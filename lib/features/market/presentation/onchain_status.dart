import 'package:flutter/material.dart';
import 'package:ramala/template.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ramala/features/market/data/onchain_service.dart';

/// Badge bukti on-chain. [onRetry] hanya diisi untuk admin.
class OnchainStatus extends StatelessWidget {
  const OnchainStatus({
    super.key,
    required this.status,
    required this.tx,
    this.onRetry,
  });

  final String? status; // pending | confirmed | failed | null
  final String? tx;
  final VoidCallback? onRetry;

  String _short(String t) =>
      '${t.substring(0, 10)}…${t.substring(t.length - 6)}';

  @override
  Widget build(BuildContext context) {
    if (status == null) return const SizedBox.shrink();

    final (label, color) = switch (status) {
      'confirmed' => ('Tercatat on-chain', AppColors.arcane),
      'failed' => ('Pencatatan gagal', AppColors.no),
      _ => ('Menunggu pencatatan', AppColors.textMuted),
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppBadge(label, color: color),
          if (tx != null) ...[
            const Gap(AppSpace.sm),
            Text('Tx ${_short(tx!)}', style: AppText.caption),
          ],
          if (status == 'confirmed' && tx != null) ...[
            const Gap(AppSpace.sm),
            AppButton(
              label: 'Lihat di explorer',
              variant: AppButtonVariant.secondary,
              icon: Icons.open_in_new,
              onPressed: () => launchUrl(
                Uri.parse('${OnchainService.explorerTx}$tx'),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ],
          if (status != 'confirmed' && onRetry != null) ...[
            const Gap(AppSpace.sm),
            AppButton(
              label: 'Coba lagi',
              variant: AppButtonVariant.ghost,
              icon: Icons.refresh,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}
