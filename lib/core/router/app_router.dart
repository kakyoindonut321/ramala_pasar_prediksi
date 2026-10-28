import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ramala/features/admin/presentation/admin_create_market_page.dart';
import 'package:ramala/features/admin/presentation/admin_page.dart';
import 'package:ramala/features/admin/presentation/admin_resolve_page.dart';
import 'package:ramala/features/admin/presentation/admin_topup_page.dart';
import 'package:ramala/features/chatbot/presentation/chat_page.dart';
import 'package:ramala/features/converter/presentation/converter_page.dart';
import 'package:ramala/features/game/presentation/game_page.dart';
import 'package:ramala/features/ledger/presentation/ledger_page.dart';
import 'package:ramala/features/nearby/presentation/nearby_page.dart';
import 'package:ramala/features/notification/presentation/notification_page.dart';
import 'package:ramala/features/topup/presentation/topup_page.dart';
import 'package:ramala/shell/features_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ramala/features/auth/presentation/login_page.dart';
import 'package:ramala/features/auth/presentation/register_page.dart';
import 'package:ramala/shell/main_shell.dart';
// import 'package:ramala/shell/placeholder_page.dart';
import 'package:ramala/features/feedback/presentation/feedback_page.dart';
import 'package:ramala/features/profile/presentation/profile_page.dart';
import 'package:ramala/features/market/presentation/market_detail_page.dart';
import 'package:ramala/features/market/presentation/market_list_page.dart';
import 'package:ramala/features/portfolio/presentation/portfolio_page.dart';
import 'package:ramala/features/about/presentation/about_page.dart';

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
      GoRoute(path: '/konverter', builder: (_, __) => const ConverterPage()),
      GoRoute(path: '/nearby', builder: (_, __) => const NearbyPage()),
      GoRoute(path: '/game', builder: (_, __) => const GamePage()),
      GoRoute(path: '/chatbot', builder: (_, __) => const ChatPage()),
      GoRoute(
        path: '/notifikasi',
        builder: (_, __) => const NotificationPage(),
      ),
      GoRoute(path: '/ledger', builder: (_, __) => const LedgerPage()),
      GoRoute(
        path: '/admin',
        builder: (_, __) => const AdminPage(),
        routes: [
          GoRoute(
            path: 'market-baru',
            builder: (_, __) => const AdminCreateMarketPage(),
          ),
          GoRoute(path: 'topup', builder: (_, __) => const AdminTopupPage()),
          GoRoute(
            path: 'selesaikan',
            builder: (_, __) => const AdminResolvePage(),
          ),
        ],
      ),
      GoRoute(path: '/topup', builder: (_, __) => const TopupPage()),
      GoRoute(path: '/about', builder: (_, __) => const AboutPage()),
      GoRoute(path: '/rate', builder: (_, __) => const FeedbackPage()),
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
              GoRoute(path: '/fitur', builder: (_, __) => const FeaturesPage()),
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
