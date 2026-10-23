import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramala/core/error/app_error.dart';
import 'package:ramala/template.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _gameDuration = Duration(seconds: 45);
const _fieldHeight = 360.0;
const _moneyHeight = 36.0;
const _basketWidth = 88.0;

class _MoneyDrop {
  _MoneyDrop({required this.x, required this.speed, required this.value});

  final double x;
  final double speed;
  final int value;
  double y = 0;
}

final _boardProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) async => List<Map<String, dynamic>>.from(
    await Supabase.instance.client
        .from('game_scores')
        .select('score,profiles(username)')
        .eq('game', 'tangkap_uang')
        .order('score', ascending: false)
        .limit(10),
  ),
  retry: (_, _) => null,
);

class GamePage extends ConsumerStatefulWidget {
  const GamePage({super.key});

  @override
  ConsumerState<GamePage> createState() => _GamePageState();
}

class _GamePageState extends ConsumerState<GamePage> {
  final _random = Random();
  final _subscriptions = <StreamSubscription>[];
  final _money = <_MoneyDrop>[];
  Timer? _gameTimer;
  bool _playing = false;
  bool _done = false;
  int _score = 0;
  int _secondsLeft = _gameDuration.inSeconds;
  double _basketX = 0.5;
  double _targetBasketX = 0.5;
  double _tiltAngle = 0;
  double _accelerometerAngle = 0;
  double _spawnElapsed = 0;
  DateTime _gameStartedAt = DateTime.now();
  DateTime _lastTick = DateTime.now();
  DateTime _lastGyroscopeEvent = DateTime.now();
  String? _sensorError;
  double _fieldWidth = 0;

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  void _stop() {
    _gameTimer?.cancel();
    _gameTimer = null;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
  }

  void _begin() {
    _stop();
    setState(() {
      _playing = true;
      _done = false;
      _score = 0;
      _secondsLeft = _gameDuration.inSeconds;
      _basketX = 0.5;
      _targetBasketX = 0.5;
      _tiltAngle = 0;
      _accelerometerAngle = 0;
      _spawnElapsed = 0;
      _money.clear();
      _sensorError = null;
      _gameStartedAt = DateTime.now();
      _lastTick = _gameStartedAt;
      _lastGyroscopeEvent = _gameStartedAt;
    });

    _subscriptions
      ..add(
        accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)
            .listen(
              _onAccelerometer,
              onError: (Object error) => _handleSensorError(error),
            ),
      )
      ..add(
        gyroscopeEventStream(samplingPeriod: SensorInterval.gameInterval)
            .listen(
              _onGyroscope,
              onError: (Object error) => _handleSensorError(error),
            ),
      );

