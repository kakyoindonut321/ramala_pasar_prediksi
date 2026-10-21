import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ramala/core/error/app_error.dart';
import 'package:ramala/core/validators/validators.dart';
import 'package:ramala/core/widgets/input_sheet.dart';
import 'package:ramala/features/auth/data/auth_repository.dart';
import 'package:ramala/features/auth/data/biometric_service.dart';
import 'package:ramala/features/profile/data/cloudinary_service.dart';
import 'package:ramala/features/profile/data/profile_repository.dart';
import 'package:ramala/features/profile/presentation/profile_providers.dart';
import 'package:ramala/template.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});
  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _bio = BiometricService();
  final _repo = ProfileRepository();
  bool _bioOk = false, _bioOn = false, _busy = false;

  String? get _email => Supabase.instance.client.auth.currentUser?.email;

  @override
  void initState() {
    super.initState();
    _loadBio();
  }

  Future<void> _loadBio() async {
    final ok = await _bio.supported;
    final on = await _bio.enabledFor(_email);
    if (mounted) {
      setState(() {
        _bioOk = ok;
        _bioOn = on;
      });
    }
  }

  void _toast(String m, [ToastType t = ToastType.error]) {
    if (mounted) AppToast.show(context, m, type: t);
  }

  Future<void> _run(Future<void> Function() job) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await job();
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

  Future<void> _pickAvatar() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (x == null) return;
    await _run(() async {
      final url = await CloudinaryService().uploadAvatar(x.path);
      await _repo.update(avatarUrl: url);
      ref.invalidate(profileProvider);
      _toast('Foto profil diperbarui', ToastType.success);
    });
  }

  Future<void> _editName(Profile p) async {
    final v = await askInput(
      context,
      title: 'Ubah nama tampilan',
      label: 'Nama',
      initial: p.displayName ?? '',
      validator: Validators.displayName,
    );
    if (v == null) return;
    await _run(() async {
      await _repo.update(displayName: v);
      ref.invalidate(profileProvider);
    });
  }

  Future<void> _toggleBio() async {
    if (_bioOn) {
      final ok = await AppConfirmDialog.show(
        context,
        title: 'Nonaktifkan biometrik?',
        message: 'Kredensial tersimpan akan dihapus dari perangkat.',
        confirmLabel: 'Nonaktifkan',
      );
      if (!ok) return;
      await _bio.disable();
      setState(() => _bioOn = false);
      return;
    }
    if (!await _bio.authenticate())
      return _toast('Verifikasi dibatalkan atau gagal.');
    if (!mounted) return;
    final pw = await askInput(
      context,
      title: 'Konfirmasi kata sandi',
      label: 'Kata sandi',
      password: true,
      maxLength: 64,
      confirmLabel: 'Aktifkan',
    );
    if (pw == null || _email == null) return;
    await _run(() async {
      await AuthRepository().login(_email!, pw); // verifikasi sandi
      await _bio.enable(_email!, pw);
      if (mounted) setState(() => _bioOn = true);
      _toast('Login biometrik aktif', ToastType.success);
    });
  }

  Future<void> _logout() async {
    final ok = await AppConfirmDialog.show(
      context,
      title: 'Keluar?',
      message: 'Anda harus masuk lagi untuk memakai Ramala.',
      confirmLabel: 'Keluar',
      danger: true,
    );
    if (!ok || !mounted) return;
    final router = GoRouter.of(context);
    try {
      await AuthRepository().logout();
      router.go('/login');
    } catch (e) {
      _toast(AppError.message(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final balance = ref.watch(balanceProvider);

    return AppScaffold(
      title: 'Profil',
      onRefresh: () async {
        ref.invalidate(profileProvider);
        ref.invalidate(balanceProvider);
        await ref.read(profileProvider.future);
      },
      children: [
        if (_busy) const LinearProgressIndicator(color: AppColors.primary),
        profile.when(
          loading: () => const AppSkeleton(height: 180),
          error: (e, _) => ErrorState(
            message: AppError.message(e),
            onRetry: () => ref.invalidate(profileProvider),
          ),
          data: (p) => Column(
            children: [
              AppCard(
                glow: true,
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      AppAvatar(
                        name: p.displayName ?? p.username,
                        url: p.avatarUrl,
                        radius: 44,
                      ),
                      const Gap(AppSpace.md),
                      Text(p.displayName ?? p.username, style: AppText.heading),
                      Text('@${p.username}', style: AppText.bodyDim),
                      const Gap(AppSpace.md),
                      balance.when(
                        data: (b) => CoinText(b),
                        loading: () => const AppSkeleton(width: 80, height: 20),
                        error: (_, __) => const Text('-'),
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(AppSpace.lg),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    AppListTile(
                      icon: Icons.photo_camera_outlined,
                      title: 'Ganti foto profil',
                      onTap: _pickAvatar,
                    ),
                    const Divider(),
                    AppListTile(
                      icon: Icons.edit_outlined,
                      title: 'Ubah nama tampilan',
                      onTap: () => _editName(p),
                    ),
                    if (_bioOk) ...[
                      const Divider(),
                      AppListTile(
                        icon: Icons.fingerprint,
                        title: 'Login biometrik',
                        subtitle: _bioOn ? 'Aktif' : 'Nonaktif',
                        onTap: _toggleBio,
                      ),
                    ],
                    // ===== sisipkan di sini =====
                    const Divider(),
                    AppListTile(
                      icon: Icons.link,
                      title: 'Ledger blockchain',
                      onTap: () => context.push('/ledger'),
                    ),
                    if (p.role == 'admin') ...[
                      const Divider(),
                      AppListTile(
                        icon: Icons.admin_panel_settings_outlined,
                        title: 'Panel admin',
                        onTap: () => context.push('/admin'),
                      ),
                    ],
                    // ===== akhir sisipan =====
                    const Divider(),
                    AppListTile(
                      icon: Icons.logout,
                      title: 'Keluar',
                      danger: true,
                      onTap: _logout,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
