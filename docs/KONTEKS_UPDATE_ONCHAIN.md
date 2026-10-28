# KONTEKS_UPDATE_ONCHAIN.md — Ramala

> Pelengkap `PROJECT_CONTEXT.md` (terakhir diperbarui 2026-10-28). Hanya memuat apa yang **ditambah atau diubah** untuk fitur blockchain on-chain. Jika bertentangan dengan PROJECT_CONTEXT, dokumen ini yang berlaku.
> **Status**: selesai dan teruji. Dikerjakan di branch git terpisah (`fitur-onchain`).

---

## 1. Ringkasan

Resolusi market sekarang **dicatat di smart contract Ethereum testnet (Sepolia)** sebagai bukti permanen. Ledger SHA-256 lama tetap ada dan kini saling terikat dengan chain.

**Prinsip desain (jangan diubah):**
- Postgres tetap sumber kebenaran untuk saldo, payout, dan LMSR. Chain **hanya mencatat hasil resolusi**.
- Resolusi dan payout **tidak bergantung pada chain**. Jika chain gagal, market tetap selesai dan payout tetap jalan.
- HP **tidak memegang kunci apa pun**. Penandatanganan transaksi hanya di server (Edge Function). Tidak ada MetaMask/WalletConnect di app.
- Batas klaim (jujur untuk laporan): **admin tetap yang menentukan hasil**. Yang dijamin chain: hasil tidak bisa diubah setelah dicatat (write-once) dan waktunya terbukti.

---

## 2. Alur

1. Admin menyelesaikan market → RPC `admin_resolve_market` (payout, notifikasi, ledger) dan menambah blok ledger `resolve`, menyimpan hash-nya ke `markets.resolve_hash`, `chain_status = 'pending'`.
2. App memanggil Edge Function `record-onchain` (fire-and-forget, tidak ditunggu).
3. Function memverifikasi pemanggil, menandatangani `record(...)` dengan private key server, mengirim ke Sepolia, menunggu 1 konfirmasi (maks 90 detik).
4. Sukses → RPC `chain_confirm` (status `confirmed`, simpan `chain_tx`, tambah blok ledger `onchain`). Gagal → `chain_status = 'failed'`.
5. Detail market menampilkan badge, tautan Etherscan, tombol **Coba lagi** (admin) dan **Cek on-chain** (semua user).

---

## 3. Komponen di luar Flutter

| Komponen | Detail |
|---|---|
| Jaringan | **Ethereum Sepolia** (chain id 11155111), gratis. Dukungan Sepolia diperpanjang sampai 2027 menurut satu sumber (Okt 2026); cek ulang sebelum presentasi |
| Smart contract | `RamalaResolusi`, ditulis dan di-deploy lewat **Remix** |
| **Alamat kontrak resmi** | `0x127B77f2b1056475d18cd77beFCba625f76aA12C` |
| Kontrak lama (diabaikan) | `0x145b1a675044774ba0ec933ebabd23be3f1bb65d` (deploy ganda tidak sengaja, jangan dipakai) |
| Wallet dev | MetaMask khusus dev, address `0xf1DC4fd5D01A5c873ebEB146E23E935882Ecae14` (owner kontrak), saldo dari faucet. **Private key hanya ada di Supabase secrets** |
| RPC provider | Alchemy (app dengan Node API, jaringan Sepolia). URL ada di Supabase secrets |
| Edge Function | `record-onchain`, dibuat lewat **editor dashboard Supabase** (tanpa Supabase CLI) |
| Secrets Edge Function | `CHAIN_RPC_URL`, `CHAIN_CONTRACT`, `CHAIN_PRIVATE_KEY` |
| Explorer | `https://sepolia.etherscan.io/tx/<hash>` |

### Kontrak (`RamalaResolusi`)
- `owner` immutable (deployer). `record(bytes32 marketId, bool outcomeYes, bytes32 ledgerHash)` hanya untuk owner dan **write-once** (revert `"sudah tercatat"`).
- `hasil(bytes32)` mengembalikan `(bool outcomeYes, bytes32 ledgerHash, uint64 waktu, bool ada)`. Selector `0x68dc05e9`.
- Event `Tercatat(marketId, outcomeYes, ledgerHash, waktu)`.
- **Konversi `marketId`**: UUID tanpa `-` (32 hex) + 32 nol di belakang = `bytes32`.

