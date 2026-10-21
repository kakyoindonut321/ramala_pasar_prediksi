import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramala/core/error/app_error.dart';
import 'package:ramala/features/market/data/market_repository.dart';
import 'package:ramala/features/market/domain/lmsr.dart';
import 'package:ramala/features/market/domain/market.dart';
import 'package:ramala/features/market/presentation/market_providers.dart';
import 'package:ramala/features/portfolio/presentation/portfolio_providers.dart';
import 'package:ramala/features/profile/presentation/profile_providers.dart';
import 'package:ramala/template.dart';

class TradeSheet extends ConsumerStatefulWidget {
  const TradeSheet({
    super.key,
    required this.market,
    required this.heldYes,
    required this.heldNo,
  });
  final Market market;
  final double heldYes, heldNo;
  @override
  ConsumerState<TradeSheet> createState() => _TradeSheetState();
}

class _TradeSheetState extends ConsumerState<TradeSheet> {
  String _side = 'yes', _action = 'buy';
  double _shares = 10;
  bool _busy = false;

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      final id = widget.market.id;
      final amount = await MarketRepository().trade(
        id,
        _side,
        _action,
        _shares,
      );
      ref.invalidate(marketProvider(id));
      ref.invalidate(priceHistoryProvider(id));
      ref.invalidate(marketListProvider);
      ref.invalidate(portfolioProvider);
      ref.invalidate(tradesProvider);
      ref.invalidate(balanceProvider);
      if (!mounted) return;
      AppToast.show(
        context,
        '${_action == 'buy' ? 'Pembelian' : 'Penjualan'} berhasil (${Fmt.coin(amount)} koin)',
        type: ToastType.success,
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted)
        AppToast.show(context, AppError.message(e), type: ToastType.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.market;
    final buy = _action == 'buy';
    final q = Lmsr.quote(
      qYes: m.qYes,
      qNo: m.qNo,
      b: m.b,
      side: _side,
      action: _action,
      shares: _shares,
    );
    final held = _side == 'yes' ? widget.heldYes : widget.heldNo;
    final bal = ref.watch(balanceProvider).value;

    String? err;
    if (buy && bal != null && q.amount > bal) err = 'Saldo tidak cukup';
    if (!buy && _shares > held)
      err = 'Share ${_side.toUpperCase()} Anda hanya $held';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSegmented<String>(
          options: const [
            AppSegmentOption('buy', 'Beli'),
            AppSegmentOption('sell', 'Jual'),
          ],
          value: _action,
          onChanged: (v) => setState(() => _action = v),
        ),
        const Gap(AppSpace.md),
        AppSegmented<String>(
          options: [
            AppSegmentOption('yes', 'YES', color: AppColors.yes),
            AppSegmentOption('no', 'NO', color: AppColors.no),
          ],
          value: _side,
          onChanged: (v) => setState(() => _side = v),
        ),
        const Gap(AppSpace.lg),
        AppAmountStepper(
          value: _shares,
          onChanged: (v) => setState(() => _shares = (v * 100).round() / 100),
          min: 1,
          max: 1000,
          step: 1,
          label: 'Jumlah share',
        ),
        const Gap(AppSpace.lg),
        _Line(buy ? 'Perkiraan biaya' : 'Perkiraan hasil', CoinText(q.amount)),
        _Line(
          'Harga YES setelah',
          Text(Fmt.pct(q.priceYes), style: AppText.body),
        ),
        _Line('Saldo', bal == null ? const Text('-') : CoinText(bal)),
        if (!buy) _Line('Share dimiliki', Text('$held', style: AppText.body)),
        if (err != null) ...[
          const Gap(AppSpace.sm),
          Text(err, style: AppText.caption.copyWith(color: AppColors.no)),
        ],
        const Gap(AppSpace.sm),
        Text(
          'Nilai final ditentukan server saat transaksi.',
          style: AppText.caption,
        ),
        const Gap(AppSpace.lg),
        AppButton(
          label: buy
              ? 'Beli ${_side.toUpperCase()}'
              : 'Jual ${_side.toUpperCase()}',
          loading: _busy,
          onPressed: err == null && !_busy ? _submit : null,
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);
  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppText.bodyDim),
        value,
      ],
    ),
  );
}
