import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ramala/core/error/app_error.dart';
import 'package:ramala/core/validators/validators.dart';
import 'package:ramala/features/market/domain/market.dart';
import 'package:ramala/features/market/presentation/market_providers.dart';
import 'package:ramala/template.dart';
import 'package:intl/intl.dart';

class MarketListPage extends ConsumerStatefulWidget {
  const MarketListPage({super.key});
  @override
  ConsumerState<MarketListPage> createState() => _MarketListPageState();
}

class _MarketListPageState extends ConsumerState<MarketListPage> {
  String _q = '';
  bool? _open; // null = semua
  String? _cat;

  Future<void> _refresh() async {
    ref.invalidate(marketListProvider(_q));
    try {
      await ref.read(marketListProvider(_q).future);
    } catch (_) {} // error tampil lewat state provider
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(marketListProvider(_q));
    return AppScaffold(
      title: 'Pasar',
      onRefresh: _refresh,
      children: [
        AppSearchBar(
          hint: 'Cari market...',
          onSearch: (s) => setState(() => _q = Validators.searchTerm(s)),
        ),
        const Gap(AppSpace.md),
        async.when(
          loading: () => Column(
            children: [
              for (var i = 0; i < 3; i++) ...[
                const AppSkeleton(height: 110),
                const Gap(AppSpace.md),
              ],
            ],
          ),
          error: (e, _) => ErrorState(
            message: AppError.message(e),
            onRetry: () => ref.invalidate(marketListProvider(_q)),
          ),
          data: _buildList,
        ),
      ],
    );
  }

  Widget _buildList(List<Market> all) {
    final cats = ({...all.map((m) => m.category)}.toList()..sort());
    final shown = all
        .where(
          (m) =>
              (_open == null || _open == m.isOpen) &&
              (_cat == null || m.category == _cat),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            AppFilterChip(
              label: 'Semua',
              selected: _open == null,
              onTap: () => setState(() => _open = null),
            ),
            AppFilterChip(
              label: 'Terbuka',
              selected: _open == true,
              onTap: () => setState(() => _open = true),
            ),
            AppFilterChip(
              label: 'Ditutup',
              selected: _open == false,
              onTap: () => setState(() => _open = false),
            ),
            for (final c in cats)
              AppFilterChip(
                label: c,
                selected: _cat == c,
                onTap: () => setState(() => _cat = _cat == c ? null : c),
              ),
          ],
        ),
        const Gap(AppSpace.lg),
        if (shown.isEmpty)
          const EmptyState(
            title: 'Market tidak ditemukan',
            message: 'Coba kata kunci atau filter lain.',
            icon: Icons.search_off,
          )
        else
          for (final m in shown)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.md),
              child: MarketCard(
                title: m.title,
                category: m.category,
                priceYes: m.priceYes,
                volume: m.volume,
                status: MarketStatus.from(m.status, m.closeAt),
                imageUrl: m.imageUrl,
                footer:
                    'Tutup ${DateFormat('d MMM y').format(m.closeAt.toLocal())}',
                onTap: () => context.push('/market/${m.id}'),
              ),
            ),
      ],
    );
  }
}
