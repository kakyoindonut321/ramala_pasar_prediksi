import 'package:supabase_flutter/supabase_flutter.dart';

class Profile {
  const Profile(
    this.id,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.role,
  );
  final String id, username, role;
  final String? displayName, avatarUrl;

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
    m['id'] as String,
    m['username'] as String,
    m['display_name'] as String?,
    m['avatar_url'] as String?,
    m['role'] as String,
  );
}

class ProfileRepository {
  SupabaseClient get _db => Supabase.instance.client;
  String get _uid => _db.auth.currentUser!.id;

  Future<Profile> me() async => Profile.fromMap(
    await _db.from('profiles').select().eq('id', _uid).single(),
  );

  Future<double> balance() async {
    final r = await _db
        .from('wallets')
        .select('balance')
        .eq('user_id', _uid)
        .single();
    return (r['balance'] as num).toDouble();
  }

  Future<void> update({String? displayName, String? avatarUrl}) async {
    final data = {
      if (displayName != null) 'display_name': displayName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };
    if (data.isNotEmpty) await _db.from('profiles').update(data).eq('id', _uid);
  }
}
