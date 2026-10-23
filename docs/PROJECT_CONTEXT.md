# PROJECT_CONTEXT.md — Ramala

> **Tujuan**: Referensi lengkap dan terverifikasi untuk asisten AI yang bekerja pada codebase ini. Baca dokumen ini sebelum melakukan perubahan apapun pada proyek.
> **Terakhir diperbarui**: 2026-10-23
> **Cakupan**: Semua file di bawah `lib/`, `pubspec.yaml`, seluruh file `docs/`, dan migrasi `supabase/migrations/` telah diinspeksi.

---

## 1. Gambaran Umum Proyek

**Ramala** adalah aplikasi pasar prediksi Android yang terinspirasi dari Kalshi/Polymarket, dibangun dengan Flutter/Dart sebagai Tugas Akhir mata kuliah _Pemrograman Aplikasi Mobile_. Semua transaksi menggunakan **koin dummy** — tidak ada uang sungguhan. Aplikasi ditujukan untuk keperluan akademis dan seluruh teks antarmuka ditulis dalam **Bahasa Indonesia**.

- **Nama aplikasi**: Ramala
- **Package ID**: `com.example.ramala` (applicationId di `build.gradle.kts`)
- **Versi**: `1.0.0+1`
- **Platform utama**: Android (iOS tidak ditargetkan; `flutter_launcher_icons` mengatur `ios: false`)
- **Semua layanan backend menggunakan tier gratis**: Supabase, Cloudinary, Gemini Flash, Groq, CoinGecko, ExchangeRate-API, OpenStreetMap.

---

## 2. Persyaratan dan Perilaku yang Diharapkan

Sumber: `docs/ketentuan_tugas_akhir.txt`

| Persyaratan | Status (terverifikasi dari kode) |
|---|---|
| Login dengan enkripsi (tanpa Firebase) | ✅ Supabase Auth + `flutter_secure_storage` |
| Login biometrik | ✅ `local_auth` dengan fallback PIN |
| Database lokal + online | ✅ sqflite (cache offline) + Supabase (online) |
| Web service / API (LBS, game, atau multiplatform) | ✅ Supabase RPC, Cloudinary, Gemini+Groq, ExchangeRate-API, CoinGecko, OpenStreetMap |
| Menu navigasi: profil (dengan gambar), saran/kesan, logout | ✅ Semua tersedia |
| Konverter mata uang (min. 3) + konverter zona waktu (WIB, WIT, WITA, London) | ✅ 5 mata uang fiat + 3 kripto; 4 zona waktu |
| Min. 2 sensor (Akselerometer, Giroskop, dll.) | ✅ Keduanya digunakan pada fitur game |
| Fitur AI/LLM | ✅ Chatbot Gemini dengan failsafe Groq |
| Mini game | ✅ Game sensor "Tebak Arah" |
| Fasilitas pencarian dan pemilihan | ✅ Pencarian daftar market + filter kategori |
| Fitur notifikasi mobile | ✅ local notifications + Supabase Realtime + Workmanager |
| Fitur blockchain sederhana | ✅ Tabel `ledger` dengan rantai SHA-256, RPC `verify_ledger()` |

---

## 3. Stack Teknologi dan Dependensi

### Framework Utama
- **Flutter SDK**: `^3.13.5` (Dart)
- **State management**: `flutter_riverpod: ^3.4.3` — digunakan **tanpa codegen** (tidak ada `freezed`, `build_runner`, atau `riverpod_generator`)
- **Routing**: `go_router: ^18.1.0`

### Backend & Auth
- `supabase_flutter: ^2.18.3` — auth, database, realtime, panggilan RPC
- `flutter_secure_storage: ^11.2.0` — penyimpanan token sesi (Android Keystore)
- `local_auth: ^3.0.2` — biometrik (sidik jari/wajah + fallback PIN)

### Penyimpanan
- `sqflite: ^2.4.4+2` — cache SQLite lokal (3 tabel: `cache`, `chat_messages`, `search_history`)
- `path: ^1.9.1` — utilitas path file untuk sqflite

### Jaringan
- `dio: ^5.11.1` — HTTP client untuk Gemini AI, Groq, dan Cloudinary (tidak digunakan untuk Supabase)

### Media
- `image_picker: ^1.2.4` — pemilihan foto dari galeri untuk avatar dan gambar market
- `flutter_image_compress: ^2.5.1` — kompresi JPEG sebelum upload ke Cloudinary
- `cached_network_image: ^4.0.4` — caching gambar jaringan

### Grafik & Data
- `fl_chart: ^1.2.0` — widget `PriceChart` (line chart untuk riwayat harga YES)
- `crypto: ^3.0.7` — hash SHA-256 (tersedia tapi komputasi rantai dilakukan oleh Postgres `verify_ledger()`)
- `intl: ^0.20.3` — format tanggal, format angka
- `timezone: ^0.11.2` — konversi zona waktu di konverter
- `latlong2: ^0.10.1` — tipe `LatLng` untuk koordinat peta

### Lokasi & Peta
- `geolocator: ^14.1.2` — lokasi GPS
- `flutter_map: ^8.3.2` — peta tile OpenStreetMap
- `permission_handler: ^13.0.2` — manajemen izin runtime

### Notifikasi & Background
- `flutter_local_notifications: ^22.3.2` — notifikasi on-device
- `workmanager: ^0.10.10` — polling background (interval minimum 15 menit di Android)

### Sensor
- `sensors_plus: ^7.1.1` — stream akselerometer dan giroskop

### UI
- `google_fonts: ^8.2.1` — font Inter dan Cinzel

