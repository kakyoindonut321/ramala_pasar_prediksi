# Recap Konteks Percakapan (Bahan Laporan)

Recap ini mencakup keputusan, masalah, dan pembelajaran dari percakapan, bukan seluruh kode proyek.

## 1. Alur Kerja Pengembangan

Pengembangan dibagi per tahap, tiap tahap berisi langkah persiapan, kode, cek hasil, dan catatan.

| Tahap                  | Isi                                                                                        |
| ---------------------- | ------------------------------------------------------------------------------------------ |
| 1. Fondasi             | Env, error mapping, validator, session terenkripsi, router, login/register, shell navigasi |
| 2. Akun                | Login biometrik, profil dan foto (Cloudinary), saran & kesan, logout                       |
| 3. Inti pasar          | Daftar market, pencarian, detail, LMSR, trading via RPC, portofolio, cache sqflite         |
| 4. Admin & kepercayaan | Buat/resolve market, ledger blockchain dan verifikasi, notifikasi                          |
| 5. Fitur tema          | Konverter mata uang/kripto/waktu, Nearby (LBS), game sensor, chatbot Gemini                |
| 6. Pengujian & revisi  | Perbaikan bug dan penyempurnaan (laporan dikerjakan terpisah)                              |

## 2. Keputusan Desain dan Alasannya

- **Autentikasi:** Supabase Auth tanpa Firebase. Token sesi disimpan di `flutter_secure_storage` (Android Keystore) lewat subclass `LocalStorage`, bukan `shared_preferences`. Password di-hash bcrypt oleh Supabase.
- **Biometrik:** `local_auth` dengan `biometricOnly: false` (fallback PIN/pola). Saat diaktifkan, email dan kata sandi disimpan terenkripsi di Keystore, lalu dipakai login ulang setelah verifikasi sidik jari. Trade-off: kredensial tersimpan di perangkat (hanya terbaca oleh app ini).
- **Harga market:** LMSR (_automated market maker_), bukan order book. Alasan: likuiditas selalu tersedia, tanpa matching engine, implementasi jauh lebih sederhana. Kerugian maksimum market maker dibatasi `b × ln(2)` per market. Kelemahan: tidak ada limit order. Order book dan slippage limit dicatat sebagai pengembangan lanjutan.
- **Keamanan transaksi:** client hanya mengirim jumlah share. Biaya dihitung server di satu transaksi database (`for update` pada market dan dompet). Pratinjau LMSR di client hanya estimasi. Client tidak bisa mengubah saldo, posisi, market, atau role (dibatasi RLS dan `grant` per kolom).
- **Blockchain sederhana:** tabel `ledger` dengan `prev_hash`, `hash = SHA-256(idx|prev_hash|data)`, dan advisory lock agar urutan blok konsisten. Fungsi `verify_ledger()` menghitung ulang rantai dan mengembalikan blok pertama yang rusak. Uji tamper: `update ledger set data='x' where idx=1;` lewat SQL Editor (superuser), lalu verifikasi menunjukkan "Blok #1 rusak". Client biasa tidak punya hak tulis.
- **Notifikasi tanpa FCM:** `flutter_local_notifications` dipicu Supabase Realtime saat app terbuka, plus `workmanager` polling periodik (minimum 15 menit, batas Android) saat background. Penanda `notif_last` mencegah notifikasi lama muncul ulang.
- **Cache offline:** sqflite (`cache`, `chat_messages`, `search_history`). Cache dipakai hanya saat gagal jaringan, bukan saat error server. Kurs memakai TTL (fiat 1 jam, kripto 2 menit). Cache dikosongkan saat logout.
- **Chatbot:** Gemini lewat `dio`, system prompt dibatasi (jawaban singkat, tanpa nasihat investasi nyata, abaikan permintaan mengubah aturan), konteks market aktif disisipkan, rate limit client 15 pesan per 10 menit, riwayat di sqflite.
- **Game sensor "Tebak Arah":** accelerometer (kemiringan) dan gyroscope (putaran), 10 ronde, skor ke tabel `game_scores`, papan skor.
- **LBS:** `geolocator` dan `flutter_map` (OpenStreetMap), market diurutkan berdasarkan jarak.
- **Struktur:** feature-first, Riverpod tanpa codegen, `go_router` dengan satu `StatefulShellRoute` (5 tab: Pasar, Portofolio, Fitur, Saran, Profil), rute detail di luar shell.
- **Validasi dan error:** semua input dibatasi dan dirapikan (`Validators`), validasi client tidak menggantikan constraint server. Error server dipetakan ke pesan Indonesia di `AppError`, tanpa menampilkan pesan mentah.

## 3. Masalah yang Ditemui dan Solusinya (Bahan Bab Pengujian)

