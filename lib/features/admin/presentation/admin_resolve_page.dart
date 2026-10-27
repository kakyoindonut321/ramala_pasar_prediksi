import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ramala/core/error/app_error.dart';
import 'package:ramala/features/market/domain/market.dart';
import 'package:ramala/features/market/presentation/market_providers.dart';
import 'package:ramala/template.dart';
import 'package:ramala/features/market/data/onchain_service.dart';

class AdminResolvePage extends ConsumerStatefulWidget {
  const AdminResolvePage({super.key});
  @override
  ConsumerState<AdminResolvePage> createState() => _State();
}

class _State extends ConsumerState<AdminResolvePage> {
  bool _busy = false;

  void _toast(String m, [ToastType t = ToastType.error]) {
    if (mounted) AppToast.show(context, m, type: t);
  }

  Future<void> _resolve(Market m) async {
    final outcome = await AppBottomSheet.show<String>(
      context,
      title: 'Hasil market',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(m.title, style: AppText.bodyDim),
          const Gap(AppSpace.lg),
          AppButton(
            label: 'YES menang',
            onPressed: () => Navigator.pop(context, 'yes'),
          ),
          const Gap(AppSpace.sm),
          AppButton(
            label: 'NO menang',
            variant: AppButtonVariant.danger,
            onPressed: () => Navigator.pop(context, 'no'),
          ),
        ],
      ),
    );
    if (outcome == null || !mounted) return;
    final ok = await AppConfirmDialog.show(
      context,
      title: 'Selesaikan market?',
      message:
          'Hasil ${outcome.toUpperCase()} tidak dapat diubah. Payout langsung dibagikan.',
      confirmLabel: 'Selesaikan',
      danger: true,
    );
    if (!ok) return;
    setState(() => _busy = true);
    final container = ProviderScope.containerOf(context);
    try {
      await Supabase.instance.client.rpc(
        'admin_resolve_market',
        params: {'p_market': m.id, 'p_outcome': outcome},
      );
      ref.invalidate(marketListProvider);
      ref.invalidate(marketProvider(m.id));
      _toast('Market diselesaikan', ToastType.success);

      // Catat on-chain di latar belakang (bisa sampai 90 detik).
      // Kegagalan tidak membatalkan resolusi; statusnya sudah dicatat server.
      OnchainService().record(m.id).catchError((_) => 'failed').whenComplete(
        () {
          container.invalidate(marketProvider(m.id));
          container.invalidate(marketListProvider);
        },
      );
    } catch (e) {
      _toast(AppError.message(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final markets = ref.watch(marketListProvider(''));
    return AppScaffold(
      title: 'Selesaikan market',
      onRefresh: () async {
        ref.invalidate(marketListProvider);
        await ref.read(marketListProvider('').future);
      },
      children: [
        if (_busy) const LinearProgressIndicator(color: AppColors.primary),
        markets.when(
          loading: () => const AppSkeleton(height: 120),
          error: (e, _) => ErrorState(
            message: AppError.message(e),
            onRetry: () => ref.invalidate(marketListProvider('')),
          ),
          data: (all) {
            final open = all.where((m) => m.status == 'open').toList();
            if (open.isEmpty) {
              return const EmptyState(
                title: 'Tidak ada market aktif',
                message: 'Semua market sudah diselesaikan.',
                icon: Icons.task_alt,
              );
            }
            return AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < open.length; i++) ...[
                    if (i > 0) const Divider(),
                    AppListTile(
                      icon: Icons.gavel,
                      title: open[i].title,
                      subtitle:
                          'Tutup ${DateFormat('d MMM y HH:mm').format(open[i].closeAt.toLocal())}',
                      onTap: _busy ? null : () => _resolve(open[i]),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
