-- User baru mulai dari 0 koin (trigger handle_new_user memakai default kolom ini)
alter table public.wallets alter column balance set default 0;
-- Opsional, user lama yang sudah terlanjur 1000:
-- update public.wallets set balance = 0;

create table public.topup_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  amount integer not null check (amount between 1 and 1000000),
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now(),
  resolved_at timestamptz,
  resolved_by uuid references public.profiles(id),
  check ((status = 'pending') = (resolved_at is null))
);
-- Satu user hanya boleh punya 1 permintaan pending
create unique index on public.topup_requests (user_id) where status = 'pending';
create index on public.topup_requests (user_id, created_at desc);
create index on public.topup_requests (status, created_at);

alter table public.topup_requests enable row level security;
create policy topup_read on public.topup_requests for select to authenticated
  using (user_id = auth.uid() or is_admin());
grant select on public.topup_requests to authenticated;

-- User mengajukan top up
create or replace function public.request_topup(p_amount integer)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  if p_amount is null or p_amount < 1 or p_amount > 1000000 then raise exception 'invalid_amount'; end if;
  begin
    insert into topup_requests(user_id, amount) values (auth.uid(), p_amount) returning id into v_id;
  exception when unique_violation then
    raise exception 'pending_exists';
  end;
  return v_id;
end $$;

-- Admin menyetujui
create or replace function public.admin_approve_topup(p_id uuid)
returns void language plpgsql security definer set search_path = public, extensions as $$
declare r topup_requests%rowtype;
begin
  if not is_admin() then raise exception 'forbidden'; end if;
  select * into r from topup_requests where id = p_id for update;
  if r.id is null then raise exception 'request_not_found'; end if;
  if r.status <> 'pending' then raise exception 'already_settled'; end if;

  update topup_requests set status = 'approved', resolved_at = now(), resolved_by = auth.uid() where id = p_id;
  update wallets set balance = balance + r.amount, updated_at = now() where user_id = r.user_id;
  perform ledger_append(concat_ws('|', 'topup', r.id, r.user_id, r.amount));
  insert into notifications(user_id, type, title, body)
    values (r.user_id, 'topup', 'Top up disetujui', r.amount || ' koin telah ditambahkan ke saldomu.');
end $$;

-- Admin menolak
create or replace function public.admin_reject_topup(p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare r topup_requests%rowtype;
begin
  if not is_admin() then raise exception 'forbidden'; end if;
  select * into r from topup_requests where id = p_id for update;
  if r.id is null then raise exception 'request_not_found'; end if;
  if r.status <> 'pending' then raise exception 'already_settled'; end if;

  update topup_requests set status = 'rejected', resolved_at = now(), resolved_by = auth.uid() where id = p_id;
  insert into notifications(user_id, type, title, body)
    values (r.user_id, 'topup', 'Top up ditolak', 'Permintaan top up ' || r.amount || ' koin ditolak admin.');
end $$;

grant execute on function public.request_topup(integer) to authenticated;
grant execute on function public.admin_approve_topup(uuid) to authenticated;
grant execute on function public.admin_reject_topup(uuid) to authenticated;