<p align="center">
  <img src="assets/gambar/logo_ramala.png" alt="Logo Ramala" width="160">
</p>

# Ramala

Aplikasi pasar prediksi Android (terinspirasi Kalshi/Polymarket) berbasis Flutter. Pengguna membeli dan menjual share YES/NO pada market menggunakan koin aplikasi. Harga ditentukan oleh LMSR sehingga harga setara probabilitas.

Tugas Akhir mata kuliah **Pemrograman Aplikasi Mobile**.

## Fitur

| Area | Keterangan |
| --- | --- |
| Auth | Supabase Auth (tanpa Firebase), sesi di Android Keystore via `flutter_secure_storage`, login biometrik (`local_auth`, fallback PIN/pola) |
| Market | Daftar dengan chip Untuk kamu / Trending / kategori, pencarian (debounce), filter dan urutan, detail dengan grafik harga |
| Trading | Beli/jual YES/NO, pratinjau LMSR di client, transaksi resmi lewat RPC Postgres |
| Portofolio | Posisi, PnL, riwayat transaksi, saldo |
| Top up | Pengajuan koin oleh user, persetujuan atau penolakan oleh admin |
| LBS | Peta OpenStreetMap, market terdekat (hanya yang masih open), lokasi market |
| Konverter | Mata uang (5 fiat + 3 kripto), zona waktu (WIB, WITA, WIT, London, dll.) |
| AI | Chatbot Gemini dengan failsafe Groq |
| Sensor + game | "Tebak Arah" memakai akselerometer dan giroskop, leaderboard |
| Notifikasi | Local notification dari Supabase Realtime (foreground) dan Workmanager (background) |
| Blockchain | Ledger rantai SHA-256 (`verify_ledger()`), badge on-chain dan tautan Etherscan |
| Profil | Foto (Cloudinary), ubah nama, biometrik, Rate Us, About (saran dan kesan mata kuliah), logout |
| Admin | Buat market (gambar, pin lokasi), selesaikan market, kelola top up dan feedback |

## Teknologi

- Flutter / Dart, `flutter_riverpod` (tanpa codegen), `go_router`
- Backend: Supabase (Auth, Postgres, RLS, RPC, Realtime)
- Penyimpanan lokal: `sqflite` (cache, riwayat chat, riwayat pencarian)
- Layanan eksternal (tier gratis): Cloudinary, Gemini, Groq, CoinGecko, ExchangeRate-API, OpenStreetMap
- Lainnya: `dio`, `fl_chart`, `sensors_plus`, `geolocator`, `flutter_map`, `flutter_local_notifications`, `workmanager`, `timezone`

## Struktur

```
lib/
├── main.dart, app.dart
├── template.dart        # seluruh design system (token + komponen UI)
├── core/                # config, error, router, storage, validators, widgets
├── shell/               # bottom nav (Pasar, Portofolio, Fitur, Profil)
└── features/<fitur>/{data,domain,presentation}
supabase/migrations/     # skema, fungsi RPC, top up, feedback, on-chain, for-you, avatar
```

## Menjalankan

Prasyarat: Flutter SDK, perangkat Android fisik (sensor dan GPS tidak tersedia di emulator), proyek Supabase.

1. Instal dependensi:
   ```bash
   flutter pub get
   ```
2. Jalankan seluruh migrasi di `supabase/migrations/` secara berurutan (SQL Editor atau Supabase CLI).
3. Buat `env.json` di root (sudah di-gitignore, jangan di-commit):
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
   `SUPABASE_URL` tanpa trailing slash.
4. Jalankan:
   ```bash
   flutter run --dart-define-from-file=env.json
   ```
5. Menjadikan akun sebagai admin (SQL Editor):
   ```sql
   UPDATE public.profiles SET role = 'admin' WHERE username = 'nama';
   ```

Perubahan pada `env.json`, `AndroidManifest.xml`, atau Gradle memerlukan stop penuh lalu run ulang (bukan hot reload).

## Konfigurasi Android

- `MainActivity` harus `FlutterFragmentActivity` (biometrik).
- Izin manifest: `USE_BIOMETRIC`, lokasi, notifikasi, internet.
- `compileSdk = 37` dan `isCoreLibraryDesugaringEnabled = true` (diperlukan `flutter_local_notifications` dan `timezone`).
- `userAgentPackageName` peta harus sama dengan `applicationId` (`com.example.ramala`).

## Keamanan

- Semua perubahan saldo, posisi, market, dan role hanya lewat RPC Postgres. Client tidak punya akses tulis langsung.
- Validasi input di client (`Validators`) dan di server (constraint `CHECK` + RLS).
- Pesan error server dipetakan ke Bahasa Indonesia, tidak pernah ditampilkan mentah.
- Pemanggilan API eksternal dibatasi rate limiter client dan cache dengan TTL.

## Catatan Diketahui

- Rute `/admin` tanpa guard di client, akses dikendalikan RPC server.
- Notifikasi background bisa tertunda di perangkat OEM dengan mode hemat baterai (minimum interval 15 menit).
- Release build masih memakai debug keystore, ganti sebelum rilis.
- Verifikasi nama model Gemini pada `gemini_service.dart` terhadap dokumentasi API terbaru.
- Edge Function `record-onchain` hanya ada di dashboard Supabase. Saldo wallet testnet perlu diisi sebelum demo.

## Pemetaan Ketentuan Tugas

Login terenkripsi + session, biometrik, database lokal dan online, web service/API + LBS, menu profil/saran dan kesan/logout, konverter mata uang dan waktu, dua sensor, AI/LLM, mini game, pencarian dan pemilihan, notifikasi, dan blockchain sederhana. Seluruhnya terpenuhi sesuai fitur di atas.