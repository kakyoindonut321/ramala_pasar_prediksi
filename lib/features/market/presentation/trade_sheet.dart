import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static const _min = 0.01, _max = 1000.0;
  // Maksimal 4 digit bulat + 2 desimal; input lain ditolak
  static final _fmt = TextInputFormatter.withFunction(
    (o, n) => RegExp(r'^\d{0,4}([.,]\d{0,2})?$').hasMatch(n.text) ? n : o,
  );

  String _side = 'yes', _action = 'buy';
  final _ctrl = TextEditingController(text: '10');
  bool _busy = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// null jika kosong / bukan angka
  double? get _parsed {
    final v = double.tryParse(_ctrl.text.trim().replaceAll(',', '.'));
    return v == null ? null : (v * 100).round() / 100;
  }

  String? _validate(double? v) {
    if (_ctrl.text.trim().isEmpty) return 'Masukkan jumlah share';
    if (v == null) return 'Angka tidak valid';
    if (v < _min) return 'Minimal 0,01 share';
    if (v > _max) return 'Maksimal 1000 share';
    return null;
  }

  void _set(double v) {
    final s = v == v.roundToDouble() ? v.toInt().toString() : v.toString();
    setState(() => _ctrl.text = s);
  }

  Future<void> _submit(double shares) async {
    setState(() => _busy = true);
    try {
      final id = widget.market.id;
      final amount = await MarketRepository().trade(id, _side, _action, shares);
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
      if (mounted) {
        AppToast.show(context, AppError.message(e), type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.market;
    final buy = _action == 'buy';
    final held = _side == 'yes' ? widget.heldYes : widget.heldNo;
    final bal = ref.watch(balanceProvider).value;

    final shares = _parsed;
    String? err = _validate(shares);
    final valid = err == null;

    // Kuotasi hanya dihitung jika input valid
    final q = valid
        ? Lmsr.quote(
            qYes: m.qYes,
            qNo: m.qNo,
            b: m.b,
            side: _side,
            action: _action,
            shares: shares!,
          )
        : null;

    if (valid) {
      if (buy && bal != null && q!.amount > bal) err = 'Saldo tidak cukup';
      if (!buy && shares! > held) {
        err = 'Share ${_side.toUpperCase()} Anda hanya $held';
      }
    }
    // Maks jual: dibulatkan ke bawah 2 desimal, batas 1000
    final sellMax = ((held.clamp(0, _max)) * 100).floor() / 100;

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
        AppTextField(
          label: 'Jumlah share',
          hint: '0,01 - 1000',
          controller: _ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          maxLength: 7,
          formatters: [_fmt],
          onChanged: (_) => setState(() {}),
        ),
        const Gap(AppSpace.sm),
        Wrap(
          spacing: AppSpace.sm,
          children: [
            for (final v in const [10, 50, 100, 500])
              AppFilterChip(
                label: '$v',
                selected: shares == v.toDouble(),
                onTap: () => _set(v.toDouble()),
              ),
            if (!buy && sellMax >= _min)
              AppFilterChip(
                label: 'Maks',
                selected: shares == sellMax,
                onTap: () => _set(sellMax),
              ),
          ],
        ),
        const Gap(AppSpace.lg),
        _Line(
          buy ? 'Perkiraan biaya' : 'Perkiraan hasil',
          q == null ? const Text('-') : CoinText(q.amount),
        ),
        _Line(
          'Harga YES setelah',
          Text(q == null ? '-' : Fmt.pct(q.priceYes), style: AppText.body),
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
          onPressed: err == null && !_busy ? () => _submit(shares!) : null,
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
