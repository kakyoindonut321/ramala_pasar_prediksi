import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _storage = FlutterSecureStorage();
  static const _kLast =
      'notif_last'; // created_at notifikasi terakhir yang sudah ditampilkan
  static const _task = 'ramala_notif';

  static Future<void> init() => _plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  static Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  static Future<void> show(String key, String title, String body) =>
      _plugin.show(
        id: key.hashCode & 0x7fffffff,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'ramala_main',
            'Ramala',
            channelDescription: 'Notifikasi market dan hasil',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );

  static Future<void> setLast(String iso) =>
      _storage.write(key: _kLast, value: iso);

  /// Notifikasi lama sebelum pemasangan tidak ikut ditampilkan
  static Future<void> ensureLast() async {
    if (await _storage.read(key: _kLast) == null) {
      await setLast(DateTime.now().toUtc().toIso8601String());
    }
  }

  static Future<void> startBackground() => Workmanager().registerPeriodicTask(
    _task,
    _task,
    frequency: const Duration(minutes: 15), // batas minimum Android
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    constraints: Constraints(networkType: NetworkType.connected),
  );

  static Future<void> stopBackground() async {
    await Workmanager().cancelByUniqueName(_task);
    await _storage.delete(key: _kLast);
  }

  /// Dipanggil worker: tampilkan notifikasi belum dibaca yang lebih baru dari _kLast
  static Future<void> pollBackground() async {
    final c = Supabase.instance.client;
    if (c.auth.currentSession == null) return;
    final last = await _storage.read(key: _kLast);
    var q = c
        .from('notifications')
        .select('id,title,body,created_at')
        .eq('is_read', false);
    if (last != null) q = q.gt('created_at', last);
    final rows = await q.order('created_at').limit(5);
    for (final r in rows) {
      await show(r['id'] as String, r['title'] as String, r['body'] as String);
      await setLast(r['created_at'] as String);
    }
  }
}
