import 'package:supabase_flutter/supabase_flutter.dart';

class TopupRequest {
  final String id, status;
  final int amount;
  final DateTime createdAt;
  const TopupRequest(this.id, this.status, this.amount, this.createdAt);

  factory TopupRequest.fromMap(Map<String, dynamic> m) => TopupRequest(
    m['id'] as String,
    m['status'] as String,
    (m['amount'] as num).toInt(),
    DateTime.parse(m['created_at'] as String).toLocal(),
  );
}

class TopupRepository {
  final _db = Supabase.instance.client;

  Future<void> request(int amount) =>
      _db.rpc('request_topup', params: {'p_amount': amount});

  /// Riwayat milik sendiri (RLS mengizinkan admin melihat semua, jadi filter eksplisit)
  Future<List<TopupRequest>> mine() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw const AuthException('not_authenticated');
    final rows = await _db
        .from('topup_requests')
        .select('id, status, amount, created_at')
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(20);
    return (rows as List).map((e) => TopupRequest.fromMap(e)).toList();
  }
}