    _gameTimer = Timer.periodic(
      const Duration(milliseconds: 30),
      (_) => _tick(),
    );
  }

  void _onAccelerometer(AccelerometerEvent event) {
    if (!_playing) return;
    _accelerometerAngle = atan2(event.x, event.z);
  }

  void _onGyroscope(GyroscopeEvent event) {
    if (!_playing) return;
    final now = DateTime.now();
    final elapsed =
        now.difference(_lastGyroscopeEvent).inMicroseconds /
        Duration.microsecondsPerSecond;
    _lastGyroscopeEvent = now;

    final delta = elapsed.clamp(0.0, 0.1);
    _tiltAngle =
        (0.98 * (_tiltAngle + event.y * delta) + 0.02 * _accelerometerAngle)
            .clamp(-0.75, 0.75);
    final basketMargin = _fieldWidth > _basketWidth
        ? _basketWidth / (2 * _fieldWidth) + 0.02
        : 0.15;
    _targetBasketX = (0.5 - (_tiltAngle / 0.75) * 0.44)
        .clamp(basketMargin, 1 - basketMargin)
        .toDouble();
  }

  void _handleSensorError(Object error) {
    if (!mounted || !_playing) return;
    _stop();
    setState(() {
      _playing = false;
      _sensorError = 'Sensor gerak tidak tersedia: $error';
    });
  }

  void _tick() {
    if (!_playing || _fieldWidth <= 0) return;
    final now = DateTime.now();
    final elapsed =
        now.difference(_lastTick).inMicroseconds /
        Duration.microsecondsPerSecond;
    _lastTick = now;

    final gameElapsed = now.difference(_gameStartedAt);
    if (gameElapsed >= _gameDuration) {
      unawaited(_finish());
      return;
    }

    _spawnElapsed += elapsed;
    if (_spawnElapsed >= 0.72) {
      _spawnElapsed -= 0.72;
      _money.add(
        _MoneyDrop(
          x: 0.1 + _random.nextDouble() * 0.8,
          speed: 125 + _random.nextDouble() * 90,
          value: const [10, 20, 50][_random.nextInt(3)],
        ),
      );
    }

    _basketX += (_targetBasketX - _basketX) * 0.16;
    var collected = 0;
    final basketTop = _fieldHeight - 72;
    _money.removeWhere((drop) {
      drop.y += drop.speed * elapsed;
      final horizontalDistance = (drop.x * _fieldWidth - _basketX * _fieldWidth)
          .abs();
      final caught =
          drop.y + _moneyHeight >= basketTop &&
          drop.y <= basketTop + 28 &&
          horizontalDistance <= _basketWidth / 2 + 28;
      if (caught) {
        collected += drop.value;
        return true;
      }
      return drop.y > _fieldHeight;
    });

    setState(() {
      _score += collected;
      _secondsLeft = (_gameDuration.inSeconds - gameElapsed.inSeconds).clamp(
        0,
        45,
      );
    });
  }

  Future<void> _finish() async {
    if (!_playing) return;
    _stop();
    setState(() {
      _playing = false;
      _done = true;
      _secondsLeft = 0;
    });
    try {
      await Supabase.instance.client.from('game_scores').insert({
        'game': 'tangkap_uang',
        'score': _score,
      });
      ref.invalidate(_boardProvider);
    } catch (error) {
      if (mounted) {
        AppToast.show(context, AppError.message(error), type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final board = ref.watch(_boardProvider);

    return AppScaffold(
      title: 'Tangkap Uang',
      children: [
        if (_playing)
          AppCard(
            glow: true,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _GameStat(label: 'SKOR', value: '$_score'),
                    _GameStat(label: 'WAKTU', value: '$_secondsLeft dtk'),
                  ],
                ),
                const Gap(AppSpace.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    _fieldWidth = constraints.maxWidth;
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: SizedBox(
                        width: double.infinity,
                        height: _fieldHeight,
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF251339), Color(0xFF120D1B)],
                            ),
                          ),
                          child: Stack(
                            children: [
                              for (final drop in _money)
                                Positioned(
                                  left: drop.x * _fieldWidth - 31,
                                  top: drop.y,
                                  child: Container(
                                    width: 62,
                                    height: _moneyHeight,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3A2B1A),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.accent.withValues(
                                          alpha: 0.8,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      'Rp${drop.value}',
                                      style: AppText.caption.copyWith(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned(
                                left: _basketX * _fieldWidth - _basketWidth / 2,
                                bottom: 10,
                                child: Container(
                                  width: _basketWidth,
                                  height: 54,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.16,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.shopping_basket_rounded,
                                    color: AppColors.primary,
                                    size: 34,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: AppSpace.sm,
                                left: AppSpace.sm,
                                child: Text(
                                  'Miringkan ponsel ke kiri / kanan',
                                  style: AppText.caption,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const Gap(AppSpace.sm),
                Text(
                  'Kumpulkan uang sebanyak mungkin sebelum waktu habis.',
                  style: AppText.caption,
                  textAlign: TextAlign.center,
                ),
              ],
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
                if (_sensorError != null) ...[
                  Text(
                    _sensorError!,
                    style: AppText.body.copyWith(color: AppColors.no),
                  ),
                  const Gap(AppSpace.sm),
                ],
                Text(
                  'Tangkap uang yang jatuh dengan menggerakkan keranjang. Pegang ponsel mendatar dengan layar menghadap ke atas, lalu miringkan ke kiri atau kanan. Accelerometer membaca kemiringan dan gyroscope membantu menjaga gerakan tetap halus. Kumpulkan uang selama 45 detik.',
                  style: AppText.bodyDim,
                ),
                const Gap(AppSpace.lg),
                AppButton(
                  label: _done ? 'Main lagi' : 'Mulai',
                  icon: Icons.play_arrow_rounded,
                  onPressed: _begin,
                ),
              ],
            ),
          ),
        const Gap(AppSpace.xl),
        const SectionHeader('Papan skor'),
        board.when(
          loading: () => const AppSkeleton(height: 120),
          error: (error, _) => ErrorState(
            message: AppError.message(error),
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

class _GameStat extends StatelessWidget {
  const _GameStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppText.caption),
      Text(value, style: AppText.numberSm),
    ],
  );
}
