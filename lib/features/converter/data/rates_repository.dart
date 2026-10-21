import 'package:dio/dio.dart';
import 'package:ramala/core/storage/local_db.dart';

/// Kurs dari API publik; cache sqflite dengan TTL supaya tidak memanggil API berulang.
class RatesRepository {
  static final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  static const fiatCodes = ['USD', 'IDR', 'EUR', 'JPY', 'SGD'];
  static const coins = {'bitcoin': 'BTC', 'ethereum': 'ETH', 'solana': 'SOL'};

  /// Kurs per 1 USD
  Future<Map<String, double>> fiat() =>
      _cached('rates:fiat', const Duration(hours: 1), () async {
        final r = await _dio.get('https://open.er-api.com/v6/latest/USD');
        final m = r.data['rates'] as Map;
        return {for (final k in fiatCodes) k: (m[k] as num).toDouble()};
      });

  /// Kunci: `bitcoin_usd`, `bitcoin_idr`, dst.
  Future<Map<String, double>> crypto() =>
      _cached('rates:crypto', const Duration(minutes: 2), () async {
        final r = await _dio.get(
          'https://api.coingecko.com/api/v3/simple/price',
          queryParameters: {
            'ids': coins.keys.join(','),
            'vs_currencies': 'usd,idr',
          },
        );
        final m = r.data as Map;
        return {
          for (final id in coins.keys)
            for (final cur in ['usd', 'idr'])
              '${id}_$cur': ((m[id] as Map)[cur] as num).toDouble(),
        };
      });

  Future<Map<String, double>> _cached(
    String key,
    Duration ttl,
    Future<Map<String, double>> Function() fetch,
  ) async {
    final c = await LocalDb.getCache(key);
    final old = c is Map
        ? (c['d'] as Map).map(
            (k, v) => MapEntry(k as String, (v as num).toDouble()),
          )
        : null;
    final ts = c is Map ? c['ts'] as int : 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (old != null && now - ts < ttl.inMilliseconds) return old;
    try {
      final d = await fetch();
      await LocalDb.putCache(key, {'ts': now, 'd': d});
      return d;
    } catch (_) {
      if (old != null) return old; // offline: pakai cache lama
      rethrow;
    }
  }
}
