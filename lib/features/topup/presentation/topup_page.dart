import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ramala/core/error/app_error.dart';
import 'package:ramala/core/validators/validators.dart';
import 'package:ramala/features/profile/presentation/profile_providers.dart';
import 'package:ramala/features/topup/data/topup_repository.dart';
import 'package:ramala/template.dart';

final _topupProvider = FutureProvider.autoDispose<List<TopupRequest>>(
  (ref) => TopupRepository().mine(),
  retry: (_, __) => null,
);

class TopupPage extends ConsumerStatefulWidget {
  const TopupPage({super.key});
  @override
  ConsumerState<TopupPage> createState() => _TopupPageState();
}

class _TopupPageState extends ConsumerState<TopupPage> {
  final _form = GlobalKey<FormState>();
  final _ctrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    final amount = int.parse(Validators.clean(_ctrl.text));
    setState(() => _busy = true);
    try {
      await TopupRepository().request(amount);
      _ctrl.clear();
      ref.invalidate(_topupProvider);
      if (mounted) {
        AppToast.show(
          context,
          'Permintaan terkirim, menunggu admin',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted)
        AppToast.show(context, AppError.message(e), type: ToastType.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  (String, Color) _status(String s) => switch (s) {
    'approved' => ('Disetujui', AppColors.yes),
    'rejected' => ('Ditolak', AppColors.no),
    _ => ('Menunggu', AppColors.accent),
  };

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(_topupProvider);
    final balance = ref.watch(balanceProvider);
    final df = DateFormat('d MMM yyyy, HH:mm', 'id_ID');

    return AppScaffold(
      title: 'Top up koin',
      onRefresh: () async {
        ref.invalidate(balanceProvider);
        ref.invalidate(_topupProvider);
        await ref.read(_topupProvider.future);
      },
      children: [
        AppCard(
          glow: true,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Saldo saat ini', style: AppText.bodyDim),
              balance.when(
                data: (b) => CoinText(b),
                loading: () => const AppSkeleton(width: 80, height: 20),
                error: (_, __) => const Text('-'),
              ),
            ],
          ),
        ),
        const Gap(AppSpace.lg),
        Form(
          key: _form,
          child: Column(
            children: [
              AppTextField(
                label: 'Jumlah koin (maks. 1.000.000)',
                controller: _ctrl,
                icon: Icons.toll_outlined,
                keyboardType: TextInputType.number,
                maxLength: 7,
                formatters: [FilteringTextInputFormatter.digitsOnly],
                validator: Validators.topupAmount,
                enabled: !_busy,
              ),
              const Gap(AppSpace.md),
              AppButton(
                label: 'Kirim permintaan',
                icon: Icons.send_outlined,
                loading: _busy,
                expanded: true,
                onPressed: _submit,
              ),
            ],
          ),
        ),
        const Gap(AppSpace.xl),
        const SectionHeader('Riwayat permintaan'),
        const Gap(AppSpace.sm),
        list.when(
          loading: () => const AppSkeleton(height: 120),
          error: (e, _) => ErrorState(
            message: AppError.message(e),
            onRetry: () => ref.invalidate(_topupProvider),
          ),
          data: (items) => items.isEmpty
              ? const EmptyState(
                  title: 'Belum ada permintaan',
                  message: 'Ajukan top up untuk mulai bertransaksi.',
                  icon: Icons.account_balance_wallet_outlined,
                )
              : AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        if (i > 0) const Divider(),
                        Builder(
                          builder: (_) {
                            final t = items[i];
                            final (label, color) = _status(t.status);
                            return AppListTile(
                              icon: Icons.toll_outlined,
                              title: '${Fmt.coin(t.amount)} koin',
                              subtitle: df.format(t.createdAt),
                              trailing: AppBadge(label, color: color),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
