import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ramala/core/error/app_error.dart';
import 'package:ramala/features/notification/data/notification_repository.dart';
import 'package:ramala/features/notification/domain/app_notification.dart';
import 'package:ramala/template.dart';

final notificationsProvider = FutureProvider.autoDispose<List<AppNotification>>(
  (ref) => NotificationRepository().list(),
  retry: (_, __) => null,
);

/// Lonceng dengan badge jumlah belum dibaca (untuk actions AppScaffold)
class NotifBell extends ConsumerWidget {
  const NotifBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n =
        ref
            .watch(notificationsProvider)
            .value
            ?.where((x) => !x.isRead)
            .length ??
        0;
    return Badge(
      isLabelVisible: n > 0,
      label: Text('$n'),
      child: IconButton(
        icon: const Icon(Icons.notifications_outlined),
        onPressed: () => context.push('/notifikasi'),
      ),
    );
  }
}

class NotificationPage extends ConsumerWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    final repo = NotificationRepository();

    return AppScaffold(
      title: 'Notifikasi',
      actions: [
        IconButton(
          tooltip: 'Tandai semua dibaca',
          icon: const Icon(Icons.done_all),
          onPressed: () async {
            try {
              await repo.markAllRead();
              ref.invalidate(notificationsProvider);
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
      onRefresh: () async {
        ref.invalidate(notificationsProvider);
        try {
          await ref.read(notificationsProvider.future);
        } catch (_) {}
      },
      children: [
        async.when(
          loading: () => Column(
            children: [
              for (var i = 0; i < 3; i++) ...[
                const AppSkeleton(height: 64),
                const Gap(AppSpace.md),
              ],
            ],
          ),
          error: (e, _) => ErrorState(
            message: AppError.message(e),
            onRetry: () => ref.invalidate(notificationsProvider),
          ),
          data: (list) => list.isEmpty
              ? const EmptyState(
                  title: 'Belum ada notifikasi',
                  message: 'Hasil market akan muncul di sini.',
                  icon: Icons.notifications_none,
                )
              : AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < list.length; i++) ...[
                        if (i > 0) const Divider(),
                        AppListTile(
                          icon: list[i].isRead
                              ? Icons.notifications_none
                              : Icons.notifications_active,
                          title: list[i].title,
                          subtitle:
                              '${list[i].body}\n${DateFormat('d MMM HH:mm').format(list[i].createdAt.toLocal())}',
                          onTap: () async {
                            final n = list[i];
                            if (!n.isRead) {
                              try {
                                await repo.markRead(n.id);
                                ref.invalidate(notificationsProvider);
                              } catch (_) {}
                            }
                            if (n.marketId != null && context.mounted)
                              context.push('/market/${n.marketId}');
                          },
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
