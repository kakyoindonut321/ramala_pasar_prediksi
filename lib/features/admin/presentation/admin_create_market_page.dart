import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ramala/core/error/app_error.dart';
import 'package:ramala/core/validators/validators.dart';
import 'package:ramala/features/admin/presentation/pin_picker_page.dart';
import 'package:ramala/features/market/presentation/market_providers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ramala/features/market/data/market_image_service.dart';
import 'package:ramala/template.dart';

class AdminCreateMarketPage extends ConsumerStatefulWidget {
  const AdminCreateMarketPage({super.key});
  @override
  ConsumerState<AdminCreateMarketPage> createState() => _State();
}

class _State extends ConsumerState<AdminCreateMarketPage> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _cat = TextEditingController(text: 'general');
  final _b = TextEditingController(text: '100');
  DateTime? _close;
  LatLng? _pin;
  bool _busy = false;
  XFile? _img;
  Uint8List? _imgBytes; // untuk preview

  @override
  void dispose() {
    for (final c in [_title, _desc, _cat, _b]) {
      c.dispose();
    }
    super.dispose();
  }

  void _toast(String m, [ToastType t = ToastType.error]) {
    if (mounted) AppToast.show(context, m, type: t);
  }

  String? _bRange(String? v) {
    final n = double.tryParse(Validators.clean(v ?? ''));
    return (n == null || n < 10 || n > 1000) ? 'Harus 10 sampai 1000' : null;
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

  Future<void> _pickPin() async {
    final p = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (_) => PinPickerPage(initial: _pin)),
    );
    if (p != null) setState(() => _pin = p);
  }

  /// Hanya menerima gambar persegi (rasio 1:1, toleransi 2%), min. 200 px
  Future<void> _pickImage() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (x == null) return;
    final bytes = await x.readAsBytes();
    final im = await decodeImageFromList(bytes);
    final ratio = im.width / im.height;
    if (ratio < 0.98 || ratio > 1.02 || im.width < 200) {
      return _toast('Gambar harus persegi (1:1), minimal 200 px.');
    }
    setState(() {
      _img = x;
      _imgBytes = bytes;
    });
  }

  Future<void> _create() async {
    if (_busy || !_form.currentState!.validate()) return;
    if (_close == null || !_close!.isAfter(DateTime.now())) {
      return _toast('Pilih waktu tutup di masa depan');
    }
    setState(() => _busy = true);
    try {
      final imageUrl = _img == null
          ? null
          : await MarketImageService().upload(_img!.path);
      await Supabase.instance.client.rpc(
        'admin_create_market',
        params: {
          'p_title': Validators.clean(_title.text),
          'p_close_at': _close!.toUtc().toIso8601String(),
          'p_description': Validators.clean(_desc.text),
          'p_category': Validators.clean(_cat.text),
          'p_b': double.parse(_b.text),
          if (imageUrl != null) 'p_image_url': imageUrl,
          if (_pin != null) 'p_lat': _pin!.latitude,
          if (_pin != null) 'p_lng': _pin!.longitude,
        },
      );
      ref.invalidate(marketListProvider);
      ref.invalidate(categoriesProvider);
      _toast('Market dibuat', ToastType.success);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _toast(
        e is FormatException
            ? 'Gambar tidak valid atau terlalu besar.'
            : AppError.message(e),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Buat market',
      children: [
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
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                maxLength: 6,
                formatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                validator: _bRange,
              ),
            ],
          ),
        ),
        const Gap(AppSpace.md),
        if (_imgBytes != null)
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Image.memory(
                _imgBytes!,
                width: 96,
                height: 96,
                fit: BoxFit.cover,
              ),
            ),
          ),
        AppButton(
          label: _img == null
              ? 'Pilih gambar persegi (opsional)'
              : 'Ganti gambar',
          icon: Icons.image_outlined,
          variant: AppButtonVariant.secondary,
          expanded: true,
          onPressed: _busy ? null : _pickImage,
        ),
        if (_img != null)
          Align(
            alignment: Alignment.centerRight,
            child: AppButton(
              label: 'Hapus gambar',
              variant: AppButtonVariant.ghost,
              onPressed: () => setState(() {
                _img = null;
                _imgBytes = null;
              }),
            ),
          ),
        const Gap(AppSpace.md),
        AppButton(
          label: _close == null
              ? 'Pilih waktu tutup'
              : DateFormat('d MMM y HH:mm').format(_close!),
          icon: Icons.event,
          variant: AppButtonVariant.secondary,
          expanded: true,
          onPressed: _pickClose,
        ),
        const Gap(AppSpace.md),
        AppButton(
          label: _pin == null
              ? 'Tandai lokasi di peta (opsional)'
              : '${_pin!.latitude.toStringAsFixed(5)}, ${_pin!.longitude.toStringAsFixed(5)}',
          icon: Icons.location_on_outlined,
          variant: AppButtonVariant.secondary,
          expanded: true,
          onPressed: _pickPin,
        ),
        if (_pin != null)
          Align(
            alignment: Alignment.centerRight,
            child: AppButton(
              label: 'Hapus lokasi',
              variant: AppButtonVariant.ghost,
              onPressed: () => setState(() => _pin = null),
            ),
          ),
        const Gap(AppSpace.lg),
        AppButton(
          label: 'Buat market',
          loading: _busy,
          expanded: true,
          onPressed: _busy ? null : _create,
        ),
      ],
    );
  }
}
