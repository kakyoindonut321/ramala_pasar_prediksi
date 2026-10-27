-- Sinyal view per user (client tidak boleh akses langsung, hanya lewat RPC)
create table if not exists public.market_views (
  user_id uuid not null references auth.users(id) on delete cascade,
  market_id uuid not null references public.markets(id) on delete cascade,
  view_count int not null default 1,
  last_viewed_at timestamptz not null default now(),
  primary key (user_id, market_id)
);
alter table public.market_views enable row level security;
revoke all on public.market_views from anon, authenticated;

create or replace function public.log_market_view(p_market uuid)
returns void language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid();
begin
  if uid is null then raise exception 'not_authenticated'; end if;
  if not exists (select 1 from markets where id = p_market) then raise exception 'market_not_found'; end if;
  insert into market_views(user_id, market_id) values (uid, p_market)
  on conflict (user_id, market_id) do update
    set view_count = least(market_views.view_count + 1, 20),  -- batas anti-spam
        last_viewed_at = now();
end $$;

-- Skor kategori = 3 x jumlah trade (bukan payout) + jumlah view.
-- Urutan: skor kategori, lalu trending (volume, terbaru), sama seperti sort trending.
create or replace function public.markets_for_you(
  p_done boolean default false, p_text text default '', p_limit int default 30)
returns setof markets language sql stable security definer set search_path = public as $$
  with sig as (
    select m.category, 3.0 * count(*) as s
      from trades t join markets m on m.id = t.market_id
     where t.user_id = auth.uid() and t.action <> 'payout' group by m.category
    union all
    select m.category, sum(v.view_count)::numeric
      from market_views v join markets m on m.id = v.market_id
     where v.user_id = auth.uid() group by m.category
  ), score as (select category, sum(s) as s from sig group by category)
  select m.* from markets m left join score sc on sc.category = m.category
   where (case when p_done then (m.status <> 'open' or m.close_at <= now())
               else (m.status = 'open' and m.close_at > now()) end)
     and (coalesce(p_text, '') = '' or m.title ilike
          '%' || replace(replace(replace(p_text, '\', '\\'), '%', '\%'), '_', '\_') || '%')
   order by coalesce(sc.s, 0) desc, m.volume desc, m.created_at desc
   limit least(greatest(coalesce(p_limit, 30), 1), 200)
$$;

revoke execute on function public.log_market_view(uuid) from public, anon;
revoke execute on function public.markets_for_you(boolean, text, int) from public, anon;
grant execute on function public.log_market_view(uuid) to authenticated;
grant execute on function public.markets_for_you(boolean, text, int) to authenticated;