### Dev Dependencies
- `flutter_lints: ^6.0.0`
- `flutter_launcher_icons: ^0.14.4` — ikon launcher kustom dari `assets/gambar/logo_ramala_icon.png`

---

## 4. Struktur Direktori dan File Penting

```
ramala/
├── lib/
│   ├── main.dart                     # Entry point aplikasi
│   ├── app.dart                      # RamalaApp (MaterialApp.router)
│   ├── template.dart                 # SELURUH design system (1131+ baris)
│   ├── core/
│   │   ├── config/env.dart           # Konstanta String.fromEnvironment()
│   │   ├── error/app_error.dart      # Pemetaan Error → pesan Bahasa Indonesia
│   │   ├── router/app_router.dart    # Konfigurasi GoRouter + redirect auth
│   │   ├── storage/
│   │   │   ├── local_db.dart         # Helper sqflite (cache, chat, search)
│   │   │   └── secure_session.dart   # SecureLocalStorage untuk sesi Supabase
│   │   ├── validators/validators.dart # Validasi + sanitasi input
│   │   └── widgets/input_sheet.dart  # Helper bottom sheet askInput()
│   ├── shell/
│   │   ├── main_shell.dart           # StatefulNavigationShell + Realtime + bottom nav
│   │   ├── features_page.dart        # Tab "Fitur" — launcher menu untuk fitur tambahan
│   │   └── placeholder_page.dart     # Placeholder tak terpakai (dikomentari di router)
│   └── features/
│       ├── auth/{data,presentation}
│       ├── chatbot/{data,presentation}   # Gemini + Groq failsafe
│       ├── converter/{data,presentation}
│       ├── feedback/presentation
│       ├── game/presentation
│       ├── ledger/presentation
│       ├── market/{data,domain,presentation}
│       ├── nearby/presentation
│       ├── notification/{data,domain,presentation}
│       ├── portfolio/{data,presentation}
│       ├── profile/{data,presentation}
│       ├── topup/{data,presentation}     # Request top up koin user
│       ├── admin/presentation            # Panel admin (buat market, top up, selesaikan)
│       ├── contoh_struktur/              # Folder template referensi (hanya gitkeep)
│       ├── trading/                      # Kosong (hanya gitkeep) — logika trading di fitur market
│       └── wallet/                       # Kosong (hanya gitkeep)
├── docs/                             # File dokumentasi (semua dalam Bahasa Indonesia)
├── assets/gambar/                    # Aset gambar (logo_ramala.png, logo_ramala_icon.png)
├── android/
│   └── app/
│       ├── build.gradle.kts          # compileSdk=37, coreLibraryDesugaring diaktifkan
│       └── src/main/
│           ├── AndroidManifest.xml   # Izin yang dideklarasikan
│           └── kotlin/.../MainActivity.kt  # extends FlutterFragmentActivity (diperlukan untuk biometrik)
├── pubspec.yaml
├── supabase/migrations/              # File migrasi SQL Supabase CLI
│   ├── 001_schema.sql                # Tabel, constraint, trigger, RLS, grant
│   ├── 001_functions.sql             # Fungsi RPC (trade, admin, ledger, dll.)
│   ├── 003_topup.sql                 # Tabel & RPC top up koin; set balance awal = 0
│   └── 007_feedback_admin.sql        # Kolom is_hidden + RPC admin_set_feedback_hidden
└── env.json                          # ⚠️ BERISI API KEY ASLI — jangan di-commit
```

> **Catatan**: `features/trading/` dan `features/wallet/` hanya berisi file `.gitkeep`. Logika trading ada di `features/market/`.

---

## 5. Arsitektur dan Startup Aplikasi

### Urutan Startup (`lib/main.dart`)
1. `WidgetsFlutterBinding.ensureInitialized()`
2. `Supabase.initialize(url, anonKey, authOptions: FlutterAuthClientOptions(localStorage: SecureLocalStorage()))` — menyimpan sesi di Android Keystore
3. `NotificationService.init()` — mendaftarkan plugin `flutter_local_notifications`
4. `Workmanager().initialize(callbackDispatcher)` — mendaftarkan entry point isolate background
5. `tz.initializeTimeZones()` — memuat database timezone
6. `runApp(ProviderScope(child: RamalaApp()))`

### Pola Arsitektur
- **Feature-first**: `lib/features/<feature>/{data,domain,presentation}/`
- **Riverpod tanpa codegen**: `FutureProvider.autoDispose`, `FutureProvider.autoDispose.family`, `Provider` — semuanya dibuat secara manual
- Tidak menggunakan `freezed`, `json_serializable`, atau `build_runner`
- Model adalah kelas Dart biasa dengan konstruktor `factory fromMap()`
- Repository adalah kelas biasa yang diinstansiasi langsung di provider

---

## 6. Navigasi dan Inventaris Layar

### Konfigurasi Route (`lib/core/router/app_router.dart`)

**Guard auth**: `_AuthRefresh` mendengarkan `Supabase.instance.client.auth.onAuthStateChange`. Fungsi `redirect`:
- Belum login → redirect semua route ke `/login`
- Sudah login di halaman login/register → redirect ke `/pasar`

**Shell routes (5 tab — bottom nav)**:
| Tab | Route | Widget | Deskripsi |
|---|---|---|---|
| 0 | `/pasar` | `MarketListPage` | Daftar market dengan pencarian dan filter kategori termasuk "Semua" |
| 1 | `/portofolio` | `PortfolioPage` | Posisi, riwayat transaksi, saldo |
| 2 | `/fitur` | `FeaturesPage` | Menu launcher untuk fitur tambahan |
| 3 | `/saran` | `FeedbackPage` | Form saran & kesan; admin bisa lihat dan sembunyikan daftar |
| 4 | `/profil` | `ProfilePage` | Profil user, avatar, biometrik, logout, request top up koin |

