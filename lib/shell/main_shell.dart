import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ramala/features/notification/data/notification_service.dart';
import 'package:ramala/features/notification/presentation/notification_page.dart';
import 'package:ramala/template.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell(this.shell, {super.key});
  final StatefulNavigationShell shell;
  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  RealtimeChannel? _ch;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await NotificationService.requestPermission();
    await NotificationService.ensureLast();
    await NotificationService.startBackground();
    final c = Supabase.instance.client;
    final uid = c.auth.currentUser?.id;
    if (uid == null || !mounted) return;
    // Saat app terbuka: notifikasi baru langsung muncul lewat Realtime
    _ch = c
        .channel('notif_$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: uid,
          ),
          callback: (p) {
            final r = p.newRecord;
            NotificationService.show(
              r['id'] as String,
              r['title'] as String,
              r['body'] as String,
            );
            NotificationService.setLast(r['created_at'] as String);
            if (mounted) ref.invalidate(notificationsProvider);
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    final ch = _ch;
    if (ch != null) Supabase.instance.client.removeChannel(ch);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shell = widget.shell;
    return AppScaffold(
      body: shell,
      bottomNav: AppBottomNav(
        current: shell.currentIndex,
        onTap: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        items: const [
          AppNavItem(Icons.show_chart_outlined, 'Pasar', Icons.show_chart),
          AppNavItem(
            Icons.account_balance_wallet_outlined,
            'Portofolio',
            Icons.account_balance_wallet,
          ),
          AppNavItem(Icons.apps_outlined, 'Fitur', Icons.apps),
          // AppNavItem(Icons.rate_review_outlined, 'Saran', Icons.rate_review),
          AppNavItem(Icons.person_outline, 'Profil', Icons.person),
        ],
      ),
    );
  }
}
