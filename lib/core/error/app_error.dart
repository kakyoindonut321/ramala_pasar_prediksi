import 'dart:io';

import 'package:dio/dio.dart';
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
    if (e is DioException) {
      switch (e.response?.statusCode) {
        case 503:
          return 'Layanan AI sedang sibuk. Coba lagi beberapa saat lagi.';
        case 429:
          return 'Kuota layanan habis atau terlalu banyak permintaan. Coba lagi nanti.';
        case 400:
        case 401:
        case 403:
        case 404:
          return 'Layanan tidak dapat diakses. Periksa konfigurasi API.';
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'Tidak ada koneksi atau layanan lambat merespons.';
      }
      return 'Gagal terhubung ke layanan. Coba lagi.';
    }
    return 'Terjadi kesalahan. Coba lagi.';
  }
}
