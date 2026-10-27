import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramala/features/market/data/market_repository.dart';
import 'package:ramala/features/market/domain/market.dart';

final marketListProvider = FutureProvider.autoDispose
    .family<List<Market>, String>(
      (ref, q) => MarketRepository().list(q),
      retry: (_, __) => null,
    );

final marketProvider = FutureProvider.autoDispose.family<Market, String>(
  (ref, id) => MarketRepository().get(id),
  retry: (_, __) => null,
);

final priceHistoryProvider = FutureProvider.autoDispose
    .family<List<double>, String>(
      (ref, id) => MarketRepository().history(id),
      retry: (_, __) => null,
    );

final marketPageProvider = FutureProvider.autoDispose
    .family<List<Market>, MarketQuery>(
      (ref, q) => MarketRepository().page(q),
      retry: (_, __) => null,
    );

final categoriesProvider = FutureProvider.autoDispose<List<String>>(
  (ref) => MarketRepository().categories(),
  retry: (_, __) => null,
);

final hasHistoryProvider = FutureProvider.autoDispose<bool>(
  (ref) => MarketRepository().hasHistory(),
  retry: (_, __) => null,
);