| No  | Masalah                                     | Penyebab                                                                                                      | Solusi                                                                                               |
| --- | ------------------------------------------- | ------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| 1   | `LocalStorage` tidak bisa diinstansiasi     | Kelas abstrak di supabase_flutter 2.x                                                                         | Buat subclass `SecureLocalStorage`                                                                   |
| 2   | `AppNavItem` parameter tidak terdefinisi    | Konstruktor memakai parameter posisional, bukan bernama                                                       | Sesuaikan ke urutan posisional                                                                       |
| 3   | Login dan register gagal                    | `SUPABASE_URL` berisi `/rest/v1/`                                                                             | Pakai URL dasar saja                                                                                 |
| 4   | `MarketCard` meminta `footer`               | Parameter wajib tidak diisi                                                                                   | Tambahkan teks footer (tanggal tutup/hasil)                                                          |
| 5   | Dua `StatefulShellRoute` di router          | Penanda instruksi (`// ...`) tersalin sebagai kode                                                            | Satu shell dengan semua branch                                                                       |
| 6   | `DateFormat` tidak dikenali                 | Import `intl` belum ada                                                                                       | Tambahkan import                                                                                     |
| 7   | Error sintaks di `gemini_service`           | `?[` terbaca sebagai operator ternary                                                                         | Parsing respons bertahap dengan pengecekan tipe                                                      |
| 8   | `_finish()` dikembalikan dari fungsi `void` | Mengembalikan `Future` dari `void`                                                                            | Pisahkan jadi dua pernyataan                                                                         |
| 9   | Chatbot 404                                 | Model `gemini-2.5-flash` tidak tersedia untuk akun baru                                                       | Ganti nama model (konstanta tunggal)                                                                 |
| 10  | Chatbot 503                                 | Lonjakan permintaan di server Gemini                                                                          | Retry otomatis 2 kali (jeda 2 dan 4 detik), pesan error spesifik per status HTTP (503, 429, 400-404) |
| 11  | Logout tidak menghapus sesi                 | `stopBackground()` dijalankan sebelum `signOut()` dan bisa melempar error sehingga `signOut` tidak terpanggil | `signOut` (scope local) dijalankan lebih dulu, pembersihan lain dibuat best-effort dengan try/catch  |
| 12  | Halaman profil error sesaat setelah logout  | Provider memuat ulang dengan `currentUser!` saat sesi kosong                                                  | Redirect eksplisit ke `/login` dan `_uid` melempar error terkontrol                                  |
| 13  | Pasar selesai tampil di atas daftar         | Daftar tidak dibedakan aktif dan selesai                                                                      | Pisahkan: aktif di atas (urut paling cepat tutup), selesai di bagian lipat                           |

Catatan: masalah logout (no. 11) sempat muncul lagi setelah hot reload dan hilang setelah restart penuh. Statusnya masih dipantau.

## 4. Pembelajaran Teknis (Bahan Pembahasan)

- Perubahan `env.json`, `AndroidManifest.xml`, dan Gradle tidak terbaca oleh hot reload atau hot restart, jadi perlu restart penuh.
- Nilai di `--dart-define` ikut terkemas di APK. API key Gemini bersifat tidak sepenuhnya rahasia, sehingga perlu dibatasi kuotanya.
- Operasi pembersihan (notifikasi, cache) tidak boleh menghalangi operasi keamanan utama (logout).
- Layanan eksternal bisa berubah (model dipensiunkan, lonjakan permintaan), sehingga nama model dibuat satu konstanta dan error dipetakan per status HTTP.
- Asumsi pada nama parameter widget template harus diverifikasi terhadap kode asli, karena sumber kesalahan terbanyak adalah ketidaksesuaian signature.
- Sensor dan GPS hanya bisa diuji penuh di ponsel fisik. Polling background Android punya batas minimum 15 menit dan bisa tertunda oleh mode hemat daya.

## 5. Hasil Pengujian yang Sudah Dikonfirmasi

- Login/register, penyimpanan sesi, upload foto profil, daftar market dan filter, trading beli/jual, portofolio, notifikasi setelah resolve market, dan verifikasi ledger: berjalan.
- Belum teruji penuh: notifikasi realtime dan polling background (hanya notifikasi setelah resolve yang terkonfirmasi), uji tamper ledger, serta konsistensi logout.

## 6. Pengembangan Lanjutan yang Disebut

Order book dan limit order, batas harga maksimum (slippage limit) pada RPC, gambar market di form admin, notifikasi tambahan (market hampir tutup), serta penyempurnaan jual share pecahan (stepper berlangkah 1).

## 7. Tambahan Operasional

- Ikon launcher custom dapat dipasang lewat `flutter_launcher_icons` (PNG persegi minimal 1024×1024, opsional adaptive icon dengan foreground di area tengah sekitar 66%), berlaku juga di build debug.
- Panduan menjalankan proyek bagi anggota lain sudah dibuat: `flutter pub get`, siapkan `env.json`, `flutter run --dart-define-from-file=env.json`.
