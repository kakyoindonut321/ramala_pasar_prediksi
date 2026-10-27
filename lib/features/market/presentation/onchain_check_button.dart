import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ramala/core/error/app_error.dart';
import 'package:ramala/features/market/data/onchain_verifier.dart';
import 'package:ramala/template.dart';

class OnchainCheckButton extends StatefulWidget {
  const OnchainCheckButton({
    super.key,
    required this.marketId,
    required this.outcome,
  });
  final String marketId, outcome;

  @override
  State<OnchainCheckButton> createState() => _OnchainCheckButtonState();
}

class _OnchainCheckButtonState extends State<OnchainCheckButton> {
  bool _busy = false;

  Future<void> _run() async {
    setState(() => _busy = true);
    try {
      final r = await OnchainVerifier().check(widget.marketId, widget.outcome);
      if (!mounted) return;
      await AppBottomSheet.show<void>(
        context,
        title: r.ok ? 'Terverifikasi on-chain' : 'Tidak cocok dengan chain',
        child: _Result(r),
      );
    } catch (e) {
      if (mounted) {
        AppToast.show(context, AppError.message(e), type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppButton(
    label: 'Cek on-chain',
    variant: AppButtonVariant.secondary,
    icon: Icons.verified_outlined,
    loading: _busy,
    onPressed: _busy ? null : _run,
  );
}

class _Result extends StatelessWidget {
  const _Result(this.r);
  final OnchainCheck r;

  Widget _row(String label, bool ok) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.sm),
    child: Row(
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.cancel,
          color: ok ? AppColors.yes : AppColors.no,
          size: 20,
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(child: Text(label, style: AppText.body)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      _row('Resolusi tercatat di kontrak', r.recorded),
      _row('Hasil YES/NO sama dengan database', r.outcomeMatch),
      _row('Hash ledger sama dengan database', r.hashMatch),
      if (r.recordedAt != null) ...[
        const Gap(AppSpace.xs),
        Text(
          'Dicatat ${DateFormat('d MMM y HH:mm').format(r.recordedAt!.toLocal())}',
          style: AppText.caption,
        ),
      ],
      const Gap(AppSpace.md),
      Text(
        'Dibaca langsung dari kontrak di Sepolia, tanpa melalui server Ramala.',
        style: AppText.caption,
      ),
    ],
  );
}
