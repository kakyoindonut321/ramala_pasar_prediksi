-- Menandai market tercatat on-chain + blok ledger, dalam satu transaksi.
-- Hanya bisa dipanggil Edge Function (service role), bukan client.
create or replace function public.chain_confirm(p_market uuid, p_tx text)
returns void language plpgsql security definer set search_path = public, extensions as $$
declare v_status text;
begin
  if p_tx is null or p_tx !~ '^0x[0-9a-f]{64}$' then raise exception 'invalid_input'; end if;

  select chain_status into v_status from markets where id = p_market for update;
  if not found then raise exception 'market_not_found'; end if;
  if v_status = 'confirmed' then return; end if;   -- idempoten: tidak menambah blok ganda

  update markets
    set chain_status = 'confirmed', chain_tx = p_tx, chain_at = now()
    where id = p_market;
  perform ledger_append(concat_ws('|', 'onchain', p_market, p_tx));
end $$;

revoke all on function public.chain_confirm(uuid, text) from public, anon, authenticated;
grant execute on function public.chain_confirm(uuid, text) to service_role;