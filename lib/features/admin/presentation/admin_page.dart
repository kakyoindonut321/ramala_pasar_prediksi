import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ramala/features/admin/presentation/admin_topup_page.dart';
import 'package:ramala/template.dart';

class AdminPage extends ConsumerWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingTopupsProvider).value?.length ?? 0;
    return AppScaffold(
      title: 'Panel Admin',
      onRefresh: () async => ref.invalidate(pendingTopupsProvider),
      children: [
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              AppListTile(
                icon: Icons.add_location_alt_outlined,
                title: 'Buat market',
                subtitle: 'Tambah market prediksi baru',
                onTap: () => context.push('/admin/market-baru'),
              ),
              const Divider(),
              AppListTile(
                icon: Icons.add_card_outlined,
                title: 'Permintaan top up',
                subtitle: 'Setujui atau tolak permintaan koin',
                trailing: pending > 0
                    ? AppBadge('$pending', color: AppColors.accent)
                    : null,
                onTap: () => context.push('/admin/topup'),
              ),
              const Divider(),
              AppListTile(
                icon: Icons.gavel,
                title: 'Selesaikan market',
                subtitle: 'Tentukan hasil market yang berjalan',
                onTap: () => context.push('/admin/selesaikan'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
