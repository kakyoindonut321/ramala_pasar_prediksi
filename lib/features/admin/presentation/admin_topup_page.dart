import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ramala/core/error/app_error.dart';
import 'package:ramala/template.dart';

class PendingTopup {
  final String id, username;
  final String? displayName, avatarUrl;
  final int amount;
  final DateTime createdAt;
  const PendingTopup(
    this.id,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.amount,
    this.createdAt,
  );

  factory PendingTopup.fromMap(Map<String, dynamic> m) {
    final p = m['profiles'] as Map<String, dynamic>;
    return PendingTopup(
      m['id'] as String,
      p['username'] as String,
      p['display_name'] as String?,
      p['avatar_url'] as String?,
      (m['amount'] as num).toInt(),
      DateTime.parse(m['created_at'] as String).toLocal(),
    );
  }
}

/// Hanya yang masih pending; yang sudah diproses otomatis tidak muncul lagi.
final pendingTopupsProvider = FutureProvider.autoDispose<List<PendingTopup>>((
  ref,
) async {
  final rows = await Supabase.instance.client
      .from('topup_requests')
      .select(
        'id, amount, created_at, profiles!topup_requests_user_id_fkey(username, display_name, avatar_url)',
      )
      .eq('status', 'pending')
      .order('created_at')
      .limit(50);
  return (rows as List).map((e) => PendingTopup.fromMap(e)).toList();
}, retry: (_, __) => null);

class AdminTopupPage extends ConsumerStatefulWidget {
  const AdminTopupPage({super.key});
  @override
  ConsumerState<AdminTopupPage> createState() => _State();
}

class _State extends ConsumerState<AdminTopupPage> {
  String? _busyId;

  Future<void> _act(PendingTopup t, bool approve) async {
    if (_busyId != null) return;
    final ok = await AppConfirmDialog.show(
      context,
      title: approve ? 'Setujui top up?' : 'Tolak top up?',
      message: approve
          ? '${Fmt.coin(t.amount)} koin akan ditambahkan ke saldo @${t.username}.'
          : 'Permintaan @${t.username} ditolak dan saldo tidak berubah.',
      confirmLabel: approve ? 'Setujui' : 'Tolak',
      danger: !approve,
    );
    if (!ok || !mounted) return;
    setState(() => _busyId = t.id);
    try {
      await Supabase.instance.client.rpc(
        approve ? 'admin_approve_topup' : 'admin_reject_topup',
        params: {'p_id': t.id},
      );
      ref.invalidate(pendingTopupsProvider);
      if (mounted) {
        AppToast.show(
          context,
          approve ? 'Top up disetujui' : 'Top up ditolak',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted)
        AppToast.show(context, AppError.message(e), type: ToastType.error);
      ref.invalidate(
        pendingTopupsProvider,
      ); // mungkin sudah diproses admin lain
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(pendingTopupsProvider);
    final df = DateFormat('d MMM y, HH:mm');
    return AppScaffold(
      title: 'Permintaan top up',
      onRefresh: () async {
        ref.invalidate(pendingTopupsProvider);
        await ref.read(pendingTopupsProvider.future);
      },
      children: [
        list.when(
          loading: () => const AppSkeleton(height: 140),
          error: (e, _) => ErrorState(
            message: AppError.message(e),
            onRetry: () => ref.invalidate(pendingTopupsProvider),
          ),
          data: (items) => items.isEmpty
              ? const EmptyState(
                  title: 'Tidak ada permintaan',
                  message: 'Semua permintaan top up sudah diproses.',
                  icon: Icons.task_alt,
                )
              : Column(
                  children: [
                    for (final t in items) ...[
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                AppAvatar(
                                  name: t.displayName ?? t.username,
                                  url: t.avatarUrl,
                                  radius: 20,
                                ),
                                const SizedBox(width: AppSpace.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.displayName ?? t.username,
                                        style: AppText.heading,
                                      ),
                                      Text(
                                        '@${t.username}',
                                        style: AppText.caption,
                                      ),
                                    ],
                                  ),
                                ),
                                CoinText(t.amount),
                              ],
                            ),
                            const Gap(AppSpace.sm),
                            Text(
                              df.format(t.createdAt),
                              style: AppText.caption,
                            ),
                            const Gap(AppSpace.md),
                            Row(
                              children: [
                                Expanded(
                                  child: AppButton(
                                    label: 'Tolak',
                                    variant: AppButtonVariant.danger,
                                    onPressed: _busyId == null
                                        ? () => _act(t, false)
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: AppSpace.md),
                                Expanded(
                                  child: AppButton(
                                    label: 'Setujui',
                                    variant: AppButtonVariant.secondary,
                                    loading: _busyId == t.id,
                                    onPressed: _busyId == null
                                        ? () => _act(t, true)
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Gap(AppSpace.md),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}
