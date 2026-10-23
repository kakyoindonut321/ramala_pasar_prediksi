import 'package:flutter/services.dart';

class Validators {
  /// Trim + buang karakter kontrol
  static String clean(String s) =>
      s.trim().replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');

  static String? email(String? v) {
    final s = clean(v ?? '');
    if (s.isEmpty) return 'Email wajib diisi';
    if (s.length > 100 || !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(s)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  static String? password(String? v) {
    final s = v ?? '';
    if (s.length < 8) return 'Minimal 8 karakter';
    if (s.length > 64) return 'Maksimal 64 karakter';
    if (!RegExp(r'[A-Za-z]').hasMatch(s) || !RegExp(r'\d').hasMatch(s)) {
      return 'Harus mengandung huruf dan angka';
    }
    return null;
  }

  static String? username(String? v) {
    final s = clean(v ?? '');
    if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(s)) {
      return '3-20 karakter: huruf kecil, angka, _';
    }
    return null;
  }

  static final usernameFormatters = [
    FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_]')),
  ];

  static String? displayName(String? v) {
    final s = clean(v ?? '');
    if (s.isEmpty) return 'Wajib diisi';
    if (s.length > 40) return 'Maksimal 40 karakter';
    return null;
  }

  static String? required(String? v, {int min = 1, int max = 500}) {
    final s = clean(v ?? '');
    if (s.length < min) return 'Minimal $min karakter';
    if (s.length > max) return 'Maksimal $max karakter';
    return null;
  }

  /// Rapikan kata pencarian, maksimal 60 karakter
  static String searchTerm(String s) {
    final c = clean(s);
    return c.length > 60 ? c.substring(0, 60) : c;
  }

  /// Escape wildcard untuk ilike
  static String likeEscape(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');

  /// Angka koin top up: bilangan bulat 1..1.000.000
  static String? topupAmount(String? v) {
    final s = clean(v ?? '');
    if (s.isEmpty) return 'Jumlah wajib diisi';
    final n = int.tryParse(s);
    if (n == null) return 'Masukkan angka bulat';
    if (n < 1 || n > 1000000) return 'Jumlah 1 sampai 1.000.000 koin';
    return null;
  }
}