### Edge Function `record-onchain`
- `POST {"market_id": "<uuid>"}`. Stack: Deno, `npm:ethers@6`, `npm:@supabase/supabase-js@2`. **Verify JWT aktif**.
- Otorisasi: pemanggil harus admin (`is_admin()` lewat token user) atau service role.
- Syarat: market `resolved` dan punya `resolve_hash`. Sudah `confirmed` → langsung kembalikan hasil.
- **Idempoten**: cek `hasil(key).ada` sebelum mengirim; tidak pernah menulis dua kali.
- Kode function hanya ada di dashboard. **Simpan salinan** di repo (mis. `supabase/functions/record-onchain/index.ts`).
- Uji `curl` dengan service role dilewati; jalur yang teruji adalah panggilan dari app dengan token admin.

### Migrasi SQL (jalankan lewat SQL Editor, simpan di `supabase/migrations/`)
- **`008_onchain.sql`**: kolom baru di `markets`: `resolve_hash text`, `chain_tx text`, `chain_status text` (`pending|confirmed|failed`), `chain_at timestamptz`. `admin_resolve_market` diganti: ditambah `ledger_append('resolve|<market>|<outcome>')`, hash blok itu disimpan ke `resolve_hash`, `chain_status = 'pending'`.
- **`009_chain_confirm.sql`**: RPC `chain_confirm(p_market uuid, p_tx text)`. Validasi `tx` `^0x[0-9a-f]{64}$`, idempoten, memperbarui `markets` dan menambah blok `onchain`. **`execute` hanya untuk `service_role`** (dicabut dari public/anon/authenticated).

### Format blok ledger (kolom `data`)
- `trade|<tid>|<uid>|<market>|<side>|<action>|<shares>|<amount>`
- `payout|<tid>|<uid>|<market>|<side>|<shares>|<amount>`
- **baru** `resolve|<market>|<outcome>` (hash-nya = `ledgerHash` di kontrak)
- **baru** `onchain|<market>|<tx_hash>`

---

## 4. Perubahan di Flutter

**Dependensi baru**: `url_launcher` (plugin native, perlu stop penuh + run ulang).
**Opsional di `env.json`**: `CHAIN_RPC_URL` (RPC read-only untuk verifikasi; default `https://ethereum-sepolia-rpc.publicnode.com`).

**File baru**
- `features/market/data/onchain_service.dart`: memanggil function `record-onchain`; konstanta `explorerTx`.
- `features/market/data/onchain_verifier.dart`: `eth_call` langsung ke kontrak lewat `dio`, membandingkan dengan database. Hasil `OnchainCheck(recorded, outcomeMatch, hashMatch, recordedAt)`.
- `features/market/presentation/onchain_status.dart`: kartu badge (`pending/confirmed/failed`), tautan explorer, tombol Coba lagi (hanya admin).
- `features/market/presentation/onchain_check_button.dart`: tombol **Cek on-chain** + bottom sheet hasil.

**File diubah**
- `market/domain/market.dart`: field `chainStatus`, `chainTx`.
- `market/data/market_repository.dart`: **`marketCols` ditambah `chain_status,chain_tx`**. Query memakai daftar kolom eksplisit, jadi kolom baru harus ditambahkan di sini, kalau tidak field selalu null.
- `admin/presentation/admin_resolve_page.dart`: setelah RPC resolve sukses, panggil `OnchainService().record(...)` di latar belakang dengan `catchError`; invalidasi provider lewat `ProviderScope.containerOf`.
- `market/presentation/market_detail_page.dart`: `_isAdminProvider` (memanggil `is_admin`), `OnchainStatus` dan `OnchainCheckButton` (hanya jika `resolved` dan `chain_status != null`).
- `ledger/presentation/ledger_page.dart`: blok `onchain|...` diberi badge "on-chain" dan bisa diketuk ke Etherscan; teks penjelasan diperbarui.

---

## 5. Konteks penting (hindari salah paham)

