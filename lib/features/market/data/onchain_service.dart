import 'package:supabase_flutter/supabase_flutter.dart';

/// Meminta server mencatat resolusi market ke smart contract.
/// Melempar FunctionException jika server menolak atau chain gagal.
class OnchainService {
  static const explorerTx = 'https://sepolia.etherscan.io/tx/';

  Future<String> record(String marketId) async {
    final res = await Supabase.instance.client.functions.invoke(
      'record-onchain',
      body: {'market_id': marketId},
    );
    final d = res.data;
    return d is Map ? (d['status'] as String? ?? 'failed') : 'failed';
  }
}
