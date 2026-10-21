import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ramala/core/storage/local_db.dart';
import 'package:ramala/features/market/data/market_repository.dart';
import 'package:ramala/features/market/domain/market.dart';

class PortfolioPosition {
  const PortfolioPosition(
    this.market,
    this.side,
    this.shares,
    this.cost,
    this.realizedPnl,
  );
  final Market market;
  final String side;
  final double shares, cost, realizedPnl;

  /// Estimasi nilai pada harga pasar saat ini
  double get value =>
      shares * (side == 'yes' ? market.priceYes : 1 - market.priceYes);
  double get unrealized => shares > 0 ? value - cost : 0;

  factory PortfolioPosition.fromMap(Map<String, dynamic> m) =>
      PortfolioPosition(
        Market.fromMap(Map<String, dynamic>.from(m['markets'] as Map)),
        m['side'] as String,
        (m['shares'] as num).toDouble(),
        (m['cost'] as num).toDouble(),
        (m['realized_pnl'] as num).toDouble(),
      );
}

class TradeRecord {
  const TradeRecord(
    this.marketId,
    this.title,
    this.side,
    this.action,
    this.shares,
    this.amount,
    this.createdAt,
  );
  final String marketId, title, side, action;
  final double shares, amount;
  final DateTime createdAt;

  factory TradeRecord.fromMap(Map<String, dynamic> m) => TradeRecord(
    m['market_id'] as String,
    (m['markets'] as Map?)?['title'] as String? ?? '-',
    m['side'] as String,
    m['action'] as String,
    (m['shares'] as num).toDouble(),
    (m['amount'] as num).toDouble(),
    DateTime.parse(m['created_at'] as String),
  );
}

class PortfolioRepository {
  SupabaseClient get _db => Supabase.instance.client;

  /// Semua posisi (termasuk yang sudah 0 share, untuk total realized PnL). RLS: hanya milik sendiri.
  Future<List<PortfolioPosition>> positions() async {
    final uid = _db.auth.currentUser!.id;
    final rows = await LocalDb.cachedList(
      'portfolio:$uid',
      () => _db
          .from('positions')
          .select('side,shares,cost,realized_pnl,markets($marketCols)'),
    );
    return rows
        .where((r) => r['markets'] != null)
        .map(PortfolioPosition.fromMap)
        .toList();
  }

  Future<List<TradeRecord>> trades() async {
    final rows = await _db
        .from('trades')
        .select('market_id,side,action,shares,amount,created_at,markets(title)')
        .order('created_at', ascending: false)
        .limit(20);
    return rows.map(TradeRecord.fromMap).toList();
  }
}
