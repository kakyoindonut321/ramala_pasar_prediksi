# Panduan Menjalankan Ramala

## Prasyarat

- Flutter SDK terpasang (Dart `^3.13.5`, cek dengan `flutter --version`)
- Android Studio atau Android SDK, plus **ponsel fisik** (USB debugging aktif) atau emulator
- File `env.json` dari pemilik proyek (tidak ada di GitHub karena berisi kunci rahasia)

## Langkah

**1. Cek lingkungan**

```
flutter doctor
```

Pastikan bagian Android toolchain bertanda centang.

**2. Pasang dependensi**

```
flutter pub get
```

**3. Buat `env.json` di root proyek** (sejajar `pubspec.yaml`):

```json
{
  "SUPABASE_URL": "https://xxxx.supabase.co",
  "SUPABASE_ANON_KEY": "sb_publishable_...",
  "CLOUDINARY_CLOUD_NAME": "...",
  "CLOUDINARY_UPLOAD_PRESET": "...",
  "GEMINI_API_KEY": "AIza..."
}
```

**4. Hubungkan perangkat dan cek terdeteksi**

```
flutter devices
```

**5. Jalankan**

```
flutter run --dart-define-from-file=env.json
```

Jika ada lebih dari satu perangkat: `flutter run -d <id_perangkat> --dart-define-from-file=env.json`

## Catatan penting

- Setiap mengubah `env.json`, `AndroidManifest.xml`, atau file Gradle, **hentikan app lalu jalankan ulang penuh**. Hot reload dan hot restart tidak membaca perubahan itu.
- Build pertama lama (beberapa menit) karena Gradle mengunduh dependensi.
- Fitur game sensor (Tebak Arah) butuh ponsel fisik. Nearby butuh GPS aktif.
- Untuk akses admin, akun harus diubah rolenya lewat SQL Editor Supabase: `update public.profiles set role = 'admin' where username = 'usernamemu';`

## Jika error

| Gejala                            | Solusi                                                     |
| --------------------------------- | ---------------------------------------------------------- |
| `Gradle`/`minSdk`/`desugar` error | `flutter clean`, lalu `flutter pub get` dan jalankan ulang |
| Login selalu gagal                | Cek `SUPABASE_URL` dan `SUPABASE_ANON_KEY` di `env.json`   |
| Chatbot gagal                     | Cek `GEMINI_API_KEY`, atau Gemini sedang sibuk (coba lagi) |
| Perangkat tidak terdeteksi        | Aktifkan USB debugging, jalankan `adb devices`             |
