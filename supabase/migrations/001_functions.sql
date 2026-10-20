-- 002_functions.sql : LMSR, ledger (blockchain), RPC trading & admin

-- ========== HELPER ==========
create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from profiles where id = auth.uid() and role = 'admin')
$$;

-- LMSR: C(q) = b * ln(e^(qy/b) + e^(qn/b)), versi stabil (log-sum-exp)
create or replace function public.lmsr_cost(qy double precision, qn double precision, b double precision)
returns double precision language sql immutable as $$
  select greatest(qy, qn) + b * ln(exp((qy - greatest(qy, qn)) / b) + exp((qn - greatest(qy, qn)) / b))
$$;

-- Harga YES = probabilitas
create or replace function public.lmsr_price(qy double precision, qn double precision, b double precision)
returns double precision language sql immutable as $$
  select 1 / (1 + exp((qn - qy) / b))
$$;

-- ========== LEDGER ==========
create or replace function public.ledger_append(p_data text)
returns void language plpgsql security definer set search_path = public, extensions as $$
declare v_idx bigint; v_prev text;
begin
  perform pg_advisory_xact_lock(7001);
  select idx, hash into v_idx, v_prev from ledger order by idx desc limit 1;
  v_idx := coalesce(v_idx, 0) + 1;
  v_prev := coalesce(v_prev, repeat('0', 64));
  insert into ledger(idx, prev_hash, data, hash)
  values (v_idx, v_prev, p_data,
          encode(extensions.digest(v_idx || '|' || v_prev || '|' || p_data, 'sha256'), 'hex'));
end $$;

-- Mengembalikan idx blok pertama yang rusak, atau null jika chain valid
create or replace function public.verify_ledger()
returns bigint language plpgsql stable set search_path = public, extensions as $$
declare r record; v_prev text := repeat('0', 64);
begin
  for r in select * from ledger order by idx loop
    if r.prev_hash <> v_prev
       or r.hash <> encode(extensions.digest(r.idx || '|' || r.prev_hash || '|' || r.data, 'sha256'), 'hex') then
      return r.idx;
    end if;
    v_prev := r.hash;
  end loop;
  return null;
end $$;

-- ========== TRADE (beli/jual share) ==========
create or replace function public.trade_market(p_market uuid, p_side text, p_action text, p_shares numeric)
returns jsonb language plpgsql security definer set search_path = public, extensions as $$
declare
  uid uuid := auth.uid();
  m markets%rowtype;
  v_bal numeric; v_sh numeric; v_cost numeric;
  qy double precision; qn double precision; c0 double precision;
  amt numeric; v_part numeric; v_price numeric; v_shares numeric;
  tid uuid := gen_random_uuid();
begin
  if uid is null then raise exception 'not_authenticated'; end if;
  if coalesce(p_side, '') not in ('yes','no') or coalesce(p_action, '') not in ('buy','sell') then
    raise exception 'invalid_input';
  end if;
  if p_shares is null or p_shares < 0.01 or p_shares > 1000 then raise exception 'invalid_shares'; end if;
  v_shares := round(p_shares, 2);

  select * into m from markets where id = p_market for update;
  if m.id is null then raise exception 'market_not_found'; end if;
  if m.status <> 'open' or m.close_at <= now() then raise exception 'market_closed'; end if;

  select balance into v_bal from wallets where user_id = uid for update;
  select shares, cost into v_sh, v_cost from positions
    where user_id = uid and market_id = p_market and side = p_side for update;
  v_sh := coalesce(v_sh, 0); v_cost := coalesce(v_cost, 0);

  qy := m.q_yes; qn := m.q_no;
  c0 := lmsr_cost(qy, qn, m.b);

  if p_action = 'buy' then
    if p_side = 'yes' then qy := qy + v_shares; else qn := qn + v_shares; end if;
    amt := ceil((lmsr_cost(qy, qn, m.b) - c0)::numeric * 10000) / 10000;   -- pembulatan ke atas
    if coalesce(v_bal, 0) < amt then raise exception 'insufficient_balance'; end if;
    update wallets set balance = balance - amt, updated_at = now() where user_id = uid;
    insert into positions(user_id, market_id, side, shares, cost)
    values (uid, p_market, p_side, v_shares, amt)
    on conflict (user_id, market_id, side) do update
      set shares = positions.shares + excluded.shares,
          cost = positions.cost + excluded.cost,
          updated_at = now();
  else
    if v_sh < v_shares then raise exception 'insufficient_shares'; end if;
    if p_side = 'yes' then qy := qy - v_shares; else qn := qn - v_shares; end if;
    amt := floor((c0 - lmsr_cost(qy, qn, m.b))::numeric * 10000) / 10000;  -- pembulatan ke bawah
    v_part := round(v_cost * v_shares / v_sh, 4);
    update wallets set balance = balance + amt, updated_at = now() where user_id = uid;
    update positions
      set shares = shares - v_shares, cost = cost - v_part,
          realized_pnl = realized_pnl + amt - v_part, updated_at = now()
      where user_id = uid and market_id = p_market and side = p_side;
  end if;

  v_price := round(lmsr_price(qy, qn, m.b)::numeric, 6);
  update markets set q_yes = qy, q_no = qn, price_yes = v_price, volume = volume + amt where id = p_market;
  insert into trades(id, user_id, market_id, side, action, shares, amount, price_yes_after)
    values (tid, uid, p_market, p_side, p_action, v_shares, amt, v_price);
  insert into price_history(market_id, price_yes) values (p_market, v_price);
  perform ledger_append(concat_ws('|', 'trade', tid, uid, p_market, p_side, p_action, v_shares, amt));

  return jsonb_build_object(
    'trade_id', tid, 'shares', v_shares, 'amount', amt, 'price_yes', v_price,
    'balance', (select balance from wallets where user_id = uid));
