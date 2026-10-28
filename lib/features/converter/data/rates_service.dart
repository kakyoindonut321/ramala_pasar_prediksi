import 'package:dio/dio.dart';
import 'package:ramala/core/storage/local_db.dart';

/// Aset yang bisa dipilih di konverter. `cgId` terisi = kripto (CoinGecko).
class RateAsset {
  const RateAsset(this.code, this.name, {this.cgId});
  final String code, name;
  final String? cgId;
  bool get crypto => cgId != null;
}

const kRateAssets = [
  RateAsset('KOIN', 'Koin Ramala'),
  RateAsset('USD', 'Dolar AS'),
  RateAsset('IDR', 'Rupiah'),
  RateAsset('EUR', 'Euro'),
  RateAsset('GBP', 'Poundsterling'),
  RateAsset('JPY', 'Yen Jepang'),
  RateAsset('SGD', 'Dolar Singapura'),
  RateAsset('MYR', 'Ringgit Malaysia'),
  RateAsset('AUD', 'Dolar Australia'),
  RateAsset('CNY', 'Yuan Tiongkok'),
  RateAsset('SAR', 'Riyal Saudi'),
  RateAsset('BTC', 'Bitcoin', cgId: 'bitcoin'),
  RateAsset('ETH', 'Ethereum', cgId: 'ethereum'),
  RateAsset('SOL', 'Solana', cgId: 'solana'),
  RateAsset('USDC', 'USD Coin', cgId: 'usd-coin'),
];

/// Nilai tiap aset dalam USD (pivot). Semua konversi lewat satu rumus.
class Rates {
  const Rates(this.usdPer, this.hasCrypto);
  final Map<String, double> usdPer; // 1 unit aset = x USD
  final bool hasCrypto;

  double? convert(double amount, String from, String to) {
    final a = usdPer[from], b = usdPer[to];
    if (a == null || b == null || b == 0) return null;
    return amount * a / b;
  }

  /// Nilai 1 unit aset dalam rupiah.
  double? idr(String code) {
    final u = usdPer[code], i = usdPer['IDR'];
    return (u == null || i == null || i == 0) ? null : u / i;
  }
}

class RatesService {
  static final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  static final _lastTry = <String, int>{};

  /// Fiat wajib; kripto opsional (jika gagal, fiat tetap bisa dipakai).
  static Future<Rates> load() async {
    final fiat = await _cached(
      'rates:fiat2',
      const Duration(hours: 1),
      _fetchFiat,
    );
    var crypto = <String, double>{};
    try {
      crypto = await _cached(
        'rates:crypto2',
        const Duration(minutes: 2),
        _fetchCrypto,
      );
    } catch (_) {}
    return Rates({...fiat, ...crypto, 'KOIN': 1.0}, crypto.isNotEmpty);
  }

  /// Cache sqflite dengan TTL. Jeda minimal 10 detik antar panggilan jaringan
  /// (pembatas di sisi client). Jika jaringan gagal, pakai cache lama bila ada.
  static Future<Map<String, double>> _cached(
    String key,
    Duration ttl,
    Future<Map<String, double>> Function() fetch,
  ) async {
    Map<String, double>? old;
    int? t;
    try {
      final c = await LocalDb.getCache(key);
      if (c is Map) {
        t = c['t'] as int?;
        old = {
          for (final e in (c['v'] as Map).entries)
            e.key as String: (e.value as num).toDouble(),
        };
      }
    } catch (_) {}
    final now = DateTime.now().millisecondsSinceEpoch;
    if (old != null && t != null && now - t < ttl.inMilliseconds) return old;
    final last = _lastTry[key];
    if (old != null && last != null && now - last < 10000) return old;
    _lastTry[key] = now;
    try {
      final v = await fetch();
      await LocalDb.putCache(key, {'t': now, 'v': v});
      return v;
    } catch (_) {
      if (old != null) return old;
      rethrow;
    }
  }

  // open.er-api.com: basis USD, `rates[X]` = jumlah X per 1 USD
  static Future<Map<String, double>> _fetchFiat() async {
    final r = await _dio.get('https://open.er-api.com/v6/latest/USD');
    final rates = (r.data as Map)['rates'] as Map;
    final out = <String, double>{'USD': 1.0};
    for (final a in kRateAssets) {
      if (a.crypto || a.code == 'KOIN' || a.code == 'USD') continue;
      final v = (rates[a.code] as num?)?.toDouble();
      if (v != null && v > 0) out[a.code] = 1 / v;
    }
    if (out.length < 2) throw const FormatException('rates');
    return out;
  }

  // CoinGecko: satu panggilan untuk semua kripto, harga dalam USD
  static Future<Map<String, double>> _fetchCrypto() async {
    final coins = kRateAssets.where((a) => a.crypto).toList();
    final r = await _dio.get(
      'https://api.coingecko.com/api/v3/simple/price',
      queryParameters: {
        'ids': coins.map((a) => a.cgId).join(','),
        'vs_currencies': 'usd',
      },
    );
    final d = r.data as Map;
    final out = <String, double>{};
    for (final a in coins) {
      final v = ((d[a.cgId] as Map?)?['usd'] as num?)?.toDouble();
      if (v != null && v > 0) out[a.code] = v;
    }
    if (out.isEmpty) throw const FormatException('rates');
    return out;
  }
}
