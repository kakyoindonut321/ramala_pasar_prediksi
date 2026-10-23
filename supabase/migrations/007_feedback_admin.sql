-- Kolom pendukung (aman jika sudah ada)
alter table public.feedback add column if not exists id uuid default gen_random_uuid();
alter table public.feedback add column if not exists created_at timestamptz not null default now();
alter table public.feedback add column if not exists is_hidden boolean not null default false;
create unique index if not exists feedback_id_key on public.feedback(id);

-- Hanya admin yang boleh membaca daftar feedback
create policy feedback_admin_select on public.feedback
  for select to authenticated using (public.is_admin());

-- Sembunyikan / tampilkan kembali (cek role di server)
create or replace function public.admin_set_feedback_hidden(p_id uuid, p_hidden boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'forbidden'; end if;
  update public.feedback set is_hidden = p_hidden where id = p_id;
end $$;

revoke all on function public.admin_set_feedback_hidden(uuid, boolean) from public;
grant execute on function public.admin_set_feedback_hidden(uuid, boolean) to authenticated;