1. **Market lama (sebelum migrasi) sengaja tidak punya badge/tombol.** `chain_status` dan `resolve_hash` kosong. Jangan di-backfill: waktu on-chain akan menjadi waktu hari ini, menyesatkan. Jangan dihapus (merusak referensi trade/ledger). Untuk demo gunakan market baru. Market uji "ETH test" (`bf6a1256-0c9e-4e40-8d08-12aa9fd7215d`) sudah `confirmed`; blok `onchain`-nya mungkin tidak ada karena dicatat sebelum `009` dibuat.
2. **Client tidak boleh menulis kolom `chain_*` dan `resolve_hash`**, dan tidak boleh memanggil `chain_confirm`. Semua lewat Edge Function (service role).
3. **Private key jangan pernah** masuk Flutter, `env.json`, git, atau chat. Secrets chain terpisah dari `env.json`.
4. **Kegagalan chain tidak membatalkan resolusi.** Status `failed`/`pending` yang tertinggal (mis. app ditutup, timeout 90 detik) dipulihkan lewat **Coba lagi**; aman diulang karena idempoten.
5. Penyebab gagal paling mungkin: saldo sETH wallet dev habis (isi ulang dari faucet), secrets salah, RPC bermasalah.
6. `verify_ledger()` tetap mengembalikan `null` jika rantai utuh; blok baru (`resolve`, `onchain`) ikut terverifikasi.
7. Sepolia adalah **testnet**: bukan produksi, ETH tidak bernilai. Faucet berubah-ubah; ambil ETH cukup di awal.
8. Pembaruan `env.json`, plugin native, atau manifest memerlukan **stop penuh + restart**, bukan hot reload.
9. Aturan lama tetap berlaku: UI lewat `template.dart`, satu `AppButton` primary per layar (tombol on-chain bervariasi secondary/ghost), error lewat `AppError.message`, teks Indonesia, tanpa codegen.

---

## 6. Bagian PROJECT_CONTEXT yang kini usang

- **§2 / §7.11 (blockchain)**: bukan lagi sekadar ledger lokal; kini ada pencatatan on-chain dan blok `resolve`/`onchain`.
- **§3 (dependensi)**: tambah `url_launcher`.
- **§4 (struktur)**: tambah migrasi `008`, `009` dan (disarankan) `supabase/functions/record-onchain/`.
- **§7.12 (admin resolve)**: kini memicu pencatatan on-chain.
- **§9 (tabel & RPC)**: kolom baru `markets`; RPC baru `chain_confirm` (service role saja); `admin_resolve_market` berubah.
- **§13 (utang teknis)**: tambah — kode Edge Function belum ada di repo; ketergantungan pada saldo faucet dan RPC publik.

---

## 7. Bahan laporan (blockchain)

**Teori**: blockchain publik, testnet, faucet, wallet/private key, gas, smart contract, deploy, RPC provider, block explorer, hash SHA-256, write-once.

**Screenshot yang sebaiknya diambil**
- Remix: kode kontrak, deploy sukses.
- Etherscan: halaman kontrak (label *Contract*), tab Events, transaksi `record`.
- Uji write-once (percobaan `record` kedua ditolak/gagal).
- App: badge "Tercatat on-chain", tombol explorer, sheet **Cek on-chain** (hijau).
- Uji manipulasi: ubah `resolve_hash` di database lalu **Cek on-chain** menjadi merah (lalu kembalikan nilainya).
- Uji kegagalan: `CHAIN_RPC_URL` dibuat salah → badge "Pencatatan gagal" → dipulihkan lewat Coba lagi.
- Halaman Ledger dengan badge on-chain; tombol Verifikasi rantai valid.

**Referensi transaksi** (bukan rahasia)
- Deploy kontrak tidak terpakai: `0x2f23a64029a42cfd2c947f9e1ab7abbaf8f261736e74d66e2f979e46bc11f85e`
- Uji `record` manual ke kontrak resmi (marketId uji `0x1111…1111`): `0x90fe6fa73a08fc8a2d01ebe599af5c3ae605fe320b2debccbc0c69ecdd5cfeef`
- Resolusi "ETH test": `0x927debad0561f1a798684d366d9a2cf6e73623a89d2675392bbdec2e6da09e86`

---

## 8. Rencana lain yang sudah disepakati

- **AI (non-LLM) — "Untuk kamu"**: ✅ **SELESAI.** Rekomendasi market content-based berdasarkan kategori yang sering di-trade dan dilihat (skor = 3 × trade + view), tampil sebagai feed "Untuk kamu" di daftar market. Detail implementasi lihat §7.2 dan §8 `PROJECT_CONTEXT.md`, serta migrasi `010_foryou.sql`.
- **Konversi**: tidak dirombak; tambah tampilan nilai fiat ("≈ Rp ...") di detail market dan trade sheet dengan memakai provider kurs yang sudah ada. *(belum dikerjakan)*
- **Sensor/game**: tidak diubah (akselerometer + giroskop di "Tebak Arah" sudah memenuhi). Opsional jaga-jaga: shake-to-refresh. *(belum dikerjakan)*
