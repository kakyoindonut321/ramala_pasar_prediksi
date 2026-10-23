import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ramala/core/error/app_error.dart';
import 'package:ramala/core/validators/validators.dart';
import 'package:ramala/features/market/domain/market.dart';
import 'package:ramala/features/market/presentation/market_providers.dart';
import 'package:ramala/features/notification/presentation/notification_page.dart';
import 'package:ramala/template.dart';

class MarketListPage extends ConsumerStatefulWidget {
  const MarketListPage({super.key});
  @override
  ConsumerState<MarketListPage> createState() => _MarketListPageState();
}

class _MarketListPageState extends ConsumerState<MarketListPage> {
  static const _step = 30;
  String _q = '';
  String? _cat; // null = Semua
  bool _done = false;
  String _sort = 'trending';
  int _limit = _step;
  List<Market>?
  _last; // daftar terakhir, dipakai agar tidak berkedip saat "lebih banyak"

  get _key =>
      (text: _q, category: _cat, done: _done, sort: _sort, limit: _limit);

  /// Ubah filter: kembali ke halaman pertama
  void _filter(VoidCallback f) => setState(() {
    f();
    _limit = _step;
    _last = null;
  });

  Future<void> _refresh() async {
    ref.invalidate(marketPageProvider(_key));
    ref.invalidate(categoriesProvider);
    try {
      await ref.read(marketPageProvider(_key).future);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(marketPageProvider(_key));
    final cats = ref.watch(categoriesProvider).value ?? const <String>[];
    if (async.hasValue) _last = async.value;
    final items = _last;

    return AppScaffold(
      title: 'Pasar',
      actions: const [NotifBell()],
      onRefresh: _refresh,
      children: [
        AppSearchBar(
          hint: 'Cari market...',
          onSearch: (s) => _filter(() => _q = Validators.searchTerm(s)),
        ),
        const Gap(AppSpace.md),
        AppSegmented<bool>(
          options: [
            AppSegmentOption(false, 'Aktif'),
            AppSegmentOption(true, 'Selesai'),
          ],
          value: _done,
          onChanged: (v) => _filter(() => _done = v),
        ),
        const Gap(AppSpace.sm),
        AppSegmented<String>(
          options: [
            AppSegmentOption('trending', 'Trending'),
            AppSegmentOption('newest', 'Terbaru'),
          ],
          value: _sort,
          onChanged: (v) => _filter(() => _sort = v),
        ),
        const Gap(AppSpace.md),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            AppFilterChip(
              label: 'Semua',
              selected: _cat == null,
              onTap: () => _filter(() => _cat = null),
            ),
            for (final c in cats)
              AppFilterChip(
                label: c,
                selected: _cat == c,
                onTap: () => _filter(() => _cat = _cat == c ? null : c),
              ),
          ],
        ),
        const Gap(AppSpace.lg),
        if (items == null)
          async.hasError
              ? ErrorState(
                  message: AppError.message(async.error!),
                  onRetry: () => ref.invalidate(marketPageProvider(_key)),
                )
              : Column(
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      const AppSkeleton(height: 110),
                      const Gap(AppSpace.md),
                    ],
                  ],
                )
        else if (items.isEmpty)
          EmptyState(
            title: 'Market tidak ditemukan',
            message: _done
                ? 'Belum ada market yang selesai.'
                : 'Coba kata kunci atau filter lain.',
            icon: Icons.search_off,
          )
        else ...[
          for (final m in items) _card(m),
          // Jumlah == limit berarti kemungkinan masih ada sisanya
          if (items.length >= _limit)
            AppButton(
              label: 'Tampilkan lebih banyak pasar',
              icon: Icons.expand_more,
              variant: AppButtonVariant.ghost,
              expanded: true,
              loading: async.isLoading,
              onPressed: () => setState(() => _limit += _step),
            ),
        ],
      ],
    );
  }

  Widget _card(Market m) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.md),
    child: MarketCard(
      title: m.title,
      category: m.category,
      priceYes: m.priceYes,
      volume: m.volume,
      status: MarketStatus.from(m.status, m.closeAt),
      imageUrl: m.imageUrl,
      footer: m.isOpen
          ? 'Tutup ${DateFormat('d MMM y').format(m.closeAt.toLocal())}'
          : m.outcome != null
          ? 'Hasil: ${m.outcome!.toUpperCase()}'
          : 'Ditutup ${DateFormat('d MMM y').format(m.closeAt.toLocal())}',
      onTap: () => context.push('/market/${m.id}'),
    ),
  );
}
