import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ramala/core/error/app_error.dart';
import 'package:ramala/core/validators/validators.dart';
import 'package:ramala/features/market/data/market_repository.dart';
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
  String? _cat; // null = tanpa filter kategori
  bool _done = false;
  String? _feed; // 'foryou' | 'trending' | null (dipilih lewat chip)
  bool _picked = false; // false = feed otomatis sesuai riwayat
  String _sort = 'trending'; // urutan dari modal: 'trending' | 'newest'
  int _limit = _step;
  List<Market>? _last; // agar daftar tidak berkedip saat "lebih banyak"

  /// Pengaturan modal non-default?
  bool get _customized => _done || _sort != 'trending';

  void _filter(VoidCallback f) => setState(() {
    f();
    _limit = _step;
    _last = null;
  });

  Future<void> _refresh(MarketQuery key) async {
    ref.invalidate(marketPageProvider(key));
    ref.invalidate(categoriesProvider);
    try {
      await ref.read(marketPageProvider(key).future);
    } catch (_) {}
  }

  void _openFilter() => AppBottomSheet.show<void>(
    context,
    title: 'Filter & urutkan',
    child: StatefulBuilder(
      builder: (ctx, setSheet) {
        void apply(VoidCallback f) {
          _filter(f);
          setSheet(() {});
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status', style: AppText.label),
            const Gap(AppSpace.sm),
            AppSegmented<bool>(
              options: [
                AppSegmentOption(false, 'Aktif'),
                AppSegmentOption(true, 'Selesai'),
              ],
              value: _done,
              onChanged: (v) => apply(() => _done = v),
            ),
            const Gap(AppSpace.lg),
            Text('Urutan', style: AppText.label),
            const Gap(AppSpace.sm),
            AppSegmented<String>(
              options: [
                AppSegmentOption('trending', 'Trending'),
                AppSegmentOption('newest', 'Terbaru'),
              ],
              value: _feed == null ? _sort : '',
              onChanged: (v) => apply(() {
                _sort = v;
                _feed = null; // urutan manual: lepas feed
                _picked = true;
              }),
            ),
            const Gap(AppSpace.sm),
            Text(
              'Berlaku untuk kategori atau tanpa chip terpilih.',
              style: AppText.caption,
            ),
            const Gap(AppSpace.xl),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Reset',
                    variant: AppButtonVariant.ghost,
                    onPressed: () => apply(() {
                      _done = false;
                      _sort = 'trending';
                    }),
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: AppButton(
                    label: 'Selesai',
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final hist = ref.watch(hasHistoryProvider);
    final cats = ref.watch(categoriesProvider).value ?? const <String>[];

    // Tunggu cek riwayat sekali agar feed awal tidak berganti setelah tampil
    if (!_picked && hist.isLoading) {
      return AppScaffold(
        title: 'Pasar',
        actions: const [NotifBell()],
        children: [
          for (var i = 0; i < 3; i++) ...[
            const AppSkeleton(height: 110),
            const Gap(AppSpace.md),
          ],
        ],
      );
    }

    final feed = _picked
        ? _feed
        : ((hist.value ?? false) ? 'foryou' : 'trending');
    final key = (
      text: _q,
      category: _cat,
      done: _done,
      sort: feed ?? _sort,
      limit: _limit,
    );
    final async = ref.watch(marketPageProvider(key));
    if (async.hasValue) _last = async.value;
    final items = _last;

    void pickFeed(String f) => _filter(() {
      _feed = f;
      _cat = null;
      _picked = true;
    });

    return AppScaffold(
      title: 'Pasar',
      actions: const [NotifBell()],
      onRefresh: () => _refresh(key),
      children: [
        Row(
          children: [
            Expanded(
              child: AppSearchBar(
                hint: 'Cari market...',
                onSearch: (s) => _filter(() => _q = Validators.searchTerm(s)),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            AppIconButton(
              icon: Icons.tune_rounded,
              badge: _customized,
              onTap: _openFilter,
            ),
          ],
        ),
        const Gap(AppSpace.md),
        AppChipRows(
          children: [
            AppFilterChip(
              label: 'Untuk kamu',
              selected: feed == 'foryou' && _cat == null,
              onTap: () => pickFeed('foryou'),
            ),
            AppFilterChip(
              label: 'Trending',
              selected: feed == 'trending' && _cat == null,
              onTap: () => pickFeed('trending'),
            ),
            for (final c in cats)
              AppFilterChip(
                label: c,
                selected: _cat == c,
                onTap: () => _filter(() {
                  _cat = _cat == c ? null : c;
                  _feed = null; // kategori memakai urutan dari modal
                  _picked = true;
                }),
              ),
          ],
        ),
        const Gap(AppSpace.lg),
        if (items == null)
          async.hasError
              ? ErrorState(
                  message: AppError.message(async.error!),
                  onRetry: () => ref.invalidate(marketPageProvider(key)),
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
          if (feed == 'foryou' && _cat == null && _q.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.md),
              child: Text(
                (hist.value ?? false)
                    ? 'Disusun dari market yang kamu trade dan lihat.'
                    : 'Trade atau lihat market dulu agar rekomendasi muncul.',
                style: AppText.caption,
              ),
            ),
          for (final m in items) _card(m),
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
