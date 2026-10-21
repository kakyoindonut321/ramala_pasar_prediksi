import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'package:ramala/core/config/env.dart';
import 'package:ramala/core/storage/secure_session.dart';
import 'package:ramala/features/notification/data/notification_service.dart';

/// Entry point isolate background (wajib top-level)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, input) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await Supabase.initialize(
        url: Env.supabaseUrl,
        anonKey: Env.supabaseAnonKey,
        authOptions: FlutterAuthClientOptions(
          localStorage: const SecureLocalStorage(),
        ),
      );
      await NotificationService.init();
      await NotificationService.pollBackground();
    } catch (_) {} // gagal sekali tidak masalah, dicoba lagi 15 menit kemudian
    return true;
  });
}
