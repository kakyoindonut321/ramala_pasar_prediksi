import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ramala/core/validators/validators.dart';
import 'package:ramala/template.dart';

/// Mengembalikan teks (sudah dirapikan, kecuali password) atau null jika dibatalkan.
Future<String?> askInput(
  BuildContext context, {
  required String title,
  required String label,
  String initial = '',
  bool password = false,
  int maxLength = 40,
  String? Function(String?)? validator,
  List<TextInputFormatter>? formatters,
  String confirmLabel = 'Simpan',
}) => AppBottomSheet.show<String>(
  context,
  title: title,
  child: _InputSheet(
    label,
    initial,
    password,
    maxLength,
    validator,
    formatters,
    confirmLabel,
  ),
);

class _InputSheet extends StatefulWidget {
  const _InputSheet(
    this.label,
    this.initial,
    this.password,
    this.maxLength,
    this.validator,
    this.formatters,
    this.confirmLabel,
  );
  final String label, initial, confirmLabel;
  final bool password;
  final int maxLength;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? formatters;

  @override
  State<_InputSheet> createState() => _InputSheetState();
}

class _InputSheetState extends State<_InputSheet> {
  final _form = GlobalKey<FormState>();
  late final _c = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _ok() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(
      context,
      widget.password ? _c.text : Validators.clean(_c.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              label: widget.label,
              controller: _c,
              password: widget.password,
              maxLength: widget.maxLength,
              formatters: widget.formatters,
              validator: widget.validator,
            ),
            const Gap(AppSpace.lg),
            AppButton(label: widget.confirmLabel, onPressed: _ok),
          ],
        ),
      ),
    );
  }
}
