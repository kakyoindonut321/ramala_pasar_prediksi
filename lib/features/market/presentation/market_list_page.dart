import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ramala/core/error/app_error.dart';
import 'package:ramala/core/validators/validators.dart';
import 'package:ramala/features/market/domain/market.dart';
import 'package:ramala/features/market/presentation/market_providers.dart';
import 'package:ramala/template.dart';
import 'package:intl/intl.dart';
import 'package:ramala/features/notification/presentation/notification_page.dart';

class MarketListPage extends ConsumerStatefulWidget {
  const MarketListPage({super.key});
  @override
  ConsumerState<MarketListPage> createState() => _MarketListPageState();
}

class _MarketListPageState extends ConsumerState<MarketListPage> {
  String _q = '';
  bool? _open; // null = semua
  String? _cat;
  bool _showDone = false;

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
      actions: const [NotifBell()],
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

  Widget _buildList(List<Market> all) {
    final cats = ({...all.map((m) => m.category)}.toList()..sort());
    final filtered = all
        .where((m) => _cat == null || m.category == _cat)
        .toList();
    // Aktif: yang paling cepat tutup di atas. Selesai: yang terbaru di atas.
    final active = filtered.where((m) => m.isOpen).toList()
      ..sort((a, b) => a.closeAt.compareTo(b.closeAt));
    final done = filtered.where((m) => !m.isOpen).toList()
      ..sort((a, b) => b.closeAt.compareTo(a.closeAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (cats.isNotEmpty)
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (final c in cats)
                AppFilterChip(
                  label: c,
                  selected: _cat == c,
                  onTap: () => setState(() => _cat = _cat == c ? null : c),
                ),
            ],
          ),
        const Gap(AppSpace.lg),
        if (active.isEmpty && done.isEmpty)
          const EmptyState(
            title: 'Market tidak ditemukan',
            message: 'Coba kata kunci atau filter lain.',
            icon: Icons.search_off,
          )
        else ...[
          if (active.isEmpty)
            const EmptyState(
              title: 'Tidak ada market aktif',
              message: 'Market yang sudah selesai ada di bagian bawah.',
              icon: Icons.hourglass_empty,
            )
          else
            for (final m in active) _card(m),
          if (done.isNotEmpty) ...[
            const Gap(AppSpace.sm),
            AppButton(
              label: _showDone
                  ? 'Sembunyikan market selesai (${done.length})'
                  : 'Lihat market selesai (${done.length})',
              icon: _showDone ? Icons.expand_less : Icons.expand_more,
              variant: AppButtonVariant.ghost,
              onPressed: () => setState(() => _showDone = !_showDone),
            ),
            const Gap(AppSpace.md),
            if (_showDone)
              for (final m in done) _card(m),
          ],
        ],
      ],
    );
  }
}