**Route detail (di luar shell, layar penuh)**:
| Route | Widget | Catatan |
|---|---|---|
| `/login` | `LoginPage` | Dijaga auth |
| `/register` | `RegisterPage` | Dijaga auth |
| `/market/:id` | `MarketDetailPage` | Parameter path `id` |
| `/konverter` | `ConverterPage` | Mata uang + kripto + zona waktu; tab waktu hanya tampilkan market yang masih buka |
| `/nearby` | `NearbyPage` | Peta LBS + daftar terurut |
| `/game` | `GamePage` | Game sensor |
| `/chatbot` | `ChatPage` | Chat AI (Gemini + failsafe Groq); limit input 1000 karakter |
| `/notifikasi` | `NotificationPage` | Daftar notifikasi |
| `/ledger` | `LedgerPage` | Ledger blockchain |
| `/admin` | `AdminPage` | Khusus admin (tanpa guard client — RPC server yang mengontrol akses) |
| `/admin/market-baru` | `AdminCreateMarketPage` | Buat market baru dengan gambar, pin peta, dan waktu tutup |
| `/admin/topup` | `AdminTopupPage` | Daftar permintaan top up; terima/tolak |
| `/admin/selesaikan` | `AdminResolvePage` | Selesaikan market yang berjalan |

---

## 7. Implementasi Fitur Per-Fitur

### 7.1 Autentikasi (`features/auth/`)

**Login (`login_page.dart`)**:
- Form email/password menggunakan `Validators.email` dan cek required untuk password
- Tombol biometrik hanya ditampilkan jika `BiometricService.supported && enabled`
- Saat login biometrik: autentikasi → baca kredensial tersimpan → panggil `AuthRepository.login()`
- Jika kredensial biometrik tidak valid (password berubah), biometrik dinonaktifkan otomatis dan panduan ditampilkan
- Redirect router menangani navigasi setelah login berhasil

**Register (`register_page.dart`)**:
- Field username, email, password
- `Validators.username` (3–20 karakter, huruf kecil, angka, underscore)
- `Validators.password` (8–64 karakter, harus mengandung huruf DAN angka)
- Setelah berhasil, router redirect otomatis; tidak ada navigasi manual

**AuthRepository (`auth/data/auth_repository.dart`)**:
- `login()` → `_auth.signInWithPassword()`
- `register()` → `_auth.signUp()` dengan `data: {'username': username}` sebagai metadata user
- `logout()`: **urutan kritis** — `signOut(scope: SignOutScope.local)` dulu (tanpa jaringan), lalu `NotificationService.stopBackground()` dan `LocalDb.clear()` sebagai best-effort

**BiometricService (`auth/data/biometric_service.dart`)**:
- Menyimpan `bio_email` dan `bio_pass` di `FlutterSecureStorage` (terpisah dari token sesi)
- `authenticate()` menggunakan `biometricOnly: false` → memperbolehkan fallback PIN/pola
- `enabledFor(email)` memverifikasi bahwa email tersimpan cocok dengan user saat ini
- Mengaktifkan: membutuhkan `authenticate()` yang berhasil + konfirmasi password eksplisit via `AuthRepository.login()`

### 7.2 Market (`features/market/`)

**Model Market (`domain/market.dart`)**:
```dart
class Market {
  final String id, title, category, status;
  final String? description, imageUrl, outcome;
  final DateTime closeAt;
  final double b, qYes, qNo, priceYes, volume;
  bool get isOpen => status == 'open' && closeAt.isAfter(DateTime.now());
}
```
- `isOpen` dihitung sisi client menggunakan `closeAt` vs waktu sekarang
- `MarketStatus.from(status, closeAt)` di `template.dart` menambahkan state `closed` yang dihitung

**Daftar market (`market_list_page.dart`)**:
- Market aktif diurutkan berdasarkan `closeAt` naik (yang segera tutup tampil pertama)
- Market diselesaikan/dibatalkan dalam seksi yang bisa dilipat, diurutkan `closeAt` turun
- Filter kategori termasuk opsi **"Semua"** di posisi pertama untuk menampilkan semua market
- Chip filter kategori dibangkitkan secara dinamis dari kategori yang tersedia
- Jika market memiliki `imageUrl`, gambar ditampilkan sebagai icon mirip Polymarket (persegi, opsional)
- `AppSearchBar` dengan debounce 400ms → memperbarui state `_q` → memantau ulang `marketListProvider(_q)`
- Cache offline: hanya ketika `query.isEmpty` (via `LocalDb.cachedList`)

**MarketRepository (`market/data/market_repository.dart`)**:
- `list(query)`: menggunakan `ilike` dengan `Validators.likeEscape()` untuk keamanan wildcard, limit 100
- `get(id)`: market tunggal berdasarkan UUID
- `history(id)`: 100 snapshot harga terakhir dari `price_history` (dibalik ke urutan kronologis)
- `trade()`: memanggil RPC `trade_market`, mengembalikan `amount` dari respons

**Penetapan harga LMSR (`domain/lmsr.dart`)**:
- `cost(qy, qn, b)` menggunakan log-sum-exp yang stabil secara numerik
- `price(qy, qn, b)` = `1 / (1 + e^((qn-qy)/b))`
- `quote(...)` mengembalikan `(amount, priceYes)` — beli dibulatkan ke atas 4 desimal, jual ke bawah
- **Hanya preview sisi client.** Jumlah otoritatif berasal dari RPC server.

