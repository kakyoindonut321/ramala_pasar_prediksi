import 'package:dio/dio.dart';
import 'package:ramala/core/config/env.dart';

class GroqService {
  static const _model = 'openai/gpt-oss-20b';
  static final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  Future<String> ask(List<Map<String, String>> history, String system) async {
    final r = await _dio.post(
      'https://api.groq.com/openai/v1/chat/completions',
      options: Options(headers: {'Authorization': 'Bearer ${Env.groqKey}'}),
      data: {
        'model': _model,
        'messages': [
          {'role': 'system', 'content': system},
          for (final m in history)
            {
              'role': m['role'] == 'model' ? 'assistant' : 'user',
              'content': m['text'],
            },
        ],
        'max_completion_tokens': 1000, // termasuk token reasoning
        'reasoning_effort': 'low',
        'temperature': 0.7,
      },
    );
    final c = r.data['choices'];
    final msg = (c is List && c.isNotEmpty) ? (c[0] as Map)['message'] : null;
    final text = msg is Map ? (msg['content'] ?? '').toString().trim() : '';
    return text.isEmpty ? 'Maaf, saya tidak bisa menjawab itu.' : text;
  }
}
