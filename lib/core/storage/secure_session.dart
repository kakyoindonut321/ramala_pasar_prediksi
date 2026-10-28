import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(resetOnError: true),
);
const _key = 'ramala_session';

class SecureLocalStorage extends LocalStorage {
  const SecureLocalStorage();

  // Data rusak (mis. gagal dekripsi Keystore): hapus semua, jangan crash.
  Future<void> _wipe() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async {
    try {
      return await _storage.containsKey(key: _key);
    } catch (_) {
      await _wipe();
      return false;
    }
  }

  @override
  Future<String?> accessToken() async {
    try {
      final v = await _storage.read(key: _key);
      return (v == null || v.isEmpty) ? null : v;
    } catch (_) {
      await _wipe();
      return null;
    }
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    try {
      await _storage.write(key: _key, value: persistSessionString);
    } catch (_) {
      await _wipe();
      try {
        await _storage.write(key: _key, value: persistSessionString);
      } catch (_) {} // sesi tidak tersimpan, tapi login tetap jalan
    }
  }

  @override
  Future<void> removePersistedSession() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {
      await _wipe();
      try {
        // Jaring terakhir: timpa dengan kosong (dibaca sebagai tanpa sesi)
        await _storage.write(key: _key, value: '');
      } catch (_) {}
    }
  }
}
