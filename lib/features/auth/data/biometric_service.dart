import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static const _storage = FlutterSecureStorage();
  static const _kEmail = 'bio_email', _kPass = 'bio_pass';
  final _auth = LocalAuthentication();

  Future<bool> get supported async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Biometrik aktif untuk akun ini?
  Future<bool> enabledFor(String? email) async =>
      email != null && await _storage.read(key: _kEmail) == email;

  Future<bool> get enabled => _storage.containsKey(key: _kPass);

  /// biometricOnly: false → boleh fallback ke PIN/pola/password HP
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Verifikasi identitas Anda untuk masuk',
        biometricOnly: false,
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> enable(String email, String password) async {
    await _storage.write(key: _kEmail, value: email);
    await _storage.write(key: _kPass, value: password);
  }

  Future<void> disable() async {
    await _storage.delete(key: _kEmail);
    await _storage.delete(key: _kPass);
  }

  Future<({String email, String password})?> credentials() async {
    final e = await _storage.read(key: _kEmail);
    final p = await _storage.read(key: _kPass);
    return (e == null || p == null) ? null : (email: e, password: p);
  }
}
