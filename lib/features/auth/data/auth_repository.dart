import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ramala/core/storage/local_db.dart';
import 'package:ramala/features/notification/data/notification_service.dart';
import 'package:flutter/foundation.dart';

class AuthRepository {
  GoTrueClient get _auth => Supabase.instance.client.auth;

  Future<void> login(String email, String password) =>
      _auth.signInWithPassword(email: email, password: password);

  Future<void> register(String email, String password, String username) => _auth
      .signUp(email: email, password: password, data: {'username': username});

  Future<void> logout() async {
    // Hapus sesi lebih dulu. Scope local: tidak bergantung pada jaringan.
    await _auth.signOut(scope: SignOutScope.local);
    // Pembersihan lain tidak boleh menggagalkan logout
    for (final job in [NotificationService.stopBackground, LocalDb.clear]) {
      try {
        await job();
      } catch (e) {
        debugPrint('CLEANUP ERROR: $e');
      }
    }
  }
}
