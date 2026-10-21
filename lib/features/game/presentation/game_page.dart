import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ramala/core/error/app_error.dart';
import 'package:ramala/template.dart';

enum _Dir { kiri, kanan, maju, mundur, putar }

const _label = {
  _Dir.kiri: 'MIRING KIRI',
  _Dir.kanan: 'MIRING KANAN',
  _Dir.maju: 'MIRING KE DEPAN',
  _Dir.mundur: 'MIRING KE BELAKANG',
  _Dir.putar: 'PUTAR CEPAT',
};
const _icon = {
  _Dir.kiri: Icons.arrow_back,
  _Dir.kanan: Icons.arrow_forward,
  _Dir.maju: Icons.arrow_upward,
  _Dir.mundur: Icons.arrow_downward,
  _Dir.putar: Icons.rotate_right,
};

const _rounds = 10;
const _roundMs = 3000;

final _boardProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) async => List<Map<String, dynamic>>.from(
    await Supabase.instance.client
        .from('game_scores')
        .select('score,profiles(username)')
        .eq('game', 'tebak_arah')
        .order('score', ascending: false)
        .limit(10),
  ),
  retry: (_, __) => null,
);

class GamePage extends ConsumerStatefulWidget {
  const GamePage({super.key});
  @override
  ConsumerState<GamePage> createState() => _GamePageState();
}

class _GamePageState extends ConsumerState<GamePage> {
  final _rnd = Random();
  final _subs = <StreamSubscription>[];
  Timer? _timer;
  bool _playing = false, _done = false;
  int _round = 0, _score = 0;
  _Dir? _target;
  DateTime _start = DateTime.now();

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  void _stop() {
    _timer?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
  }

  void _begin() {
    _round = 0;
    _score = 0;
    _target = null;
    _done = false;
    _playing = true;
    // Accelerometer: kemiringan. Gyroscope: putaran cepat.
    _subs
      ..add(
        accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)
            .listen(_onAccel),
      )
      ..add(
        gyroscopeEventStream(samplingPeriod: SensorInterval.gameInterval)
            .listen(_onGyro),
      );
    _advance();
  }

  void _advance() {
    _timer?.cancel();
    if (_round >= _rounds) {
      _finish();
      return;
    }
    _round++;
    _Dir next;
    do {
      next = _Dir.values[_rnd.nextInt(_Dir.values.length)];
    } while (next == _target);
    setState(() => _target = next);
    _start = DateTime.now();
    _timer = Timer(const Duration(milliseconds: _roundMs), _advance);
  }

  // Ponsel dipegang mendatar. Jika arah terbalik di perangkat Anda, tukar tanda di sini.
  void _onAccel(AccelerometerEvent e) {
    if (e.x > 5) {
      _try(_Dir.kiri);
    } else if (e.x < -5) {
      _try(_Dir.kanan);
    } else if (e.y < -5) {
      _try(_Dir.maju);
    } else if (e.y > 5) {
      _try(_Dir.mundur);
    }
  }

  void _onGyro(GyroscopeEvent e) {
    if (e.z.abs() > 5) _try(_Dir.putar);
  }

  void _try(_Dir d) {
    if (!_playing || d != _target) return;
    final ms = DateTime.now().difference(_start).inMilliseconds;
    if (ms < 400) return; // hindari sisa gerakan ronde sebelumnya
    _score += 100 + (_roundMs - ms) ~/ 10; // bonus kecepatan
    _advance();
  }

  Future<void> _finish() async {
    _stop();
    setState(() {
      _playing = false;
      _done = true;
    });
    try {
      await Supabase.instance.client.from('game_scores').insert({
        'game': 'tebak_arah',
        'score': _score,
      });
      ref.invalidate(_boardProvider);
    } catch (e) {
      if (mounted)
        AppToast.show(context, AppError.message(e), type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final board = ref.watch(_boardProvider);
    return AppScaffold(
      title: 'Tebak Arah',
      children: [
        if (_playing && _target != null)
          AppCard(
            glow: true,
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  Text(
                    'Ronde $_round/$_rounds · Skor $_score',
                    style: AppText.bodyDim,
                  ),
                  const Gap(AppSpace.lg),
                  Icon(_icon[_target]!, size: 96, color: AppColors.primary),
                  const Gap(AppSpace.md),
                  Text(_label[_target]!, style: AppText.heading),
                ],
              ),
            ),
          )
        else
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_done) ...[
                  Text('Skor akhir: $_score', style: AppText.number),
                  const Gap(AppSpace.sm),
                ],
                Text(
                  'Pegang ponsel mendatar (layar menghadap atas). Ikuti perintah: miringkan ke arah yang diminta '
                  '(accelerometer) atau putar ponsel dengan cepat (gyroscope). 3 detik per ronde, $_rounds ronde.',
                  style: AppText.bodyDim,
                ),
                const Gap(AppSpace.lg),
                AppButton(
                  label: _done ? 'Main lagi' : 'Mulai',
                  onPressed: () => setState(_begin),
                ),
              ],
            ),
          ),
        const Gap(AppSpace.xl),
        const SectionHeader('Papan skor'),
        board.when(
          loading: () => const AppSkeleton(height: 120),
          error: (e, _) => ErrorState(
            message: AppError.message(e),
            onRetry: () => ref.invalidate(_boardProvider),
          ),
          data: (rows) => rows.isEmpty
              ? const EmptyState(
                  title: 'Belum ada skor',
                  message: 'Jadilah yang pertama.',
                  icon: Icons.emoji_events_outlined,
                )
              : AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < rows.length; i++) ...[
                        if (i > 0) const Divider(),
                        AppListTile(
                          icon: Icons.emoji_events_outlined,
                          title:
                              '${i + 1}. ${(rows[i]['profiles'] as Map?)?['username'] ?? '-'}',
                          subtitle: '${rows[i]['score']} poin',
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