**Sheet trading (`market/presentation/trade_sheet.dart`)**:
- Memilih Beli/Jual dan YES/NO via `AppSegmented`
- Input jumlah share menggunakan `AppTextField` dengan angka langsung (bukan hanya tombol +/-)
- Chip cepat tersedia: 10, 50, 100, 500 share; chip "Maks" untuk mode jual
- Validasi ketat: regex `^\d{0,4}([.,]\d{0,2})?$`, min 0,01, maks 1000; pesan error inline
- Tombol submit dinonaktifkan jika saldo tidak cukup, share kurang, atau input tidak valid
- Setelah transaksi berhasil: invalidasi `marketProvider`, `priceHistoryProvider`, `marketListProvider`, `portfolioProvider`, `tradesProvider`, `balanceProvider`

### 7.3 Portofolio (`features/portfolio/`)

**Model PortfolioPosition** (didefinisikan di `portfolio_repository.dart`):
- Menyimpan referensi ke objek `Market` lengkap (di-join dalam query)
- `value` = `shares × (priceYes if side=yes, else 1-priceYes)`
- `unrealized` = `value - cost` (hanya jika shares > 0)
- Posisi dengan `shares == 0` disertakan untuk kalkulasi PnL terealisasi

**PortfolioRepository**:
- `positions()`: join tabel `markets` dengan semua kolom market
- `trades()`: 20 transaksi terakhir (limit hardcoded)

### 7.4 Profil (`features/profile/`)

**ProfileRepository**:
- Getter `_uid` melempar `AuthException('not_authenticated')` jika `currentUser == null` — mencegah crash saat race condition logout
- `update()`: update parsial, hanya mengirim field yang tidak null
- `avatarUrl` dibatasi prefix `https://res.cloudinary.com/` oleh constraint server

**Halaman profil (`profile_page.dart`)**:
- Upload avatar: `ImagePicker → CloudinaryService.uploadAvatar → ProfileRepository.update`
- Edit nama: via bottom sheet `askInput()`
- Toggle biometrik: aktifkan setelah autentikasi ulang + konfirmasi password; nonaktifkan setelah konfirmasi
- Admin melihat "Panel admin" → `/admin`
- Menu **"Request Top Up Koin"** → menampilkan form di mana user bisa input jumlah (validasi angka, max 1.000.000 koin); satu request pending per user
- Logout: dialog konfirmasi → `AuthRepository.logout()` → `GoRouter.go('/login')`

**CloudinaryService**:
- Kompresi ke JPEG 512×512 min, kualitas 80%
- Tolak jika ukuran terkompresi > 3MB (`FormatException('image')`)

### 7.5 Top Up Koin (`features/topup/`)

**Alur top up**:
1. User mengajukan permintaan melalui menu di halaman profil → RPC `request_topup(p_amount)`
2. Satu user hanya boleh punya **satu permintaan pending** (unique index di database)
3. Admin melihat daftar permintaan di `/admin/topup` → terima atau tolak
4. Saat **disetujui**: balance user bertambah, entri ledger dibuat, notifikasi dikirim ke user
5. Saat **ditolak**: notifikasi dikirim ke user; saldo tidak berubah
6. Request yang sudah selesai (approved/rejected) **tidak lagi tampil** di daftar admin

**Validasi**:
- Jumlah minimum: 1 koin
- Jumlah maksimum: 1.000.000 koin (dijaga di client DAN di RPC server)
- Harus angka positif (validasi di Flutter + constraint `check` di database)

**Catatan database**: Migrasi `003_topup.sql` mengubah `default balance = 0` pada tabel `wallets` — **user baru tidak lagi otomatis mendapat 1000 koin**.

### 7.6 Notifikasi (`features/notification/`)

**Sistem notifikasi tiga lapis**:
1. **Realtime (foreground)**: `MainShell._start()` berlangganan ke channel Supabase Realtime `notif_<uid>`. Saat INSERT di tabel `notifications` → `NotificationService.show()` + invalidasi `notificationsProvider`.
2. **Polling background**: Task periodik Workmanager (min 15 menit), reinisialisasi Supabase di isolate, memanggil `NotificationService.pollBackground()`.
3. **Deduplikasi**: `notif_last` di `FlutterSecureStorage` — hanya notifikasi yang lebih baru yang ditampilkan.

**Model AppNotification** berisi `marketId` dari `data->>'market_id'` JSONB — digunakan untuk navigasi saat notifikasi diketuk.

### 7.7 Chatbot (`features/chatbot/`)

**Arsitektur dual AI dengan failsafe**:
- `AiChatService` (`chatbot/data/ai_chat_service.dart`) adalah fasad tunggal yang dipanggil `ChatPage`
- **Urutan**: Coba Gemini terlebih dahulu → jika gagal (error apapun), fallback ke Groq
- Jika Gemini error/sibuk, UI tetap loading sementara request dipindahkan ke Groq
- Jika hanya Groq yang tersedia (Gemini key kosong), Groq digunakan langsung

**GeminiService (`chatbot/data/gemini_service.dart`)**:
- Model: `gemini-2.0-flash` (verifikasi nama model sebelum digunakan)
- System prompt: Bahasa Indonesia, maks 120 kata, tanpa nasihat investasi nyata, menjelaskan LMSR
- Menyuntikkan hingga 10 market aktif dengan harga YES sebagai konteks
- `maxOutputTokens: 600`, `temperature: 0.7`, `thinkingBudget: 0`

**GroqService (`chatbot/data/groq_service.dart`)**:
- Model: `openai/gpt-oss-20b`
- Endpoint: `https://api.groq.com/openai/v1/chat/completions`
- `max_completion_tokens: 1000`, `reasoning_effort: 'low'`, `temperature: 0.7`
- Format history: role `model` dikonversi ke `assistant` untuk API OpenAI-compatible

