-- 008_onchain.sql : pencatatan resolusi market ke smart contract

alter table public.markets
  add column if not exists resolve_hash text,
  add column if not exists chain_tx text,
  add column if not exists chain_status text
    check (chain_status in ('pending','confirmed','failed')),
  add column if not exists chain_at timestamptz;

-- Sama seperti versi lama, ditambah: blok ledger 'resolve' dan penyimpanan hash-nya
create or replace function public.admin_resolve_market(p_market uuid, p_outcome text)
returns void language plpgsql security definer set search_path = public, extensions as $$
declare
  m markets%rowtype; r record; v_pay numeric; tid uuid; v_hash text;
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

  -- Blok ledger khusus resolusi; hash-nya yang dikirim ke smart contract
  perform ledger_append(concat_ws('|', 'resolve', p_market, p_outcome));
  select hash into v_hash from ledger order by idx desc limit 1;
  update markets set resolve_hash = v_hash, chain_status = 'pending' where id = p_market;

  for r in select * from positions where market_id = p_market and shares > 0 for update loop
    v_pay := case when r.side = p_outcome then r.shares else 0 end;
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