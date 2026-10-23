import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ramala/core/error/app_error.dart';
import 'package:ramala/core/validators/validators.dart';
import 'package:ramala/template.dart';

final _isAdminProvider = FutureProvider.autoDispose<bool>(
  (ref) async => await Supabase.instance.client.rpc('is_admin') == true,
  retry: (_, __) => null,
);

/// Parameter: tampilkan juga yang disembunyikan
final _feedbackListProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, bool>((ref, showHidden) async {
      final base = Supabase.instance.client
          .from('feedback')
          .select('id, impression, suggestion, rating, is_hidden, created_at');
      final f = showHidden ? base : base.eq('is_hidden', false);
      final rows = await f.order('created_at', ascending: false).limit(50);
      return List<Map<String, dynamic>>.from(rows);
    }, retry: (_, __) => null);

class FeedbackPage extends ConsumerStatefulWidget {
  const FeedbackPage({super.key});
  @override
  ConsumerState<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends ConsumerState<FeedbackPage> {
  final _form = GlobalKey<FormState>();
  final _impression = TextEditingController();
  final _suggestion = TextEditingController();
  int _rating = 0;
  bool _loading = false;
  bool _showHidden = false;

  @override
  void dispose() {
    _impression.dispose();
    _suggestion.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_rating == 0) {
      return AppToast.show(
        context,
        'Pilih rating terlebih dahulu',
        type: ToastType.error,
      );
    }
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
      ref.invalidate(_feedbackListProvider);
      if (mounted) {
        AppToast.show(
          context,
          'Terima kasih atas masukannya!',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, AppError.message(e), type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setHidden(Object id, bool hide) async {
    try {
      await Supabase.instance.client.rpc(
        'admin_set_feedback_hidden',
        params: {'p_id': id, 'p_hidden': hide},
      );
      ref.invalidate(_feedbackListProvider);
    } catch (e) {
      if (mounted) {
        AppToast.show(context, AppError.message(e), type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(_isAdminProvider).value ?? false;

    return AppScaffold(
      title: 'Saran & Kesan',
      onRefresh: isAdmin
          ? () async => ref.invalidate(_feedbackListProvider)
          : null,
      children: [
        Text(
          'Gimana Mata kuliah Pemrograman Aplikasi Mobile?',
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
        if (isAdmin) ...[
          const Gap(AppSpace.xl),
          const SectionHeader('Masukan Pengguna'),
          Align(
            alignment: Alignment.centerLeft,
            child: AppFilterChip(
              label: 'Tampilkan yang disembunyikan',
              selected: _showHidden,
              onTap: () => setState(() => _showHidden = !_showHidden),
            ),
          ),
          const Gap(AppSpace.md),
          ref
              .watch(_feedbackListProvider(_showHidden))
              .when(
                loading: () => const AppSkeleton(height: 110),
                error: (e, _) => ErrorState(
                  message: AppError.message(e),
                  onRetry: () => ref.invalidate(_feedbackListProvider),
                ),
                data: (rows) => rows.isEmpty
                    ? const EmptyState(
                        title: 'Belum ada masukan',
                        message: 'Masukan pengguna akan muncul di sini.',
                        icon: Icons.rate_review_outlined,
                      )
                    : Column(
                        children: [
                          for (final r in rows)
                            _FeedbackItem(
                              r,
                              onToggle: () => _setHidden(
                                r['id'] as Object,
                                r['is_hidden'] != true,
                              ),
                            ),
                        ],
                      ),
              ),
        ],
      ],
    );
  }
}

class _FeedbackItem extends StatelessWidget {
  const _FeedbackItem(this.r, {required this.onToggle});
  final Map<String, dynamic> r;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final hidden = r['is_hidden'] == true;
    final rating = (r['rating'] as num?)?.toInt() ?? 0;
    final date = DateTime.tryParse('${r['created_at']}')?.toLocal();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: Opacity(
        opacity: hidden ? 0.5 : 1,
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  for (var i = 1; i <= 5; i++)
                    Icon(
                      i <= rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: AppColors.accent,
                      size: 18,
                    ),
                  const Spacer(),
                  if (date != null)
                    Text(
                      DateFormat('d MMM y').format(date),
                      style: AppText.caption,
                    ),
                  IconButton(
                    tooltip: hidden ? 'Tampilkan' : 'Sembunyikan',
                    onPressed: onToggle,
                    icon: Icon(
                      hidden ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.textDim,
                      size: 20,
                    ),
                  ),
                ],
              ),
              Text('Kesan', style: AppText.label),
              Text('${r['impression']}', style: AppText.body),
              const Gap(AppSpace.sm),
              Text('Saran', style: AppText.label),
              Text('${r['suggestion']}', style: AppText.body),
            ],
          ),
        ),
      ),
    );
  }
}
