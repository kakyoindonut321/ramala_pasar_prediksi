import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ramala/core/error/app_error.dart';
import 'package:ramala/features/converter/data/rates_service.dart';
import 'package:ramala/template.dart';

final ratesProvider = FutureProvider.autoDispose<Rates>(
  (ref) => RatesService.load(),
  retry: (_, __) => null,
);

final _options = [
  for (final a in kRateAssets) AppDropdownOption<String>(a.code, a.code),
];
final _price = NumberFormat('#,##0.00');
final _rupiah = NumberFormat('#,##0');

/// Harga kripto + konverter dua arah (A dan B sama-sama input dan hasil).
class ConverterSection extends ConsumerStatefulWidget {
  const ConverterSection({super.key});
  @override
  ConsumerState<ConverterSection> createState() => _ConverterSectionState();
}

class _ConverterSectionState extends ConsumerState<ConverterSection> {
  final _a = TextEditingController(text: '1'), _b = TextEditingController();
  String _codeA = 'KOIN', _codeB = 'IDR';
  bool _lastA = true; // sisi yang terakhir diketik = sumber hitung

  @override
  void initState() {
    super.initState();
    // Hitung ulang saat kurs selesai dimuat / diperbarui
    ref.listenManual(
      ratesProvider,
      (_, n) => n.whenData(_recalc),
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  String _plain(double v) {
    var s = v.toStringAsFixed(v >= 1000 ? 2 : (v >= 1 ? 4 : 8));
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    }
    return s;
  }

  void _recalc(Rates r) {
    final src = _lastA ? _a : _b, dst = _lastA ? _b : _a;
    final amt = double.tryParse(src.text);
    final out = amt == null
        ? null
        : r.convert(amt, _lastA ? _codeA : _codeB, _lastA ? _codeB : _codeA);
    dst.text = out == null ? '' : _plain(out);
  }

  @override
  Widget build(BuildContext context) {
    return ref
        .watch(ratesProvider)
        .when(
          loading: () => const AppSkeleton(height: 380),
          error: (e, _) => ErrorState(
            message: AppError.message(e),
            onRetry: () => ref.invalidate(ratesProvider),
          ),
          data: _content,
        );
  }

  Widget _content(Rates r) {
    final coins = kRateAssets
        .where((a) => a.crypto && r.usdPer.containsKey(a.code))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Konverter'),
        AppCard(
          padding: EdgeInsets.zero,
          child: r.hasCrypto
              ? Column(
                  children: [
                    for (var i = 0; i < coins.length; i++) ...[
                      if (i > 0) const Divider(),
                      CryptoTicker(
                        symbol: coins[i].code,
                        name: coins[i].name,
                        usd: '\$${_price.format(r.usdPer[coins[i].code])}',
                        idr: r.idr(coins[i].code) == null
                            ? null
                            : 'Rp ${_rupiah.format(r.idr(coins[i].code))}',
                      ),
                    ],
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.all(AppSpace.lg),
                  child: Text(
                    'Harga kripto belum tersedia.',
                    style: AppText.bodyDim,
                  ),
                ),
        ),
        const Gap(AppSpace.md),
        AppCard(
          child: Column(
            children: [
              CurrencyPairField(
                label: 'Dari',
                controller: _a,
                code: _codeA,
                options: _options,
                onAmount: (_) {
                  _lastA = true;
                  _recalc(r);
                },
                onCode: (c) {
                  setState(() => _codeA = c);
                  _recalc(r);
                },
              ),
              const Gap(AppSpace.lg),
              CurrencyPairField(
                label: 'Ke',
                controller: _b,
                code: _codeB,
                options: _options,
                onAmount: (_) {
                  _lastA = false;
                  _recalc(r);
                },
                onCode: (c) {
                  setState(() => _codeB = c);
                  _recalc(r);
                },
              ),
            ],
          ),
        ),
        const Gap(AppSpace.sm),
        Text(
          '1 KOIN = 1 USD. Kurs mata uang diperbarui tiap 1 jam, kripto tiap 2 menit.',
          style: AppText.caption,
        ),
      ],
    );
  }
}
