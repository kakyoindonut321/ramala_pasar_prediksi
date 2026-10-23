import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ramala/core/error/app_error.dart';
import 'package:ramala/features/market/domain/market.dart';
import 'package:ramala/features/market/presentation/market_providers.dart';
import 'package:ramala/features/market/presentation/trade_sheet.dart';
import 'package:ramala/features/portfolio/presentation/portfolio_providers.dart';
import 'package:ramala/template.dart';

class MarketDetailPage extends ConsumerWidget {
  const MarketDetailPage(this.id, {super.key});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final market = ref.watch(marketProvider(id));
    return AppScaffold(
      title: 'Detail Market',
      onRefresh: () async {
        ref.invalidate(marketProvider(id));
        ref.invalidate(priceHistoryProvider(id));
        ref.invalidate(portfolioProvider);
        try {
          await ref.read(marketProvider(id).future);
        } catch (_) {}
      },
      children: [
        market.when(
          loading: () => const AppSkeleton(height: 260),
          error: (e, _) => ErrorState(
            message: AppError.message(e),
            onRetry: () => ref.invalidate(marketProvider(id)),
          ),
          data: (m) => _Body(m),
        ),
      ],
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body(this.m);
  final Market m;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hist = ref.watch(priceHistoryProvider(m.id));
    final mine = (ref.watch(portfolioProvider).value ?? [])
        .where((p) => p.market.id == m.id && p.shares > 0)
        .toList();
    double held(String side) =>
        mine.where((p) => p.side == side).fold(0.0, (a, p) => a + p.shares);
    final status = MarketStatus.from(m.status, m.closeAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (m.imageUrl != null) ...[_Cover(m.imageUrl), const Gap(AppSpace.md)],
        Wrap(
          spacing: AppSpace.sm,
          children: [
            AppBadge(m.category),
            AppBadge(status.label, color: status.color),
            if (m.outcome != null)
              AppBadge(
                'Hasil: ${m.outcome!.toUpperCase()}',
                color: AppColors.accent,
              ),
          ],
        ),
        const Gap(AppSpace.sm),
        Text(m.title, style: AppText.heading),
        const Gap(AppSpace.lg),
        AppCard(
          glow: true,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'YES ${Fmt.pct(m.priceYes)}',
                    style: AppText.number.copyWith(color: AppColors.yes),
                  ),
                  Text(
                    'NO ${Fmt.pct(1 - m.priceYes)}',
                    style: AppText.number.copyWith(color: AppColors.no),
                  ),
                ],
              ),
              const Gap(AppSpace.sm),
              ProbabilityBar(yes: m.priceYes),
              const Gap(AppSpace.lg),
              hist.when(
                loading: () => const AppSkeleton(height: 140),
                error: (_, __) =>
                    Text('Grafik gagal dimuat', style: AppText.bodyDim),
                data: (d) => d.length >= 2
                    ? PriceChart(data: d, height: 140)
                    : Text('Belum ada riwayat harga', style: AppText.bodyDim),
              ),
            ],
          ),
        ),
        const Gap(AppSpace.md),
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'Volume',
                value: Fmt.coin(m.volume),
                icon: Icons.bar_chart,
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: StatTile(
                label: 'Tutup',
                value: DateFormat('d MMM y HH:mm').format(m.closeAt.toLocal()),
                icon: Icons.schedule,
              ),
            ),
          ],
        ),
        if (m.description != null) ...[
          const Gap(AppSpace.lg),
          Text(m.description!, style: AppText.body),
        ],
        if (mine.isNotEmpty) ...[
          const Gap(AppSpace.lg),
          const SectionHeader('Posisi Anda'),
          AppCard(
            child: Column(
              children: [
                for (final p in mine)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppBadge(
                        p.side.toUpperCase(),
                        color: p.side == 'yes' ? AppColors.yes : AppColors.no,
                      ),
                      Text('${p.shares} share', style: AppText.body),
                      Text(
                        'Nilai ${Fmt.coin(p.value)}',
                        style: AppText.bodyDim,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
        const Gap(AppSpace.xl),
        AppButton(
          label: m.isOpen ? 'Perdagangkan' : 'Market ditutup',
          onPressed: m.isOpen
              ? () => AppBottomSheet.show<void>(
                  context,
                  title: 'Perdagangkan',
                  child: TradeSheet(
                    market: m,
                    heldYes: held('yes'),
                    heldNo: held('no'),
                  ),
                )
              : null,
        ),
      ],
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover(this.url);
  final String? url;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      height: 180,
      width: double.infinity,
      color: AppColors.card,
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.textMuted,
        size: 40,
      ),
    );
    final u = url?.trim() ?? '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: u.isEmpty
          ? placeholder
          : CachedNetworkImage(
              imageUrl: u,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) => placeholder,
              errorWidget: (_, __, ___) => placeholder,
            ),
    );
  }
}
