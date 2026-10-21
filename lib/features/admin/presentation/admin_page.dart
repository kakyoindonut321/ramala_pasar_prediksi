import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ramala/core/error/app_error.dart';
import 'package:ramala/core/validators/validators.dart';
import 'package:ramala/features/market/domain/market.dart';
import 'package:ramala/features/market/presentation/market_providers.dart';
import 'package:ramala/template.dart';

class AdminPage extends ConsumerStatefulWidget {
  const AdminPage({super.key});
  @override
  ConsumerState<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends ConsumerState<AdminPage> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _cat = TextEditingController(text: 'general');
  final _b = TextEditingController(text: '100');
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  DateTime? _close;
  bool _busy = false;

  SupabaseClient get _db => Supabase.instance.client;
  final _numFmt = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]'))];
  static const _numKb = TextInputType.numberWithOptions(
    decimal: true,
    signed: true,
  );

  @override
  void dispose() {
    for (final c in [_title, _desc, _cat, _b, _lat, _lng]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _range(String? v, double min, double max, {bool optional = false}) {
    final s = Validators.clean(v ?? '');
    if (s.isEmpty) return optional ? null : 'Wajib diisi';
    final n = double.tryParse(s);
    if (n == null || n < min || n > max) return 'Harus $min sampai $max';
    return null;
  }

  Future<void> _pickClose() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 23, minute: 59),
    );
    if (t == null) return;
    setState(() => _close = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  void _toast(String m, [ToastType t = ToastType.error]) {
    if (mounted) AppToast.show(context, m, type: t);
  }

  Future<void> _create() async {
    if (!_form.currentState!.validate()) return;
    if (_close == null || !_close!.isAfter(DateTime.now()))
      return _toast('Pilih waktu tutup di masa depan');
    final hasLat = _lat.text.trim().isNotEmpty,
        hasLng = _lng.text.trim().isNotEmpty;
    if (hasLat != hasLng)
      return _toast(
        'Isi latitude dan longitude bersamaan, atau kosongkan keduanya',
      );
    setState(() => _busy = true);
    try {
      await _db.rpc(
        'admin_create_market',
        params: {
          'p_title': Validators.clean(_title.text),
          'p_close_at': _close!.toUtc().toIso8601String(),
          'p_description': Validators.clean(_desc.text),
          'p_category': Validators.clean(_cat.text),
          'p_b': double.parse(_b.text),
          if (hasLat) 'p_lat': double.parse(_lat.text),
          if (hasLng) 'p_lng': double.parse(_lng.text),
        },
      );
      for (final c in [_title, _desc, _lat, _lng]) {
        c.clear();
      }
      setState(() => _close = null);
      ref.invalidate(marketListProvider);
      _toast('Market dibuat', ToastType.success);
    } catch (e) {
      _toast(AppError.message(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resolve(Market m) async {
    final outcome = await AppBottomSheet.show<String>(
      context,
      title: 'Hasil market',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(m.title, style: AppText.bodyDim),
          const Gap(AppSpace.lg),
          AppButton(
            label: 'YES menang',
            onPressed: () => Navigator.pop(context, 'yes'),
          ),
          const Gap(AppSpace.sm),
          AppButton(
            label: 'NO menang',
            variant: AppButtonVariant.danger,
            onPressed: () => Navigator.pop(context, 'no'),
          ),
        ],
      ),
    );
    if (outcome == null || !mounted) return;
    final ok = await AppConfirmDialog.show(
      context,
      title: 'Selesaikan market?',
      message:
          'Hasil ${outcome.toUpperCase()} tidak dapat diubah. Payout langsung dibagikan.',
      confirmLabel: 'Selesaikan',
      danger: true,
    );
    if (!ok) return;
    setState(() => _busy = true);
    try {
      await _db.rpc(
        'admin_resolve_market',
        params: {'p_market': m.id, 'p_outcome': outcome},
      );
      ref.invalidate(marketListProvider);
      ref.invalidate(marketProvider(m.id));
      _toast('Market diselesaikan', ToastType.success);
    } catch (e) {
      _toast(AppError.message(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final markets = ref.watch(marketListProvider(''));
    return AppScaffold(
      title: 'Panel Admin',
      children: [
        const SectionHeader('Buat market'),
        Form(
          key: _form,
          child: Column(
            children: [
              AppTextField(
                label: 'Judul',
                controller: _title,
                maxLength: 140,
                validator: (v) => Validators.required(v, min: 5, max: 140),
              ),
              const Gap(AppSpace.md),
              AppTextField(
                label: 'Deskripsi (opsional)',
                controller: _desc,
                maxLength: 1000,
                maxLines: 3,
              ),
              const Gap(AppSpace.md),
              AppTextField(
                label: 'Kategori',
                controller: _cat,
                maxLength: 20,
                formatters: Validators.usernameFormatters,
                validator: (v) =>
                    RegExp(r'^[a-z0-9_]{2,20}$')
                        .hasMatch(Validators.clean(v ?? ''))
                    ? null
                    : '2-20 karakter: huruf kecil, angka, _',
              ),
              const Gap(AppSpace.md),
              AppTextField(
                label: 'Parameter b (10-1000)',
                controller: _b,
                keyboardType: _numKb,
                maxLength: 6,
                formatters: _numFmt,
                validator: (v) => _range(v, 10, 1000),
              ),
              const Gap(AppSpace.md),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Latitude',
                      controller: _lat,
                      keyboardType: _numKb,
                      maxLength: 12,
                      formatters: _numFmt,
                      validator: (v) => _range(v, -90, 90, optional: true),
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: AppTextField(
                      label: 'Longitude',
                      controller: _lng,
                      keyboardType: _numKb,
                      maxLength: 12,
                      formatters: _numFmt,
                      validator: (v) => _range(v, -180, 180, optional: true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Gap(AppSpace.md),
        AppButton(
          label: _close == null
              ? 'Pilih waktu tutup'
              : DateFormat('d MMM y HH:mm').format(_close!),
          icon: Icons.event,
          variant: AppButtonVariant.secondary,
          onPressed: _pickClose,
        ),
        const Gap(AppSpace.md),
        AppButton(
          label: 'Buat market',
          loading: _busy,
          onPressed: _busy ? null : _create,
        ),
        const Gap(AppSpace.xl),
        const SectionHeader('Selesaikan market'),
        markets.when(
          loading: () => const AppSkeleton(height: 120),
          error: (e, _) => ErrorState(
            message: AppError.message(e),
            onRetry: () => ref.invalidate(marketListProvider('')),
          ),
          data: (all) {
            final open = all.where((m) => m.status == 'open').toList();
            if (open.isEmpty) {
              return const EmptyState(
                title: 'Tidak ada market aktif',
                message: 'Semua market sudah diselesaikan.',
                icon: Icons.task_alt,
              );
            }
            return AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < open.length; i++) ...[
                    if (i > 0) const Divider(),
                    AppListTile(
                      icon: Icons.gavel,
                      title: open[i].title,
                      subtitle:
                          'Tutup ${DateFormat('d MMM y HH:mm').format(open[i].closeAt.toLocal())}',
                      onTap: _busy ? null : () => _resolve(open[i]),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
