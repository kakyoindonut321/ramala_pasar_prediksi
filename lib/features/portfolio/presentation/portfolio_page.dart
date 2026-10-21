import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ramala/core/error/app_error.dart';
import 'package:ramala/features/portfolio/data/portfolio_repository.dart';
import 'package:ramala/features/portfolio/presentation/portfolio_providers.dart';
import 'package:ramala/features/profile/presentation/profile_providers.dart';
import 'package:ramala/template.dart';

String _signed(double v) => '${v >= 0 ? '+' : ''}${Fmt.coin(v)}';
Color _pnlColor(double v) => v >= 0 ? AppColors.yes : AppColors.no;

class PortfolioPage extends ConsumerWidget {
  const PortfolioPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final positions = ref.watch(portfolioProvider);
    final trades = ref.watch(tradesProvider);
    final balance = ref.watch(balanceProvider);

    return AppScaffold(
      title: 'Portofolio',
      onRefresh: () async {
        ref.invalidate(portfolioProvider);
        ref.invalidate(tradesProvider);
        ref.invalidate(balanceProvider);
        try {
          await ref.read(portfolioProvider.future);
        } catch (_) {}
      },
      children: [
        positions.when(
          loading: () => const AppSkeleton(height: 220),
          error: (e, _) => ErrorState(
            message: AppError.message(e),
            onRetry: () => ref.invalidate(portfolioProvider),
          ),
          data: (all) {
            final active = all.where((p) => p.shares > 0).toList();
            final pnl = all.fold(
              0.0,
              (a, p) => a + p.realizedPnl + p.unrealized,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        label: 'Saldo',
                        value: balance.value == null
                            ? '-'
                            : Fmt.coin(balance.value!),
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: StatTile(
                        label: 'Total PnL',
                        value: _signed(pnl),
                        icon: Icons.trending_up,
                      ),
                    ),
                  ],
                ),
                const Gap(AppSpace.lg),
                const SectionHeader('Posisi aktif'),
                if (active.isEmpty)
                  EmptyState(
                    title: 'Belum ada posisi',
                    message: 'Beli share pertama Anda di tab Pasar.',
                    icon: Icons.show_chart,
                    actionLabel: 'Lihat Pasar',
                    onAction: () => context.go('/pasar'),
                  )
                else
                  for (final p in active) _PositionCard(p),
              ],
            );
          },
        ),
        const Gap(AppSpace.lg),
        const SectionHeader('Riwayat transaksi'),
        trades.when(
          loading: () => const AppSkeleton(height: 120),
          error: (e, _) => ErrorState(
            message: AppError.message(e),
            onRetry: () => ref.invalidate(tradesProvider),
          ),
          data: (list) => list.isEmpty
              ? const EmptyState(
                  title: 'Belum ada transaksi',
                  message: 'Transaksi Anda akan muncul di sini.',
                  icon: Icons.receipt_long,
                )
              : AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < list.length; i++) ...[
                        if (i > 0) const Divider(),
                        _tradeTile(context, list[i]),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _tradeTile(BuildContext context, TradeRecord t) {
    final label = switch (t.action) {
      'buy' => 'Beli',
      'sell' => 'Jual',
      _ => 'Payout',
    };
    final icon = switch (t.action) {
      'buy' => Icons.add_circle_outline,
      'sell' => Icons.remove_circle_outline,
      _ => Icons.emoji_events_outlined,
    };
    return AppListTile(
      icon: icon,
      title:
          '$label ${t.side.toUpperCase()} · ${t.shares} share · ${Fmt.coin(t.amount)}',
      subtitle:
          '${t.title} · ${DateFormat('d MMM HH:mm').format(t.createdAt.toLocal())}',
      onTap: () => context.push('/market/${t.marketId}'),
    );
  }
}

class _PositionCard extends StatelessWidget {
  const _PositionCard(this.p);
  final PortfolioPosition p;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: AppCard(
        onTap: () => context.push('/market/${p.market.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              p.market.title,
              style: AppText.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Gap(AppSpace.sm),
            Row(
              children: [
                AppBadge(
                  p.side.toUpperCase(),
                  color: p.side == 'yes' ? AppColors.yes : AppColors.no,
                ),
                const SizedBox(width: AppSpace.sm),
                Text('${p.shares} share', style: AppText.bodyDim),
                const Spacer(),
                Text(
                  _signed(p.unrealized),
                  style: AppText.numberSm.copyWith(
                    color: _pnlColor(p.unrealized),
                  ),
                ),
              ],
            ),
            const Gap(AppSpace.xs),
            Text(
              'Nilai ${Fmt.coin(p.value)} · Modal ${Fmt.coin(p.cost)}',
              style: AppText.caption,
            ),
          ],
        ),
      ),
    );
  }
}
