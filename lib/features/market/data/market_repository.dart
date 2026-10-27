import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ramala/core/storage/local_db.dart';
import 'package:ramala/core/validators/validators.dart';
import 'package:ramala/features/market/domain/market.dart';

const marketCols =
    'id,title,description,category,image_url,close_at,status,outcome,b,q_yes,q_no,price_yes,volume,chain_status,chain_tx';

/// Kunci query halaman pasar (record, equality otomatis untuk family provider)
typedef MarketQuery = ({
  String text,
  String? category,
  bool done,
  String sort, // 'trending' | 'newest'
  int limit,
});

class MarketRepository {
  SupabaseClient get _db => Supabase.instance.client;

  /// Tanpa kata kunci: dicache untuk mode offline
  Future<List<Market>> list(String query) async {
    Future<List<Map<String, dynamic>>> fetch() {
      var req = _db.from('markets').select(marketCols);
      if (query.isNotEmpty)
        req = req.ilike('title', '%${Validators.likeEscape(query)}%');
      return req.order('created_at', ascending: false).limit(100);
    }

    final rows = query.isEmpty
        ? await LocalDb.cachedList('markets:list', fetch)
        : await fetch();
    return rows.map(Market.fromMap).toList();
  }

  Future<Market> get(String id) async => Market.fromMap(
    await _db.from('markets').select(marketCols).eq('id', id).single(),
  );

  Future<List<double>> history(String id) async {
    final rows = await _db
        .from('price_history')
        .select('price_yes')
        .eq('market_id', id)
        .order('created_at', ascending: false)
        .limit(100);
    return rows.reversed
        .map((r) => (r['price_yes'] as num).toDouble())
        .toList();
  }

  /// Mengembalikan jumlah koin yang dibayar/diterima (hasil resmi server)
  Future<double> trade(
    String market,
    String side,
    String action,
    double shares,
  ) async {
    final r = await _db.rpc(
      'trade_market',
      params: {
        'p_market': market,
        'p_side': side,
        'p_action': action,
        'p_shares': shares,
      },
    );
    return ((r as Map)['amount'] as num).toDouble();
  }

  /// Halaman pasar: filter aktif/selesai, kategori, pencarian, dan urutan di server
  Future<List<Market>> page(MarketQuery q) async {
    Future<List<Map<String, dynamic>>> fetch() {
      final now = DateTime.now().toUtc().toIso8601String();
      var req = _db.from('markets').select(marketCols);
      req = q.done
          ? req.or('status.neq.open,close_at.lte.$now')
          : req.eq('status', 'open').gt('close_at', now);
      if (q.category != null) req = req.eq('category', q.category!);
      if (q.text.isNotEmpty) {
        req = req.ilike('title', '%${Validators.likeEscape(q.text)}%');
      }
      final ordered = q.sort == 'trending'
          ? req
                .order('volume', ascending: false)
                .order('created_at', ascending: false)
          : req.order('created_at', ascending: false);
      return ordered.limit(q.limit);
    }

    // Cache offline hanya untuk tampilan tanpa pencarian
    final rows = q.text.isEmpty
        ? await LocalDb.cachedList(
            'markets:page:${q.done}:${q.sort}:${q.category}:${q.limit}',
            fetch,
          )
        : await fetch();
    return rows.map(Market.fromMap).toList();
  }

  Future<List<String>> categories() async {
    final rows = await _db.from('markets').select('category').limit(1000);
    return ({...rows.map((r) => r['category'] as String)}.toList()..sort());
  }
}
