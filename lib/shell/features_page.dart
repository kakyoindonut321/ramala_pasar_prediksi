import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ramala/template.dart';

class FeaturesPage extends StatelessWidget {
  const FeaturesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.currency_exchange,
        'Konverter',
        'Mata uang, kripto, zona waktu',
        '/konverter',
      ),
      (Icons.near_me_outlined, 'Market terdekat', 'Peta dan lokasi', '/nearby'),
      (Icons.sports_esports_outlined, 'Tebak Arah', 'Game sensor', '/game'),
      (Icons.smart_toy_outlined, 'Ramala AI', 'Chatbot Gemini', '/chatbot'),
      (Icons.link, 'Ledger blockchain', 'Catatan transaksi', '/ledger'),
    ];
    return AppScaffold(
      title: 'Fitur',
      children: [
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const Divider(),
                AppListTile(
                  icon: items[i].$1,
                  title: items[i].$2,
                  subtitle: items[i].$3,
                  onTap: () => context.push(items[i].$4),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
