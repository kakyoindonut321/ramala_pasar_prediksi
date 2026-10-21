import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ramala/template.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const MainShell(this.shell, {super.key});

  @override
  Widget build(BuildContext context) {
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
          AppNavItem(Icons.rate_review_outlined, 'Saran', Icons.rate_review),
          AppNavItem(Icons.person_outline, 'Profil', Icons.person),
        ],
      ),
    );
  }
}