**ChatPage (`chatbot/presentation/chat_page.dart`)**:
- Rate limit: 15 pesan per jendela rolling 10 menit (sisi client)
- Jendela riwayat: 10 pesan terakhir dikirim ke AI
- Riwayat chat disimpan di sqflite
- **`maxLength: 1000` karakter** untuk input (batas prompt per pesan)
- Tidak ada logika retry — error ditampilkan via `AppToast`
- Kedua API key dikonfigurasi di `env.json`: `GEMINI_API_KEY` dan `GROQ_API_KEY`

### 7.8 Konverter (`features/converter/`)

**Tiga tab**: Fiat, Kripto, Waktu

- **Fiat**: `open.er-api.com`, 5 mata uang + KOIN (1 KOIN = 1 USD dummy), cache 1 jam
- **Kripto**: CoinGecko, BTC/ETH/SOL vs USD + IDR, cache 2 menit
- **Zona Waktu**: WIB, WITA, WIT, London menggunakan paket `timezone`
- Tab zona waktu bisa menggunakan `closeAt` market sebagai waktu yang dikonversi
- **Market yang sudah tutup atau selesai TIDAK ditampilkan** dalam daftar pilihan market di tab zona waktu

### 7.9 Nearby / LBS (`features/nearby/`)

- Meminta GPS via `geolocator`
- Mengambil market terbuka dengan `latitude`/`longitude` yang tidak null
- Menghitung dan mengurutkan berdasarkan jarak sisi client
- Peta: `flutter_map` dengan tile OpenStreetMap
- `userAgentPackageName: 'com.example.ramala'` harus cocok dengan `applicationId`

### 7.10 Game — "Tebak Arah" (`features/game/`)

- 10 ronde, masing-masing 3 detik
- Arah: kiri, kanan, maju, mundur, putar (5 pilihan)
- **Akselerometer**: threshold ±5 m/s² pada sumbu X/Y
- **Giroskop**: `|z| > 5` rad/s untuk rotasi
- Skor: 100 dasar + bonus kecepatan per jawaban benar
- Debounce 400ms mencegah carry-over dari gestur sebelumnya
- Skor disimpan ke tabel `game_scores`; leaderboard menampilkan top 10

### 7.11 Ledger Blockchain (`features/ledger/`)

- Membaca 50 entri terakhir dari tabel `ledger`
- `hash = SHA-256("<idx>|<prev_hash>|<data>")` dihitung di Postgres
- Tombol "Verifikasi rantai" memanggil RPC `verify_ledger()` → mengembalikan `idx` yang rusak atau null
- Blok yang rusak disorot dengan border merah (`AppCard(borderColor: AppColors.no)`)

### 7.12 Panel Admin (`features/admin/`)

**Tidak ada guard route sisi client** — keamanan ditegakkan oleh RPC Supabase.

`AdminPage` berfungsi sebagai dashboard dengan tiga menu:

**a. Buat Market (`/admin/market-baru` → `AdminCreateMarketPage`)**:
- Field: judul, deskripsi, kategori, parameter b, waktu tutup (date+time picker)
- **Upload gambar** (`image_picker` → validasi persegi toleransi 2%, min 200px → `MarketImageService.upload()` → Cloudinary → URL disimpan via RPC)
- **Drop pin lokasi**: tombol membuka `PinPickerPage` (flutter_map) untuk memilih koordinat lat/lng secara visual; tidak memerlukan dependency baru
- Memanggil RPC `admin_create_market`; invalidasi `marketListProvider` dan `categoriesProvider`

**b. Permintaan Top Up (`/admin/topup` → `AdminTopupPage`)**:
- Menampilkan daftar semua permintaan pending beserta nama user atau detail usernya
- Tombol **Terima** → memanggil RPC `admin_approve_topup(p_id)`: balance user bertambah + notifikasi dikirim
- Tombol **Tolak** → memanggil RPC `admin_reject_topup(p_id)`: notifikasi penolakan dikirim
- Request yang sudah diselesaikan (approved/rejected) **dihapus dari daftar** secara otomatis (tidak ditampilkan lagi)
- Badge jumlah pending ditampilkan di halaman admin utama

**c. Selesaikan Market (`/admin/selesaikan` → `AdminResolvePage`)**:
- Menampilkan market yang berstatus open untuk diselesaikan
- Pilihan hasil YES/NO → dialog konfirmasi → RPC `admin_resolve_market(p_market, p_outcome)`

### 7.13 Saran & Kesan (`features/feedback/`)

- Rating bintang 1–5 (wajib), field kesan + saran (min 5, maks 500 karakter)
- Insert ke tabel `feedback` langsung (tanpa layer repository)
- **Hak istimewa admin**:
  - Admin dapat melihat daftar semua saran & kesan yang dikirim pengguna (di bawah form input)
  - Admin dapat menyembunyikan/menampilkan kembali entri feedback via RPC `admin_set_feedback_hidden(p_id, p_hidden)`
  - Kebijakan RLS `feedback_admin_select` memastikan hanya admin yang bisa membaca semua feedback
  - Kolom `is_hidden` di tabel `feedback` ditambahkan via migrasi `007_feedback_admin.sql`

---

## 8. State Management dan Alur Data

### Provider Riverpod

Semua provider: `FutureProvider.autoDispose` dengan `retry: (_, __) => null` (tanpa auto-retry).

