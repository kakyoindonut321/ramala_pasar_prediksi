import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ramala/core/error/app_error.dart';
import 'package:ramala/core/validators/validators.dart';
import 'package:ramala/features/auth/data/auth_repository.dart';
import 'package:ramala/template.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _user = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _user.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthRepository().register(
        Validators.clean(_email.text),
        _pass.text,
        Validators.clean(_user.text),
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
      title: 'Buat akun',
      children: [
        Form(
          key: _form,
          child: Column(
            children: [
              AppTextField(
                label: 'Username',
                controller: _user,
                icon: Icons.person_outline,
                maxLength: 20,
                formatters: Validators.usernameFormatters,
                validator: Validators.username,
              ),
              const Gap(AppSpace.md),
              AppTextField(
                label: 'Email',
                controller: _email,
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                maxLength: 100,
                validator: Validators.email,
              ),
              const Gap(AppSpace.md),
              AppTextField(
                label: 'Kata sandi',
                controller: _pass,
                icon: Icons.lock_outline,
                password: true,
                maxLength: 64,
                validator: Validators.password,
              ),
            ],
          ),
        ),
        const Gap(AppSpace.xl),
        AppButton(
          label: 'Daftar',
          onPressed: _loading ? null : _submit,
          loading: _loading,
          expanded: true,
        ),
        const Gap(AppSpace.sm),
        AppButton(
          label: 'Sudah punya akun',
          variant: AppButtonVariant.ghost,
          expanded: true,
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}
