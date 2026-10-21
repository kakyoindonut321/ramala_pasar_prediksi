import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramala/features/profile/data/profile_repository.dart';

final profileProvider = FutureProvider.autoDispose<Profile>(
  (ref) => ProfileRepository().me(),
  retry: (_, __) => null, // tampilkan error langsung, tanpa retry otomatis
);

final balanceProvider = FutureProvider.autoDispose<double>(
  (ref) => ProfileRepository().balance(),
  retry: (_, __) => null,
);
