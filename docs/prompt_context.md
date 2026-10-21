# Ramala: konteks untuk prompt per fitur

Tempel isi file ini di awal prompt fitur. Cukup lampirkan bagian yang relevan, tidak perlu kirim `template.dart` utuh.

## A. Proyek

- **Ramala**: aplikasi pasar prediksi (gaya Kalshi/Polymarket), Android, Flutter + Dart, tugas akhir kuliah Pemrograman Aplikasi Mobile.
- Semua layanan **gratis** (Supabase free, Cloudinary, Gemini Flash, CoinGecko, ExchangeRate-API, OpenStreetMap). Tanpa Firebase.
- Koin dan transaksi **dummy**. Harga pakai **LMSR**, logika transaksi di Postgres RPC.
- State: `flutter_riverpod` **tanpa codegen** (tanpa freezed/build_runner). Routing: `go_router`.
- Struktur **feature-first**: `lib/features/<fitur>/{data,domain,presentation}`, `lib/core/*`, `lib/shell/`.
- Package terpasang: flutter_riverpod, go_router, supabase_flutter, flutter_secure_storage, local_auth, sqflite, path, dio, image_picker, flutter_image_compress, cached_network_image, crypto, fl_chart, sensors_plus, flutter_local_notifications, workmanager, geolocator, flutter_map, latlong2, intl, timezone, permission_handler, google_fonts.
- Kunci API lewat `--dart-define-from-file=env.json` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, nanti Gemini dan Cloudinary).

## B. Aturan kode (wajib)

1. Seluruh UI pakai `import 'package:ramala/template.dart';`. Jangan hardcode warna, ukuran, atau font.
2. Setiap halaman dibungkus `AppScaffold`. Tiap daftar punya state loading (`AppSkeleton`), kosong (`EmptyState`), dan gagal (`ErrorState` + retry).
3. Semua input dibatasi: validator dari `core/validators`, `maxLength`, `inputFormatters`, lalu dirapikan (trim, buang karakter kontrol). Validasi client tidak menggantikan constraint server.
4. Pencarian: debounce (`AppSearchBar`), panjang maksimal 60, escape `%` dan `_` untuk `ilike`.
5. Client **tidak boleh** mengubah saldo, posisi, market, atau role langsung. Semua lewat RPC.
6. Error RPC dipetakan ke pesan Indonesia di `core/errors`. Tidak boleh menampilkan pesan mentah dari server.
7. Pemanggilan API eksternal lewat `dio` dengan rate limiter di client dan cache sqflite (TTL).
8. Komentar singkat untuk logika non-trivial. Kode ringkas, tanpa fitur di luar permintaan.

## C. Template UI (`lib/template.dart`)

**Token**

- `AppColors`: `bg surface card border primary onPrimary accent arcane yes no text textDim textMuted`, `glow([color])`
- `AppText`: `display title heading body bodyDim label caption number numberSm`
- `AppSpace`: `xs4 sm8 md12 lg16 xl24 xxl32`. `AppRadius`: `sm8 md12 lg16 xl24 pill`. `AppMotion`: `fast normal curve`
- `Fmt.coin(num)`, `Fmt.pct(double 0..1)`. `Gap(h)` = jarak vertikal. `AppTheme.dark` = satu-satunya tema.

**Aturan warna**: `primary` (oranye) = aksi dan merek. `accent` (amber) = koin dan sorotan. `arcane` (ungu) = info. `yes`/`no` (hijau/merah) hanya untuk arah, hasil, dan PnL. Satu `AppButton` primary per layar. Penekanan pakai `AppCard(glow: true)`, maksimal satu per layar.

**Halaman dan navigasi**

- `AppScaffold({title, actions, children | body, onRefresh, bottomNav, fab})`: `children` = daftar scroll berpadding, `body` = konten bebas.
- `AppBottomNav({items: List<AppNavItem(icon, label, [activeIcon])>, current, onTap})`
- `AppLogo({size, showName})`

**Input**

- `AppButton({label, onPressed, variant: primary|secondary|ghost|danger, icon, loading, expanded})`. `onPressed: null` = disabled.
- `AppTextField({label, controller, hint, icon, validator, password, keyboardType, maxLength, maxLines, formatters, onChanged, action, enabled})`
- `AppSearchBar({onSearch(String), hint})`: debounce 400 ms
- `AppFilterChip({label, selected, onTap})`
- `AppSegmented<T>({options: List<AppSegmentOption(value, label, {color})>, value, onChanged})`: pilihan YES/NO, Beli/Jual
- `AppAmountStepper({value, onChanged, min, max, step, label})`: nilai double
- `AppInput.decoration(...)`: dekorasi untuk field kustom

