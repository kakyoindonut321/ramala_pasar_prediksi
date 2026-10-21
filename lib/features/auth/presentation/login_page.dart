import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ramala/core/error/app_error.dart';
import 'package:ramala/core/validators/validators.dart';
import 'package:ramala/features/auth/data/auth_repository.dart';
import 'package:ramala/template.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ramala/features/auth/data/biometric_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  final _bio = BiometricService();
  bool _bioReady = false;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _checkBio();
  }

  Future<void> _checkBio() async {
    final ready = await _bio.supported && await _bio.enabled;
    if (mounted) setState(() => _bioReady = ready);
  }

  Future<void> _loginBio() async {
    if (!await _bio.authenticate()) return;
    final c = await _bio.credentials();
    if (c == null) return;
    setState(() => _loading = true);
    try {
      await AuthRepository().login(c.email, c.password);
    } on AuthException catch (e) {
      if (e.code == 'invalid_credentials') {
        await _bio.disable(); // kata sandi sudah berubah
        if (mounted) setState(() => _bioReady = false);
        if (mounted)
          AppToast.show(
            context,
            'Kata sandi berubah. Masuk manual, lalu aktifkan biometrik lagi.',
            type: ToastType.error,
          );
      } else if (mounted) {
        AppToast.show(context, AppError.message(e), type: ToastType.error);
      }
    } catch (e) {
      if (mounted)
        AppToast.show(context, AppError.message(e), type: ToastType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthRepository().login(Validators.clean(_email.text), _pass.text);
      // redirect otomatis oleh router
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
      children: [
        const Gap(AppSpace.xxl),
        const Center(child: AppLogo(size: 72, showName: true)),
        const Gap(AppSpace.xxl),
        Form(
          key: _form,
          child: Column(
            children: [
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
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Wajib diisi' : null,
              ),
            ],
          ),
        ),
        const Gap(AppSpace.xl),
        AppButton(
          label: 'Masuk',
          onPressed: _loading ? null : _submit,
          loading: _loading,
          expanded: true,
        ),
        if (_bioReady) ...[
          const Gap(AppSpace.sm),
          AppButton(
            label: 'Masuk dengan biometrik',
            variant: AppButtonVariant.secondary,
            icon: Icons.fingerprint,
            onPressed: _loading ? null : _loginBio,
          ),
        ],
        const Gap(AppSpace.sm),
        AppButton(
          label: 'Buat akun',
          variant: AppButtonVariant.ghost,
          expanded: true,
          onPressed: () => context.go('/register'),
        ),
      ],
    );
  }
}
