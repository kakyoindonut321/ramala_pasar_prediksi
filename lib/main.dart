import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ramala/app.dart';
import 'package:ramala/core/config/env.dart';
import 'package:ramala/core/storage/secure_session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(
      localStorage: const SecureLocalStorage(),
    ),
  );
  runApp(const ProviderScope(child: RamalaApp()));
}