| Provider | Lokasi | Catatan |
|---|---|---|
| `routerProvider` | `core/router/app_router.dart` | Termasuk listenable auth `_AuthRefresh` |
| `marketListProvider(q)` | `market/presentation/market_providers.dart` | Family berdasarkan query pencarian |
| `marketProvider(id)` | sama | Family berdasarkan UUID market |
| `priceHistoryProvider(id)` | sama | Family berdasarkan UUID market |
| `categoriesProvider` | `market/presentation/market_providers.dart` | Daftar kategori unik + "semua" |
| `portfolioProvider` | `portfolio/presentation/portfolio_providers.dart` | |
| `tradesProvider` | sama | |
| `profileProvider` | `profile/presentation/profile_providers.dart` | |
| `balanceProvider` | sama | |
| `notificationsProvider` | `notification/presentation/notification_page.dart` | Juga diinvalidasi oleh Realtime di `MainShell` |
| `pendingTopupsProvider` | `admin/presentation/admin_topup_page.dart` | Daftar pending top up untuk admin |
| `ledgerProvider` | `ledger/presentation/ledger_page.dart` | Didefinisikan inline |
| `_boardProvider` | `game/presentation/game_page.dart` | Didefinisikan inline |
| `_fiatProvider`, `_cryptoProvider` | `converter/presentation/converter_page.dart` | Didefinisikan inline |
| `_nearbyProvider` | `nearby/presentation/nearby_page.dart` | Mengembalikan named record |

### Strategi Cache

`LocalDb.cachedList(key, fetch)` — network-first, fallback ke cache hanya untuk error jaringan. Error Supabase TIDAK di-cache — dilempar ulang. Semua cache dihapus saat logout.

Cache keys: `markets:list`, `portfolio:<uid>`, `notif:<uid>`, `rates:fiat`, `rates:crypto`

---

## 9. Model Data, Persistensi, dan Layanan Eksternal

### Tabel Database Supabase

| Tabel | Kolom Utama | Akses Client |
|---|---|---|
| `profiles` | `id, username, display_name, avatar_url, role, created_at` | SELECT semua; UPDATE `username, display_name, avatar_url` |
| `wallets` | `user_id, balance` (default **0** sejak migrasi 003) | SELECT milik sendiri |
| `markets` | `id, title, description, category, image_url, latitude, longitude, close_at, status, outcome, b, q_yes, q_no, price_yes, volume, created_by, created_at, resolved_at` | SELECT semua |
| `positions` | `user_id, market_id, side, shares, cost, realized_pnl` | SELECT milik sendiri |
| `trades` | `id, user_id, market_id, side, action, shares, amount, price_yes_after, created_at` | SELECT milik sendiri |
| `price_history` | `market_id, price_yes, created_at` | SELECT |
| `ledger` | `idx, prev_hash, data, hash, created_at` | SELECT saja |
| `notifications` | `id, user_id, type, title, body, data (JSONB), is_read, created_at` | SELECT milik sendiri; UPDATE `is_read` |
| `feedback` | `id, user_id, impression, suggestion, rating, is_hidden, created_at` | INSERT milik sendiri; SELECT semua (admin saja via RLS) |
| `game_scores` | `game, score, user_id, created_at` | INSERT; SELECT |
| `topup_requests` | `id, user_id, amount, status, created_at, resolved_at, resolved_by` | SELECT milik sendiri atau admin |

### RPC Supabase

| RPC | Parameter | Mengembalikan |
|---|---|---|
| `trade_market` | `p_market uuid, p_side, p_action, p_shares numeric 0.01–1000` | `{trade_id, shares, amount, price_yes, balance}` |
| `admin_create_market` | `p_title, p_close_at, p_description, p_category, p_b, p_image_url?, p_lat?, p_lng?` | uuid |
| `admin_resolve_market` | `p_market uuid, p_outcome 'yes'\|'no'` | void |
| `verify_ledger` | tidak ada | `int?` (idx yang rusak) atau null |
| `is_admin` | tidak ada | bool |
| `request_topup` | `p_amount integer` | uuid (ID request) |
| `admin_approve_topup` | `p_id uuid` | void |
| `admin_reject_topup` | `p_id uuid` | void |
| `admin_set_feedback_hidden` | `p_id uuid, p_hidden boolean` | void |

### Tabel sqflite (`ramala.db`)

1. `cache(key TEXT PK, json TEXT, updated_at INTEGER)`
2. `chat_messages(id INTEGER AUTOINCREMENT PK, role TEXT, content TEXT, created_at INTEGER)`
3. `search_history(query TEXT PK, used_at INTEGER)` — struktur ada, belum digunakan aktif di UI

---

## 10. Konvensi UI dan Design System

**File tunggal**: `lib/template.dart` — diimpor oleh SEMUA halaman sebagai `import 'package:ramala/template.dart'`.

**Konsep desain**: "séance / crystal ball" — ungu gelap kehitaman dengan aksen oranye-labu.

### Sistem Warna (`AppColors`)

| Nama | Hex | Penggunaan |
|---|---|---|
| `bg` | `#0B0710` | Latar halaman |
| `surface` | `#150E1C` | Input, nav bar, bottom sheet |
| `card` | `#1E1428` | Latar kartu |
| `border` | `#2E2140` | Border |
| `primary` | `#FF7A1A` | Aksi, brand (oranye) |
| `accent` | `#FFC24A` | Nilai koin, highlight (amber) |
| `arcane` | `#8B5CF6` | Info, empty state (ungu) |
| `yes` | `#7EE08A` | Arah YES, keuntungan (hijau) |
| `no` | `#F0455A` | Arah NO, kerugian, error (merah) |

### Tipografi (`AppText`)

