import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ramala/core/error/app_error.dart';
import 'package:ramala/features/market/data/onchain_service.dart';
import 'package:ramala/template.dart';

/// Hanya 5 blok terbaru (halaman Ledger penuh memuat 50).
final ledgerPreviewProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
      (ref) async => List<Map<String, dynamic>>.from(
        await Supabase.instance.client
            .from('ledger')
            .select('idx,hash,data')
            .order('idx', ascending: false)
            .limit(5),
      ),
      retry: (_, __) => null,
    );

const _types = {
  'trade': 'Transaksi',
  'payout': 'Payout',
  'resolve': 'Resolusi',
  'onchain': 'On-chain',
};

class LedgerPreview extends ConsumerWidget {
  const LedgerPreview({super.key});

  /// tx_hash dari blok 'onchain|<market>|<tx>', atau null jika bukan blok itu
  String? _tx(String data) {
    final p = data.split('|');
    return p.length == 3 && p[0] == 'onchain' ? p[2] : null;
  }

  String _short(String h) => h.length > 12 ? '${h.substring(0, 12)}…' : h;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Ledger blockchain',
          action: 'Lihat semua',
          onAction: () => context.push('/ledger'),
        ),
        ref
            .watch(ledgerPreviewProvider)
            .when(
              loading: () => const AppSkeleton(height: 160),
              error: (e, _) => ErrorState(
                message: AppError.message(e),
                onRetry: () => ref.invalidate(ledgerPreviewProvider),
              ),
              data: (rows) => rows.isEmpty
                  ? const EmptyState(
                      title: 'Ledger kosong',
                      message: 'Blok pertama dibuat saat ada transaksi.',
                      icon: Icons.link_off,
                    )
                  : AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (var i = 0; i < rows.length; i++) ...[
                            if (i > 0) const Divider(),
                            _row(context, rows[i]),
                          ],
                        ],
                      ),
                    ),
            ),
      ],
    );
  }

  Widget _row(BuildContext context, Map<String, dynamic> b) {
    final data = b['data'] as String;
    final type = data.split('|').first;
    final tx = _tx(data);
    return AppListTile(
      icon: tx == null ? Icons.link : Icons.public,
      title: '#${b['idx']} · ${_types[type] ?? type}',
      subtitle: 'hash ${_short(b['hash'] as String)}',
      trailing: tx == null
          ? null
          : const AppBadge('on-chain', color: AppColors.accent),
      onTap: tx == null
          ? () => context.push('/ledger')
          : () => launchUrl(
              Uri.parse('${OnchainService.explorerTx}$tx'),
              mode: LaunchMode.externalApplication,
            ),
    );
  }
}
