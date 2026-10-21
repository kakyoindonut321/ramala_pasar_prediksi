import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ramala/core/storage/local_db.dart';
import 'package:ramala/features/notification/domain/app_notification.dart';

class NotificationRepository {
  SupabaseClient get _db => Supabase.instance.client;

  Future<List<AppNotification>> list() async {
    final uid = _db.auth.currentUser!.id;
    final rows = await LocalDb.cachedList(
      'notif:$uid',
      () => _db
          .from('notifications')
          .select('id,title,body,data,is_read,created_at')
          .order('created_at', ascending: false)
          .limit(50),
    );
    return rows.map(AppNotification.fromMap).toList();
  }

  Future<void> markRead(String id) async {
    await _db.from('notifications').update({'is_read': true}).eq('id', id);
  }

  Future<void> markAllRead() async {
    await _db
        .from('notifications')
        .update({'is_read': true})
        .eq('is_read', false);
  }
}
