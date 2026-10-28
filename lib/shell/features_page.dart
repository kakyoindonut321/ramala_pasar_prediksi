import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ramala/features/converter/presentation/converter_section.dart';
import 'package:ramala/features/ledger/presentation/ledger_preview.dart';
import 'package:ramala/template.dart';

class _GameStats {
  const _GameStats(this.mine, this.top, this.topUser);
  final int? mine, top;
  final String? topUser;
}

/// Skor terbaik pengguna dan skor tertinggi global untuk kartu game.
final _gameProvider = FutureProvider.autoDispose<_GameStats>((ref) async {
  final c = Supabase.instance.client;
  final uid = c.auth.currentUser?.id;
  final top = await c
      .from('game_scores')
      .select('score,profiles(username)')
      .eq('game', 'tangkap_uang')
      .order('score', ascending: false)
      .limit(1);
  final List mine = uid == null
      ? const []
      : await c
            .from('game_scores')
            .select('score')
            .eq('game', 'tangkap_uang')
            .eq('user_id', uid)
            .order('score', ascending: false)
            .limit(1);
  return _GameStats(
    mine.isEmpty ? null : (mine.first['score'] as num).toInt(),
    top.isEmpty ? null : (top.first['score'] as num).toInt(),
    top.isEmpty
        ? null
        : (top.first['profiles'] as Map?)?['username'] as String?,
  );
}, retry: (_, __) => null);

class FeaturesPage extends ConsumerWidget {
  const FeaturesPage({super.key});

  Future<void> _safe(Future<Object?> f) async {
    try {
      await f;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Statistik game hanya tampil jika berhasil dimuat; tombol main tetap ada
    final stats = ref
        .watch(_gameProvider)
        .maybeWhen<List<(String, String)>>(
          data: (s) => [
            ('Skor terbaikmu', s.mine?.toString() ?? '-'),
            (
              s.topUser == null ? 'Skor teratas' : 'Teratas · ${s.topUser}',
              s.top?.toString() ?? '-',
            ),
          ],
          orElse: () => const [],
        );
    return AppScaffold(
      title: 'Fitur',
      // fabLocation: FloatingActionButtonLocation.startFloat,
      fab: AssistantFab(onTap: () => context.push('/chatbot')),
      onRefresh: () async {
        ref
          ..invalidate(ratesProvider)
          ..invalidate(_gameProvider)
          ..invalidate(ledgerPreviewProvider);
        await Future.wait([
          _safe(ref.read(ratesProvider.future)),
          _safe(ref.read(_gameProvider.future)),
          _safe(ref.read(ledgerPreviewProvider.future)),
        ]);
      },
      children: [
        const ConverterSection(),
        const Gap(AppSpace.lg),
        AppButton(
          label: 'Market terdekat',
          icon: Icons.near_me_outlined,
          variant: AppButtonVariant.secondary,
          onPressed: () => context.push('/nearby'),
        ),
        const Gap(AppSpace.lg),
        FeatureHeroCard(
          icon: Icons.sports_esports_outlined,
          title: 'Tangkap Uang',
          description: 'Gerakkan HP untuk menangkap uang yang jatuh. Dikendalikan langsung oleh sensor perangkat.',
          tags: const ['Akselerometer', 'Giroskop'],
          stats: stats,
          actionLabel: 'Main sekarang',
          onAction: () => context.push('/game'),
        ),
        const Gap(AppSpace.xl),
        const LedgerPreview(),
        // Ruang agar tombol Ramala AI tidak menutupi konten terbawah
        const Gap(AppSpace.xxl * 3),
      ],
    );
  }
}
