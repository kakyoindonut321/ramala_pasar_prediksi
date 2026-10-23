import 'package:dio/dio.dart';
import 'package:ramala/core/config/env.dart';

class GeminiService {
  static const _model =
      'gemini-3.8-flash'; // ganti jika model sudah dipensiunkan
  static final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  Future<String> ask(List<Map<String, String>> history, String system) async {
    final r = await _dio.post(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent',
      options: Options(headers: {'x-goog-api-key': Env.geminiKey}),
      data: {
        'systemInstruction': {
          'parts': [
            {'text': system},
          ],
        },
        'contents': [
          for (final m in history)
            {
              'role': m['role'],
              'parts': [
                {'text': m['text']},
              ],
            },
        ],
        'generationConfig': {
          'maxOutputTokens': 600,
          'temperature': 0.7,
          'thinkingConfig': {'thinkingBudget': 0},
        },
      },
    );
    final c = r.data['candidates'];
    final content = (c is List && c.isNotEmpty)
        ? (c[0] as Map)['content']
        : null;
    final parts = content is Map ? content['parts'] : null;
    final text = parts is List
        ? parts.map((p) => p['text'] ?? '').join().trim()
        : '';
    if (text.isEmpty) throw const FormatException('empty'); // picu fallback
    return text;
  }
}