**Tampilan data**

- `AppCard({child, onTap, glow, padding, borderColor})`
- `MarketCard({title, category, priceYes, volume, status, footer, imageUrl, onTap})`
- `ProbabilityBar({yes})`, `PriceChart({data: List<double> 0..1, height})`
- `StatTile({label, value: String, icon, delta})`, `CoinText(num)`, `AppBadge(text, {color})`
- `AppAvatar({name, url, radius})`, `SectionHeader(title, {action, onAction})`
- `AppListTile({icon, title, subtitle, onTap, danger})`: taruh di dalam `AppCard(padding: EdgeInsets.zero)` dengan `Divider()` antar item
- `MarketStatus.from(status, closeAt)` menghasilkan `open|closed|resolved|cancelled`, punya `.label` dan `.color`

**Umpan balik**

- `AppLoading()`, `AppSkeleton({width, height, radius})`, `EmptyState({title, message, icon, actionLabel, onAction})`, `ErrorState({message, onRetry})`
- `AppToast.show(context, msg, {type: success|error|info})`
- `await AppConfirmDialog.show(context, {title, message, confirmLabel, danger})` mengembalikan `bool`
- `AppBottomSheet.show<T>(context, {title, child})`

## D. Backend (Supabase)

**Tabel** (client hanya `select`, kecuali yang disebut)

- `profiles(id, username, display_name, avatar_url, role user|admin, created_at)`: client boleh `update` kolom `username, display_name, avatar_url`. `avatar_url` harus berawalan `https://res.cloudinary.com/`.
- `wallets(user_id, balance)`
- `markets(id, title, description, category, image_url, latitude, longitude, close_at, status open|resolved|cancelled, outcome yes|no, b, q_yes, q_no, price_yes 0..1, volume, created_by, created_at, resolved_at)`
- `positions(user_id, market_id, side yes|no, shares, cost, realized_pnl)`
- `trades(id, user_id, market_id, side, action buy|sell|payout, shares, amount, price_yes_after, created_at)`
- `price_history(market_id, price_yes, created_at)`
- `ledger(idx, prev_hash, data, hash, created_at)`, `hash = sha256("<idx>|<prev_hash>|<data>")`, genesis `prev_hash` = 64 karakter `0`
- `notifications(id, user_id, type, title, body, data, is_read, created_at)`: client boleh `update` kolom `is_read`. Realtime aktif.
- `feedback(impression, suggestion, rating 1-5)`: client boleh `insert`
- `game_scores(game, score 0..100000)`: client boleh `insert`

**RPC** (`supabase.rpc(nama, params: {...})`)

- `trade_market(p_market uuid, p_side 'yes'|'no', p_action 'buy'|'sell', p_shares numeric 0.01..1000)` mengembalikan `{trade_id, shares, amount, price_yes, balance}`
- `admin_create_market(p_title, p_close_at, p_description, p_category, p_b, p_image_url, p_lat, p_lng)` mengembalikan uuid
- `admin_resolve_market(p_market, p_outcome 'yes'|'no')`
- `verify_ledger()` mengembalikan `idx` blok rusak, atau `null` jika valid
- `is_admin()` mengembalikan bool

**Kode error RPC** (di `PostgrestException.message`): `not_authenticated, invalid_input, invalid_shares, market_not_found, market_closed, insufficient_balance, insufficient_shares, forbidden, invalid_close_at, already_settled`.

**LMSR (untuk pratinjau di Dart, hasil resmi dari server)**

- `cost(qy, qn) = b * ln(e^(qy/b) + e^(qn/b))`, gunakan log-sum-exp stabil
- `price_yes = 1 / (1 + e^((qn - qy)/b))`
- Biaya beli = `cost(setelah) - cost(sebelum)`, dibulatkan ke atas ke 4 desimal. Hasil jual dibulatkan ke bawah.

**Cache lokal (sqflite)**: tabel `cache(key, json, updated_at)`, `chat_messages(id, role, content, created_at)`, `search_history(query, used_at)`. Format key: `markets:list`, `profile:<uid>`, `portfolio:<uid>`, `notif:<uid>`, `rates:fiat`, `rates:crypto`. Cache dikosongkan saat logout.

## E. Cara menulis prompt fitur

```
[tempel bagian A + B]
[tempel bagian C yang relevan + bagian D yang relevan]
Tugas: <fitur>. Buat file: <daftar path>. Batasan: <validasi / perilaku khusus>.
Keluaran: hanya kode file yang diminta, tanpa penjelasan panjang.
```
