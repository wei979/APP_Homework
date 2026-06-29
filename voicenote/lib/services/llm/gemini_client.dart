import 'dart:convert';
import 'dart:io';

/// 極簡 Google Gemini (Generative Language API) 客戶端。
///
/// 用 responseSchema 取得固定深度的樹狀 JSON。免費層金鑰來自 Google AI Studio。
class GeminiClient {
  // gemini-2.5-flash：免費層可用、速度快，足夠做摘要/語意整理。
  static const String _model = 'gemini-2.5-flash';
  static String get _endpoint =>
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  final String apiKey;
  const GeminiClient(this.apiKey);

  /// 呼叫 generateContent，回傳受 responseSchema 約束的 JSON 字串。
  Future<String> structuredJson({
    required String system,
    required String userContent,
    required Map<String, dynamic> responseSchema,
  }) async {
    final body = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': system},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': userContent},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.4,
        'responseMimeType': 'application/json',
        'responseSchema': responseSchema,
      },
    });

    final client = HttpClient();
    try {
      final req = await client.postUrl(Uri.parse(_endpoint));
      req.headers.set('content-type', 'application/json');
      req.headers.set('x-goog-api-key', apiKey); // 金鑰走 header，不放 URL
      req.add(utf8.encode(body));
      final resp = await req.close();
      final respBody = await resp.transform(utf8.decoder).join();

      if (resp.statusCode != 200) {
        throw LlmException(_extractError(respBody, resp.statusCode));
      }

      final decoded = jsonDecode(respBody) as Map<String, dynamic>;
      final candidates = (decoded['candidates'] as List?) ?? const [];
      if (candidates.isEmpty) {
        final fb = decoded['promptFeedback'];
        final reason = fb is Map ? fb['blockReason'] : null;
        throw LlmException(reason != null ? '請求被擋下（$reason）' : '回應中沒有內容');
      }
      final cand = candidates.first as Map<String, dynamic>;
      final finish = cand['finishReason'];
      final parts =
          ((cand['content'] as Map?)?['parts'] as List?) ?? const [];
      for (final part in parts) {
        if (part is Map && part['text'] is String) {
          return part['text'] as String;
        }
      }
      throw LlmException('回應未完成（finishReason=$finish）');
    } finally {
      client.close();
    }
  }

  String _extractError(String respBody, int status) {
    try {
      final m = jsonDecode(respBody) as Map<String, dynamic>;
      final err = m['error'];
      if (err is Map && err['message'] != null) {
        return 'API 錯誤 ($status)：${err['message']}';
      }
    } catch (_) {}
    return 'API 錯誤 ($status)';
  }
}

class LlmException implements Exception {
  final String message;
  const LlmException(this.message);
  @override
  String toString() => message;
}