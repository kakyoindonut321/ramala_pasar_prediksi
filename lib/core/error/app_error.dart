import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class AppError {
  static const _rpc = {
    'not_authenticated': 'Sesi berakhir, silakan masuk lagi.',
    'invalid_input': 'Input tidak valid.',
    'invalid_shares': 'Jumlah share tidak valid.',
    'market_not_found': 'Market tidak ditemukan.',
    'market_closed': 'Market sudah ditutup.',
    'insufficient_balance': 'Saldo tidak cukup.',
    'insufficient_shares': 'Share tidak cukup.',
    'forbidden': 'Anda tidak punya akses.',
    'invalid_close_at': 'Waktu tutup tidak valid.',
    'already_settled': 'Market sudah diselesaikan.',
  };

  static String message(Object e) {
    if (e is SocketException) return 'Tidak ada koneksi internet.';
    if (e is AuthException) {
      switch (e.code) {
        case 'invalid_credentials':
          return 'Email atau kata sandi salah.';
        case 'user_already_exists':
          return 'Email sudah terdaftar.';
        case 'weak_password':
          return 'Kata sandi terlalu lemah.';
        case 'over_request_rate_limit':
        case 'over_email_send_rate_limit':
          return 'Terlalu banyak percobaan, coba lagi nanti.';
        case 'unexpected_failure':
          return 'Username tidak valid atau sudah dipakai.';
      }
      return 'Autentikasi gagal.';
    }
    if (e is PostgrestException) {
      return _rpc[e.message] ??
          (e.code == '23505'
              ? 'Data sudah dipakai.'
              : 'Terjadi kesalahan pada server.');
    }
    // if (e is DioException) return 'Gagal terhubung ke layanan. Coba lagi.';
    return 'Terjadi kesalahan. Coba lagi.';
  }
}