- **Cinzel**: `display` (28px bold), `title` (20px bold) — judul halaman, logo
- **Inter**: semua gaya lainnya — `heading`, `body`, `bodyDim`, `label`, `caption`, `number`, `numberSm`
- Angka menggunakan tabular figures (`FontFeature.tabularFigures()`)

### Jarak dan Radius

- `AppSpace`: xs=4, sm=8, md=12, lg=16, xl=24, xxl=32
- `AppRadius`: sm=8, md=12, lg=16, xl=24, pill=999

### Aturan Widget Utama

1. Setiap halaman menggunakan `AppScaffold`. `children:` untuk scrollable; `body:` untuk layout kustom.
2. Loading: `AppSkeleton` untuk placeholder; `AppLoading` untuk spinner.
3. State: `EmptyState` (tidak ada data), `ErrorState` (selalu sertakan `onRetry`).
4. Feedback: `AppToast.show(context, message, type: ToastType.*)`.
5. Aksi berisiko: `AppConfirmDialog.show(context, ...)` mengembalikan `Future<bool>`.
6. Panel bawah: `AppBottomSheet.show<T>(context, title, child)` mengembalikan `Future<T?>`.
7. **Hanya satu kartu bercahaya (`AppCard(glow: true)`) per layar**.
8. **Hanya satu `AppButton` primary per layar/panel**.
9. `AppNavItem(icon, label, [activeIcon])` — **konstruktor positional**.
10. `MarketStatus.from(status, closeAt)` — selalu gunakan ini, bukan string `status` mentah.

---

## 11. Validasi dan Penanganan Error

### Validasi Sisi Client

