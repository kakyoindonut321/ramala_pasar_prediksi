import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnchainCheck {
  const OnchainCheck({
    required this.recorded,
    required this.outcomeMatch,
    required this.hashMatch,
    this.recordedAt,
  });
  final bool recorded, outcomeMatch, hashMatch;
  final DateTime? recordedAt;
  bool get ok => recorded && outcomeMatch && hashMatch;
}

/// Membaca kontrak langsung (eth_call) dan membandingkannya dengan database.
class OnchainVerifier {
  static const contract = '0x127B77f2b1056475d18cd77beFCba625f76aA12C';
  // Read-only, tidak ada rahasia. Bisa diganti lewat env.json (CHAIN_RPC_URL).
  static const _rpc = String.fromEnvironment(
    'CHAIN_RPC_URL',
    defaultValue: 'https://ethereum-sepolia-rpc.publicnode.com',
  );
  static const _selector = '0x68dc05e9'; // hasil(bytes32)

  final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  Future<OnchainCheck> check(String marketId, String outcome) async {
    final row = await Supabase.instance.client
        .from('markets')
        .select('resolve_hash')
        .eq('id', marketId)
        .single();
    final dbHash = (row['resolve_hash'] as String?)?.toLowerCase();

    // UUID (16 byte) -> bytes32: buang '-', tambah nol di belakang
    final key = marketId.replaceAll('-', '').toLowerCase() + '0' * 32;

    final res = await _dio.post(
      _rpc,
      data: {
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'eth_call',
        'params': [
          {'to': contract, 'data': '$_selector$key'},
          'latest',
        ],
      },
    );
    final body = res.data;
    if (body is! Map || body['error'] != null || body['result'] is! String) {
      throw const FormatException('rpc');
    }
    final hex = (body['result'] as String).substring(2);
    if (hex.length < 256) throw const FormatException('rpc');

    // Hasil: (bool outcomeYes, bytes32 ledgerHash, uint64 waktu, bool ada), masing-masing 32 byte
    String word(int i) => hex.substring(i * 64, (i + 1) * 64);
    bool flag(int i) => BigInt.parse(word(i), radix: 16) != BigInt.zero;

    final recorded = flag(3);
    if (!recorded) {
      return const OnchainCheck(
        recorded: false,
        outcomeMatch: false,
        hashMatch: false,
      );
    }
    final secs = BigInt.parse(word(2), radix: 16).toInt();
    return OnchainCheck(
      recorded: true,
      outcomeMatch: flag(0) == (outcome == 'yes'),
      hashMatch: dbHash != null && word(1).toLowerCase() == dbHash,
      recordedAt: DateTime.fromMillisecondsSinceEpoch(secs * 1000),
    );
  }
}
