import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ramala/core/storage/local_db.dart';

class AuthRepository {
  GoTrueClient get _auth => Supabase.instance.client.auth;

  Future<void> login(String email, String password) =>
      _auth.signInWithPassword(email: email, password: password);

  Future<void> register(String email, String password, String username) => _auth
      .signUp(email: email, password: password, data: {'username': username});

  Future<void> logout() async {
    await _auth.signOut();
    await LocalDb.clear();
  }
}
