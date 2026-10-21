import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ramala/app.dart';
import 'package:ramala/core/config/env.dart';
import 'package:ramala/core/storage/secure_session.dart';
import 'package:workmanager/workmanager.dart';
import 'package:ramala/features/notification/data/background_worker.dart';
import 'package:ramala/features/notification/data/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(
      localStorage: const SecureLocalStorage(),
    ),
  );
  await NotificationService.init();
  await Workmanager().initialize(callbackDispatcher);
  tz.initializeTimeZones();
  runApp(const ProviderScope(child: RamalaApp()));
}
