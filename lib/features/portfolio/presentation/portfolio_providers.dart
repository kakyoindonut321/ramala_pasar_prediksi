import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramala/features/portfolio/data/portfolio_repository.dart';

final portfolioProvider = FutureProvider.autoDispose<List<PortfolioPosition>>(
  (ref) => PortfolioRepository().positions(),
  retry: (_, __) => null,
);

final tradesProvider = FutureProvider.autoDispose<List<TradeRecord>>(
  (ref) => PortfolioRepository().trades(),
  retry: (_, __) => null,
);
