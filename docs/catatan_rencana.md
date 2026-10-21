catatan awal

## Catatan penting atas rencana

1. **Biometric**: pakai package `local_auth`. Ia sudah otomatis fallback ke PIN/pola/password HP jika `biometricOnly: false`. Cocok persis dengan keinginanmu.
2. **Enkripsi login**: syarat tugas "tanpa Firebase" terpenuhi dengan Supabase Auth. Tambahan aman: simpan session/token di `flutter_secure_storage`, bukan SharedPreferences. Hash password sudah ditangani Supabase (bcrypt), jadi tidak perlu hash manual di client.
3. **API key Gemini ter-expose**: boleh sesuai keputusanmu, tapi jangan taruh di kode. Pakai `--dart-define` atau file `.env` yang di-gitignore. Pembatasan prompt tetap di client, plus batasi panjang input dan jumlah panggilan per menit.
4. **Validasi ketat**: sebagian validasi harus di sisi server juga (Postgres `CHECK` constraint, RLS di Supabase), karena validasi client bisa dilewati. Ini juga mendukung prinsip "tidak perlu rombak".
5. **Notifikasi**: tanpa Firebase, FCM sulit dipakai. Opsi realistis: **local notification** (`flutter_local_notifications`) yang dipicu oleh **Supabase Realtime** saat app terbuka, plus polling ringan via `workmanager` saat background. Cukup untuk tugas kuliah.
6. **Blockchain sederhana**: ide bagus. Tabel `ledger` dengan kolom `prev_hash`, `hash` (SHA-256 dari data blok + prev_hash), `nonce` opsional untuk mini proof-of-work. Ada tombol "verifikasi chain" di UI. Hash dihitung di client (`crypto` package) atau Postgres function.
7. **Sensor + game**: ide usulan yang nyambung tema: _"Tebak arah"_ (miringkan HP kiri/kanan untuk memilih YES/NO dengan accelerometer, gyroscope untuk memutar roda) agar tidak bergantung pada game teman.

Admin ditandai kolom role di tabel profiles. Semua RPC admin (buat dan resolve market) mengecek role di server.
Tanpa codegen (freezed, build_runner, riverpod_generator) agar kode lebih ringkas dan mudah di-prompt.
API key lewat --dart-define-from-file=env.json (di-gitignore), tanpa package tambahan.

## Algoritma khas pasar prediksi (untuk MVP)

- **LMSR (Logarithmic Market Scoring Rule)** atau **constant product AMM** untuk harga YES/NO. Rekomendasi: **LMSR**, karena harga = probabilitas (0 sampai 1) dan mudah dijelaskan di laporan.
- Resolusi market (admin menetapkan hasil), lalu payout 1 per share pemenang.
- Saldo dummy (mis. 1000 koin awal), posisi, PnL.
- Order book bisa ditunda, AMM sudah cukup.

## Keputusan yang dipilih

1. **Logika transaksi (beli/jual share, hitung harga) ditaruh di mana?**: Postgres function (RPC) di Supabase, agar atomik, aman dari manipulasi client, dan tidak perlu server sendiri.
2. **State management Flutter**: Riverpod
3. **Struktur folder**: feature-first
4. **Siapa yang membuat market dan meresolusinya?** Admin lewat dashboard Supabase/role admin di app
5. **Sinkronisasi lokal sqflite**: cache (market list, profil, riwayat)

nanti:
workmanager dan flutter_local_notifications butuh sedikit konfigurasi Android nanti (AndroidManifest.xml, minSdk). anda jabarkan saat masuk fitur notifikasi.
local_auth butuh MainActivity extend FlutterFragmentActivity dan izin USE_BIOMETRIC. anda jabarkan saat masuk fitur auth.
