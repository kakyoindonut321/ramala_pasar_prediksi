import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:ramala/core/error/app_error.dart';
import 'package:ramala/features/converter/data/rates_repository.dart';
import 'package:ramala/features/market/domain/market.dart';
import 'package:ramala/features/market/presentation/market_providers.dart';
import 'package:ramala/template.dart';

final _fiatProvider = FutureProvider.autoDispose<Map<String, double>>(
  (ref) => RatesRepository().fiat(),
  retry: (_, __) => null,
);
final _cryptoProvider = FutureProvider.autoDispose<Map<String, double>>(
  (ref) => RatesRepository().crypto(),
  retry: (_, __) => null,
);

const _currencies = ['KOIN', 'USD', 'IDR', 'EUR', 'JPY', 'SGD'];
const _zones = {
  'WIB': 'Asia/Jakarta',
  'WITA': 'Asia/Makassar',
  'WIT': 'Asia/Jayapura',
  'London': 'Europe/London',
};
final _num = NumberFormat('#,##0.####');

class ConverterPage extends ConsumerStatefulWidget {
  const ConverterPage({super.key});
  @override
  ConsumerState<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends ConsumerState<ConverterPage> {
  int _tab = 0;
  final _amount = TextEditingController(text: '1');
  String _from = 'KOIN', _to = 'IDR';
  DateTime _at = DateTime.now();

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Konverter',
      children: [
        AppSegmented<int>(
          options: const [
            AppSegmentOption(0, 'Mata uang'),
            AppSegmentOption(1, 'Kripto'),
            AppSegmentOption(2, 'Waktu'),
          ],
          value: _tab,
          onChanged: (v) => setState(() => _tab = v),
        ),
        const Gap(AppSpace.lg),
        switch (_tab) {
          0 => _fiatView(),
          1 => _cryptoView(),
          _ => _timeView(),
        },
      ],
    );
  }

  Widget _chips(String value, void Function(String) onPick) => Wrap(
    spacing: AppSpace.sm,
    runSpacing: AppSpace.sm,
    children: [
      for (final c in _currencies)
        AppFilterChip(
          label: c,
          selected: value == c,
          onTap: () => setState(() => onPick(c)),
        ),
    ],
  );

  Widget _fiatView() {
    return ref
        .watch(_fiatProvider)
        .when(
          loading: () => const AppSkeleton(height: 220),
          error: (e, _) => ErrorState(
            message: AppError.message(e),
            onRetry: () => ref.invalidate(_fiatProvider),
          ),
          data: (r) {
            final rates = {...r, 'KOIN': 1.0}; // 1 koin dummy = 1 USD
            final amt = double.tryParse(_amount.text) ?? 0;
            final out = amt / rates[_from]! * rates[_to]!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  label: 'Jumlah',
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  maxLength: 12,
                  formatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  onChanged: (_) => setState(() {}),
                ),
                const Gap(AppSpace.lg),
                Text('Dari', style: AppText.label),
                const Gap(AppSpace.sm),
                _chips(_from, (c) => _from = c),
                const Gap(AppSpace.lg),
                Text('Ke', style: AppText.label),
                const Gap(AppSpace.sm),
                _chips(_to, (c) => _to = c),
                const Gap(AppSpace.xl),
                AppCard(
                  glow: true,
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      children: [
                        Text(
                          '${_num.format(amt)} $_from =',
                          style: AppText.bodyDim,
                        ),
                        const Gap(AppSpace.xs),
                        Text('${_num.format(out)} $_to', style: AppText.number),
                      ],
                    ),
                  ),
                ),
                const Gap(AppSpace.sm),
                Text(
                  '1 KOIN = 1 USD (nilai dummy). Kurs diperbarui tiap 1 jam.',
                  style: AppText.caption,
                ),
              ],
            );
          },
        );
  }

  Widget _cryptoView() {
    return ref
        .watch(_cryptoProvider)
        .when(
          loading: () => const AppSkeleton(height: 200),
          error: (e, _) => ErrorState(
            message: AppError.message(e),
            onRetry: () => ref.invalidate(_cryptoProvider),
          ),
          data: (r) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final e
                        in RatesRepository.coins.entries
                            .toList()
                            .asMap()
                            .entries) ...[
                      if (e.key > 0) const Divider(),
                      AppListTile(
                        icon: Icons.currency_bitcoin,
                        title:
                            '${e.value.value}  \$${_num.format(r['${e.value.key}_usd'])}',
                        subtitle: 'Rp ${_num.format(r['${e.value.key}_idr'])}',
                      ),
                    ],
                  ],
                ),
              ),
              const Gap(AppSpace.sm),
              Text(
                'Harga referensi aset kripto (CoinGecko), cache 2 menit.',
                style: AppText.caption,
              ),
            ],
          ),
        );
  }

  Future<void> _pickTime() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _at,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_at),
    );
    if (t == null) return;
    setState(() => _at = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> _pickMarket() async {
    try {
      final list = await ref.read(marketListProvider('').future);
      if (!mounted) return;
      final m = await AppBottomSheet.show<Market>(
        context,
        title: 'Pilih market',
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final m in list.take(8))
                AppListTile(
                  icon: Icons.schedule,
                  title: m.title,
                  onTap: () => Navigator.pop(context, m),
                ),
            ],
          ),
        ),
      );
      if (m != null) setState(() => _at = m.closeAt.toLocal());
    } catch (e) {
      if (mounted)
        AppToast.show(context, AppError.message(e), type: ToastType.error);
    }
  }

  Widget _timeView() {
    final zones = _zones.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppButton(
          label: DateFormat('d MMM y HH:mm').format(_at),
          icon: Icons.event,
          variant: AppButtonVariant.secondary,
          onPressed: _pickTime,
        ),
        const Gap(AppSpace.sm),
        AppButton(
          label: 'Pakai waktu tutup market',
          icon: Icons.show_chart,
          variant: AppButtonVariant.ghost,
          onPressed: _pickMarket,
        ),
        const Gap(AppSpace.lg),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < zones.length; i++) ...[
                if (i > 0) const Divider(),
                AppListTile(
                  icon: Icons.public,
                  title: zones[i].key,
                  subtitle: DateFormat('EEE, d MMM y HH:mm').format(
                    tz.TZDateTime.from(
                      _at.toUtc(),
                      tz.getLocation(zones[i].value),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
