import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ramala/core/error/app_error.dart';
import 'package:ramala/core/validators/validators.dart';
import 'package:ramala/template.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});
  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _form = GlobalKey<FormState>();
  final _impression = TextEditingController();
  final _suggestion = TextEditingController();
  int _rating = 0;
  bool _loading = false;

  @override
  void dispose() {
    _impression.dispose();
    _suggestion.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_rating == 0)
      return AppToast.show(
        context,
        'Pilih rating terlebih dahulu',
        type: ToastType.error,
      );
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.from('feedback').insert({
        'impression': Validators.clean(_impression.text),
        'suggestion': Validators.clean(_suggestion.text),
        'rating': _rating,
      });
      _impression.clear();
      _suggestion.clear();
      setState(() => _rating = 0);
      if (mounted)
        AppToast.show(
          context,
          'Terima kasih atas masukannya!',
          type: ToastType.success,
        );
    } catch (e) {
      if (mounted)
        AppToast.show(context, AppError.message(e), type: ToastType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Saran & Kesan',
      children: [
        Text(
          'Mata kuliah Pemrograman Aplikasi Mobile',
          style: AppText.bodyDim,
          textAlign: TextAlign.center,
        ),
        const Gap(AppSpace.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 1; i <= 5; i++)
              IconButton(
                onPressed: () => setState(() => _rating = i),
                icon: Icon(
                  i <= _rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: AppColors.accent,
                  size: 36,
                ),
              ),
          ],
        ),
        const Gap(AppSpace.md),
        Form(
          key: _form,
          child: Column(
            children: [
              AppTextField(
                label: 'Kesan',
                controller: _impression,
                maxLength: 500,
                maxLines: 4,
                validator: (v) => Validators.required(v, min: 5),
              ),
              const Gap(AppSpace.md),
              AppTextField(
                label: 'Saran',
                controller: _suggestion,
                maxLength: 500,
                maxLines: 4,
                validator: (v) => Validators.required(v, min: 5),
              ),
            ],
          ),
        ),
        const Gap(AppSpace.xl),
        AppButton(
          label: 'Kirim',
          onPressed: _loading ? null : _submit,
          loading: _loading,
        ),
      ],
    );
  }
}