end $$;

-- ========== ADMIN ==========
create or replace function public.admin_create_market(
  p_title text, p_close_at timestamptz,
  p_description text default null, p_category text default 'general',
  p_b double precision default 100, p_image_url text default null,
  p_lat double precision default null, p_lng double precision default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  if not is_admin() then raise exception 'forbidden'; end if;
  if p_close_at is null or p_close_at <= now() then raise exception 'invalid_close_at'; end if;
  insert into markets(title, description, category, close_at, b, image_url, latitude, longitude, created_by)
  values (trim(p_title), nullif(trim(p_description), ''), lower(trim(coalesce(p_category, 'general'))),
          p_close_at, coalesce(p_b, 100), p_image_url, p_lat, p_lng, auth.uid())
  returning id into v_id;
  insert into price_history(market_id, price_yes) values (v_id, 0.5);
  return v_id;
end $$;

create or replace function public.admin_resolve_market(p_market uuid, p_outcome text)
returns void language plpgsql security definer set search_path = public, extensions as $$
declare
  m markets%rowtype; r record; v_pay numeric; tid uuid;
  v_final numeric := case when p_outcome = 'yes' then 1 else 0 end;
begin
  if not is_admin() then raise exception 'forbidden'; end if;
  if coalesce(p_outcome, '') not in ('yes','no') then raise exception 'invalid_input'; end if;
  select * into m from markets where id = p_market for update;
  if m.id is null then raise exception 'market_not_found'; end if;
  if m.status <> 'open' then raise exception 'already_settled'; end if;

  update markets set status = 'resolved', outcome = p_outcome, resolved_at = now(), price_yes = v_final
    where id = p_market;
  insert into price_history(market_id, price_yes) values (p_market, v_final);

  for r in select * from positions where market_id = p_market and shares > 0 for update loop
    v_pay := case when r.side = p_outcome then r.shares else 0 end;   -- 1 koin per share pemenang
    update wallets set balance = balance + v_pay, updated_at = now() where user_id = r.user_id;
    update positions set realized_pnl = realized_pnl + v_pay - r.cost, shares = 0, cost = 0, updated_at = now()
      where user_id = r.user_id and market_id = r.market_id and side = r.side;
    tid := gen_random_uuid();
    insert into trades(id, user_id, market_id, side, action, shares, amount, price_yes_after)
      values (tid, r.user_id, p_market, r.side, 'payout', r.shares, v_pay, v_final);
    perform ledger_append(concat_ws('|', 'payout', tid, r.user_id, p_market, r.side, r.shares, v_pay));
    insert into notifications(user_id, type, title, body, data)
      values (r.user_id, 'market_resolved', 'Market selesai',
              left(m.title, 120) || ' -> ' || upper(p_outcome) ||
              case when v_pay > 0 then '. Kamu menang ' || v_pay || ' koin.' else '. Posisimu kalah.' end,
              jsonb_build_object('market_id', p_market));
  end loop;
end $$;

-- ========== GRANT RPC (fungsi internal TIDAK di-grant) ==========
grant execute on function public.is_admin() to authenticated;
grant execute on function public.verify_ledger() to authenticated;
grant execute on function public.trade_market(uuid, text, text, numeric) to authenticated;
grant execute on function public.admin_create_market(text, timestamptz, text, text, double precision, text, double precision, double precision) to authenticated;
grant execute on function public.admin_resolve_market(uuid, text) to authenticated;

-- ========== JADIKAN AKUNMU ADMIN (jalankan manual setelah register) ==========
-- update public.profiles set role = 'admin' where username = 'usernamemu';