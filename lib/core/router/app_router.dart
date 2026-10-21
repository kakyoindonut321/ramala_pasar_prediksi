import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ramala/features/auth/presentation/login_page.dart';
import 'package:ramala/features/auth/presentation/register_page.dart';
import 'package:ramala/shell/main_shell.dart';
import 'package:ramala/shell/placeholder_page.dart';
import 'package:ramala/features/feedback/presentation/feedback_page.dart';
import 'package:ramala/features/profile/presentation/profile_page.dart';
import 'package:ramala/features/market/presentation/market_detail_page.dart';
import 'package:ramala/features/market/presentation/market_list_page.dart';
import 'package:ramala/features/portfolio/presentation/portfolio_page.dart';

/// Memicu ulang redirect saat status login berubah
class _AuthRefresh extends ChangeNotifier {
  late final StreamSubscription _sub;
  _AuthRefresh() {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen(
      (_) => notifyListeners(),
    );
  }
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh();
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/pasar',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = Supabase.instance.client.auth.currentSession != null;
      final onAuth =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      if (!loggedIn && !onAuth) return '/login';
      if (loggedIn && onAuth) return '/pasar';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(
        path: '/market/:id',
        builder: (_, s) => MarketDetailPage(s.pathParameters['id']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => MainShell(shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/pasar',
                builder: (_, __) => const MarketListPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/portofolio',
                builder: (_, __) => const PortfolioPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/saran', builder: (_, __) => const FeedbackPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/profil', builder: (_, __) => const ProfilePage()),
            ],
          ),
        ],
      ),
    ],
  );
});