| Validator | Aturan |
|---|---|
| `Validators.clean(s)` | Trim + hapus karakter kontrol |
| `Validators.email(v)` | Wajib, maks 100 karakter, regex format dasar |
| `Validators.password(v)` | 8–64 karakter, harus mengandung huruf DAN angka |
| `Validators.username(v)` | `^[a-z0-9_]{3,20}$` |
| `Validators.displayName(v)` | Wajib, maks 40 karakter |
| `Validators.required(v, {min, max})` | min=1 (default), max=500 (default) |
| `Validators.searchTerm(s)` | Clean + potong ke 60 karakter |
| `Validators.likeEscape(s)` | Escape `\`, `%`, `_` untuk query `ilike` |

### Pemetaan Error (`AppError.message(Object e)`)

Memetakan `SocketException`, `AuthException` (berdasarkan kode), `PostgrestException` (berdasarkan kode error RPC), `DioException` (berdasarkan status HTTP) ke pesan Bahasa Indonesia. Pesan server mentah tidak pernah ditampilkan.

---

## 12. Konfigurasi, Pengujian, dan Instruksi Build

### Menjalankan Aplikasi

```bash
flutter pub get
# Buat env.json di root proyek dengan:
# SUPABASE_URL, SUPABASE_ANON_KEY, CLOUDINARY_CLOUD_NAME, CLOUDINARY_UPLOAD_PRESET,
# GEMINI_API_KEY, GROQ_API_KEY
flutter run --dart-define-from-file=env.json
```

### env.json — Struktur Key yang Dibutuhkan

```json
{
  "SUPABASE_URL": "https://<project>.supabase.co",
  "SUPABASE_ANON_KEY": "...",
  "CLOUDINARY_CLOUD_NAME": "...",
  "CLOUDINARY_UPLOAD_PRESET": "...",
  "GEMINI_API_KEY": "...",
  "GROQ_API_KEY": "..."
}
```

> ⚠️ Jangan tambahkan trailing slash pada `SUPABASE_URL`.

### Catatan Penting

- Perubahan pada `env.json`, `AndroidManifest.xml`, atau Gradle memerlukan **stop penuh + restart**
- Sensor game dan GPS membutuhkan **perangkat fisik**
- Akses admin: di SQL Editor Supabase: `UPDATE public.profiles SET role = 'admin' WHERE username = 'nama';`

### Konfigurasi Build

- `compileSdk = 37`, `minSdk = flutter.minSdkVersion`
- `isCoreLibraryDesugaringEnabled = true` (diperlukan untuk timezone)
- Release build menggunakan debug signing key — ganti sebelum produksi
- `MainActivity.kt` extends `FlutterFragmentActivity` (diperlukan untuk `local_auth`)

---

## 13. Masalah yang Diketahui, Pekerjaan Belum Selesai, dan Hutang Teknis

1. **Nama model Gemini**: Verifikasi nama model `gemini-2.0-flash` terhadap dokumentasi API Gemini sebelum mengandalkan chatbot
2. **`env.json` berisi key asli** — risiko keamanan signifikan; jangan di-commit ke repository publik
3. **Route admin tanpa guard sisi client** — pengguna terotentikasi manapun bisa navigasi ke `/admin`; RPC server yang mengontrol akses
4. **`features/trading/` dan `features/wallet/`** — folder placeholder kosong
5. **Tabel `search_history`** — ada di sqflite tapi tidak ada UI autocomplete yang membacanya
6. **Limit `PortfolioRepository.trades()` 20** dan **`MarketRepository.list()` 100** — tidak ada paginasi
7. **Race condition logout** — bisa muncul kembali setelah hot reload; gunakan restart penuh
8. **Signing release** — menggunakan keystore debug
9. **Notifikasi background belum diuji sepenuhnya** — hanya notifikasi "setelah market diselesaikan" yang terkonfirmasi berfungsi
10. **Workmanager di HP OEM** — task background bisa tertunda jauh lebih dari 15 menit di mode hemat baterai

---

## 14. Ketidaksesuaian Dokumentasi vs Kode

| Klaim dokumentasi | Kenyataan kode |
|---|---|
| `catatan_rencana.md`: hash dihitung di client (paket `crypto`) | RPC `verify_ledger()` melakukan semua komputasi sisi server; paket `crypto` diimpor tapi tidak digunakan untuk ledger |
| `catatan_rencana.md`: retry 2× dengan delay untuk chatbot | Tidak diimplementasikan; `GeminiService` tidak memiliki logika retry (digantikan oleh failsafe Groq) |
| `koteks_percakapan_pengerjaan_mvp.md`: retry 2×/delay untuk 503/429 | Tidak diimplementasikan di kode saat ini |

---

## 15. Batasan dan Instruksi untuk Asisten AI Mendatang

### Aturan Kode Wajib

1. **Semua UI via `import 'package:ramala/template.dart'`** — jangan hardcode warna, ukuran, atau font
2. **Setiap halaman dibungkus `AppScaffold`**
3. **Semua input**: gunakan `Validators.*`, atur `maxLength`, gunakan `inputFormatters`, panggil `Validators.clean()`
4. **Tidak ada retry otomatis**: semua `FutureProvider` menggunakan `retry: (_, __) => null`
5. **Tidak ada mutasi balance/role sisi client**: semua melalui RPC
6. **Tampilan error**: selalu gunakan `AppError.message(e)` — jangan tampilkan pesan server mentah
7. **Bahasa**: semua teks UI dalam Bahasa Indonesia
8. **Tanpa codegen**: jangan tambahkan `build_runner`, `freezed`, atau `riverpod_generator`

### Jebakan Signature Widget

- `AppNavItem(icon, label, [activeIcon])` — **positional, bukan named**
- `AppScaffold` membutuhkan salah satu dari `children` atau `body` (assert akan throw jika keduanya tidak ada)
- `AppCard(glow: true)` — hanya satu per layar
- `AppButton(variant: AppButtonVariant.primary)` — hanya satu per layar/panel
- `MarketCard` — `footer` adalah **required**
- `AppBottomSheet.show<T>` mengembalikan `Future<T?>` — selalu tangani `null`
- `TradeSheet` memerlukan `market`, `heldYes`, `heldNo`

### Pola Provider

- `FutureProvider.autoDispose` untuk semua provider data
- Tempatkan provider yang digunakan bersama dalam `<feature>/presentation/<feature>_providers.dart`
- Provider hanya untuk halaman tertentu boleh didefinisikan di atas file halaman
- Setelah mutasi: invalidasi semua provider yang terpengaruh (market + price history + portfolio + balance)

### Aturan Khusus Per Fitur

- **Chatbot**: Selalu gunakan `AiChatService` (bukan `GeminiService` atau `GroqService` langsung); batas input `maxLength: 1000`
- **Konverter Waktu**: Filter daftar market agar hanya menampilkan market yang `isOpen == true`
- **Trade sheet**: Input share harus berupa `AppTextField` dengan angka langsung; tetap sertakan chip cepat; validasi ketat wajib
- **Market list**: Selalu sertakan opsi "Semua" di posisi pertama chip filter kategori; tampilkan `imageUrl` sebagai icon persegi jika ada
- **Top up**: Validasi angka di client (1–1.000.000); satu pending per user — tangani error `pending_exists`
- **Admin market**: `p_image_url` harus dikirim ke RPC jika gambar dipilih; koordinat berasal dari `PinPickerPage`
- **Admin top up**: Setelah approve/reject, request dihapus dari daftar (re-fetch / invalidasi provider)
- **Feedback admin**: List feedback hanya tampil untuk admin (cek `is_admin()` atau role di client); panggil `admin_set_feedback_hidden` untuk hide/unhide

---

## 16. Pertanyaan Terbuka dan Keterbatasan Kepercayaan

1. **Nama model Gemini**: Belum diketahui apakah `gemini-2.0-flash` valid — harus diverifikasi terhadap API Gemini sebelum mengandalkan chatbot
2. **Trailing slash di `SUPABASE_URL`**: `env.json` lama memiliki `https://...supabase.co/`; URL tanpa trailing slash direkomendasikan
3. **`minSdk` efektif**: nilai default `flutter.minSdkVersion`; beberapa paket (`local_auth`, `workmanager`) mungkin memerlukan minSdk lebih tinggi
4. **Workmanager di HP OEM**: Task background bisa tertunda jauh melampaui 15 menit
5. **`search_history` table**: Penggunaan yang dimaksudkan untuk autocomplete belum diimplementasikan

---

## 17. Cakupan Sumber dan File yang Diinspeksi

### Diinspeksi Penuh

Semua file Dart di bawah `lib/` (termasuk `template.dart`), `pubspec.yaml`, semua 6 file docs, `AndroidManifest.xml`, `build.gradle.kts`, `env.json`, dan semua 4 file migrasi di `supabase/migrations/`. `MainActivity.kt` diinspeksi via grep (mengkonfirmasi `FlutterFragmentActivity`).

### Tidak Diinspeksi

- `lib/features/contoh_struktur/`, `lib/features/trading/`, `lib/features/wallet/` — hanya gitkeep
- `lib/shell/placeholder_page.dart` — ada, dikomentari di router
- Direktori `test/` — diharapkan kosong sesuai docs
- Aset biner (`assets/gambar/`)

### Kelengkapan

**Kepercayaan Tinggi**: Arsitektur, routing, auth, implementasi semua fitur, skema database, formula LMSR, penanganan error, design system.  
**Kepercayaan Menengah**: Aturan RLS Supabase (sisi server), perilaku Workmanager per versi Android.  
**Kepercayaan Rendah**: Validitas nama model Gemini saat ini; perilaku task background di perangkat OEM.
