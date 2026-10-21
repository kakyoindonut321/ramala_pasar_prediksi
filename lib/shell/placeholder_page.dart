import 'package:flutter/material.dart';
import 'package:ramala/core/error/app_error.dart';
import 'package:ramala/features/auth/data/auth_repository.dart';
import 'package:ramala/template.dart';

class PlaceholderPage extends StatelessWidget {
  final String title;
  final bool showLogout;
  const PlaceholderPage(this.title, {super.key, this.showLogout = false});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: title,
      children: [
        const Gap(AppSpace.xxl),
        EmptyState(
          title: 'Segera hadir',
          message: 'Halaman $title dibuat di tahap berikutnya.',
          icon: Icons.construction,
        ),
        if (showLogout) ...[
          const Gap(AppSpace.xl),
          AppButton(
            label: 'Keluar',
            variant: AppButtonVariant.danger,
            expanded: true,
            onPressed: () async {
              try {
                await AuthRepository().logout();
              } catch (e) {
                if (context.mounted)
                  AppToast.show(
                    context,
                    AppError.message(e),
                    type: ToastType.error,
                  );
              }
            },
          ),
        ],
      ],
    );
  }
}
