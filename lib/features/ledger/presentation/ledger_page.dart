import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ramala/core/error/app_error.dart';
import 'package:ramala/template.dart';

final ledgerProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) async => List<Map<String, dynamic>>.from(
    await Supabase.instance.client
        .from('ledger')
        .select('idx,prev_hash,data,hash')
        .order('idx', ascending: false)
        .limit(50),
  ),
  retry: (_, __) => null,
);

class LedgerPage extends ConsumerStatefulWidget {
  const LedgerPage({super.key});
  @override
  ConsumerState<LedgerPage> createState() => _LedgerPageState();
}

class _LedgerPageState extends ConsumerState<LedgerPage> {
  bool _busy = false;
  int? _bad; // idx blok rusak

  Future<void> _verify() async {
    setState(() => _busy = true);
    try {
      // Server menghitung ulang seluruh rantai hash
      final r = await Supabase.instance.client.rpc('verify_ledger');
      if (!mounted) return;
      setState(() => _bad = (r as num?)?.toInt());
      if (r == null) {
        AppToast.show(
          context,
          'Rantai valid, tidak ada blok yang diubah.',
          type: ToastType.success,
        );
      } else {
        AppToast.show(context, 'Blok #$r rusak!', type: ToastType.error);
      }
    } catch (e) {
      if (mounted)
        AppToast.show(context, AppError.message(e), type: ToastType.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _short(String h) => '${h.substring(0, 12)}…';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(ledgerProvider);
    return AppScaffold(
      title: 'Ledger Blockchain',
      onRefresh: () async {
        ref.invalidate(ledgerProvider);
        try {
          await ref.read(ledgerProvider.future);
        } catch (_) {}
      },
      children: [
        Text(
          'Setiap transaksi dicatat dalam rantai blok. Hash tiap blok = SHA-256(idx|prev_hash|data).',
          style: AppText.bodyDim,
        ),
        const Gap(AppSpace.lg),
        AppButton(
          label: 'Verifikasi rantai',
          icon: Icons.verified_outlined,
          loading: _busy,
          onPressed: _busy ? null : _verify,
        ),
        const Gap(AppSpace.lg),
        async.when(
          loading: () => const AppSkeleton(height: 200),
          error: (e, _) => ErrorState(
            message: AppError.message(e),
            onRetry: () => ref.invalidate(ledgerProvider),
          ),
          data: (rows) => rows.isEmpty
              ? const EmptyState(
                  title: 'Ledger kosong',
                  message: 'Blok pertama dibuat saat ada transaksi.',
                  icon: Icons.link_off,
                )
              : Column(
                  children: [
                    for (final b in rows)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.md),
                        child: AppCard(
                          borderColor: (b['idx'] as num).toInt() == _bad
                              ? AppColors.no
                              : null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  AppBadge(
                                    '#${b['idx']}',
                                    color: AppColors.arcane,
                                  ),
                                  const SizedBox(width: AppSpace.sm),
                                  Text(
                                    'hash ${_short(b['hash'] as String)}',
                                    style: AppText.caption,
                                  ),
                                ],
                              ),
                              const Gap(AppSpace.xs),
                              Text(
                                'prev ${_short(b['prev_hash'] as String)}',
                                style: AppText.caption,
                              ),
                              const Gap(AppSpace.xs),
                              Text(
                                b['data'] as String,
                                style: AppText.caption,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
