import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramala/core/error/app_error.dart';
import 'package:ramala/core/storage/local_db.dart';
import 'package:ramala/core/validators/validators.dart';
import 'package:ramala/features/chatbot/data/gemini_service.dart';
import 'package:ramala/features/market/presentation/market_providers.dart';
import 'package:ramala/template.dart';
import 'package:dio/dio.dart';
import 'package:ramala/features/chatbot/data/ai_chat_service.dart';

class _Msg {
  const _Msg(this.role, this.text);
  final String role; // 'user' | 'model'
  final String text;
}

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});
  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _c = TextEditingController();
  final _msgs = <_Msg>[];
  final _times = <DateTime>[]; // rate limit sisi client
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final rows = await LocalDb.chatHistory();
    if (!mounted) return;
    setState(
      () => _msgs.addAll(
        rows.map((r) => _Msg(r['role'] as String, r['content'] as String)),
      ),
    );
  }

  void _toast(String m) {
    if (mounted) AppToast.show(context, m, type: ToastType.error);
  }

  Future<void> _send() async {
    final text = Validators.clean(_c.text);
    if (text.isEmpty || _sending) return;
    if (text.length > 1000)
      return _toast('Pesan maksimal 1000 karakter.'); // BARU
    final now = DateTime.now();
    _times.removeWhere((t) => now.difference(t) > const Duration(minutes: 10));
    if (_times.length >= 15)
      return _toast('Terlalu banyak pesan, coba lagi beberapa menit lagi.');
    _times.add(now);
    _c.clear();
    setState(() {
      _msgs.add(_Msg('user', text));
      _sending = true;
    });
    await LocalDb.addChat('user', text);
    try {
      final markets = ref.read(marketListProvider('')).value ?? [];
      final ctx = markets
          .where((m) => m.isOpen)
          .take(10)
          .map((m) => '- ${m.title} (YES ${Fmt.pct(m.priceYes)})')
          .join('\n');
      final h = (_msgs.length > 10 ? _msgs.sublist(_msgs.length - 10) : _msgs)
          .toList();
      while (h.isNotEmpty && h.first.role != 'user') {
        h.removeAt(0);
      }
      final reply = await AiChatService().ask([
        // GANTI dari GeminiService
        for (final m in h) {'role': m.role, 'text': m.text},
      ], ctx);
      await LocalDb.addChat('model', reply);
      if (mounted) setState(() => _msgs.add(_Msg('model', reply)));
    } catch (e, st) {
      debugPrint('CHAT ERROR: $e\n$st');
      if (e is DioException) debugPrint('DIO BODY: ${e.response?.data}');
      _toast(
        e is FormatException
            ? 'API key AI belum diatur.' // GANTI teks
            : AppError.message(e),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _clear() async {
    if (!await AppConfirmDialog.show(
      context,
      title: 'Hapus riwayat?',
      message: 'Seluruh percakapan dihapus dari perangkat.',
      confirmLabel: 'Hapus',
      danger: true,
    )) {
      return;
    }
    await LocalDb.clearChat();
    if (mounted) setState(_msgs.clear);
  }

  @override
  Widget build(BuildContext context) {
    final list = _msgs.reversed.toList(); // reverse: pesan terbaru di bawah
    return AppScaffold(
      title: 'Ramala AI',
      actions: [
        IconButton(icon: const Icon(Icons.delete_outline), onPressed: _clear),
      ],
      body: Column(
        children: [
          Expanded(
            child: list.isEmpty
                ? const EmptyState(
                    title: 'Tanya Ramala AI',
                    message: 'Contoh: "Jelaskan cara kerja harga LMSR".',
                    icon: Icons.smart_toy_outlined,
                  )
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(AppSpace.lg),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final m = list[i];
                      final me = m.role == 'user';
                      return Align(
                        alignment: me
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: AppSpace.md),
                          padding: const EdgeInsets.all(AppSpace.md),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * .78,
                          ),
                          decoration: BoxDecoration(
                            color: me
                                ? AppColors.primary.withValues(alpha: .2)
                                : AppColors.card,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: me ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          child: SelectableText(m.text, style: AppText.body),
                        ),
                      );
                    },
                  ),
          ),
          if (_sending) const LinearProgressIndicator(color: AppColors.primary),
          Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Pesan',
                    controller: _c,
                    maxLength: 300,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: AppColors.primary),
                  onPressed: _sending ? null : _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
