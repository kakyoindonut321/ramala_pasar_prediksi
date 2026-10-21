import 'dart:math';

class Lmsr {
  /// C(q) = b * ln(e^(qy/b) + e^(qn/b)), versi log-sum-exp stabil
  static double cost(double qy, double qn, double b) {
    final m = max(qy, qn);
    return m + b * log(exp((qy - m) / b) + exp((qn - m) / b));
  }

  static double price(double qy, double qn, double b) =>
      1 / (1 + exp((qn - qy) / b));

  /// amount = biaya beli (dibulatkan ke atas) atau hasil jual (ke bawah), 4 desimal
  static ({double amount, double priceYes}) quote({
    required double qYes,
    required double qNo,
    required double b,
    required String side,
    required String action,
    required double shares,
  }) {
    final buy = action == 'buy';
    final d = buy ? shares : -shares;
    final qy = side == 'yes' ? qYes + d : qYes;
    final qn = side == 'no' ? qNo + d : qNo;
    final c0 = cost(qYes, qNo, b);
    final c1 = cost(qy, qn, b);
    final diff = buy ? c1 - c0 : c0 - c1;
    final amount = buy
        ? (diff * 10000).ceil() / 10000
        : (diff * 10000).floor() / 10000;
    return (amount: amount, priceYes: price(qy, qn, b));
  }
}
