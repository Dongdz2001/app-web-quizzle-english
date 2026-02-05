import 'dart:convert';

import 'package:http/http.dart' as http;

/// Kết quả từ API text2audio.cc: URL audio hoặc bytes.
class Text2AudioResult {
  final String? audioUrl;
  final List<int>? audioBytes;

  const Text2AudioResult({this.audioUrl, this.audioBytes});
}

const _apiUrl = 'https://text2audio.cc/api/audio';

/// Gọi API text2audio.cc để tạo audio từ text.
/// [language] ví dụ "en-US", "vi-VN".
/// [paragraphs] nội dung cần đọc.
Future<Text2AudioResult?> fetchAudio({
  required String language,
  required String paragraphs,
  bool splitParagraph = true,
}) async {
  try {
    final body = jsonEncode({
      'language': language,
      'paragraphs': paragraphs,
      'splitParagraph': splitParagraph,
    });
    final response = await http
        .post(
          Uri.parse(_apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) return null;

    final contentType = response.headers['content-type'] ?? '';
    if (contentType.contains('application/json')) {
      final data = jsonDecode(response.body) as Map<String, dynamic>?;
      if (data == null) return null;
      final url = data['url'] as String? ??
          data['audioUrl'] as String? ??
          data['link'] as String? ??
          data['data'] as String?;
      if (url != null && url.isNotEmpty) {
        return Text2AudioResult(audioUrl: url);
      }
      final base64 = data['audio'] as String? ?? data['data'] as String?;
      if (base64 != null && base64.isNotEmpty) {
        final bytes = base64Decode(base64);
        return Text2AudioResult(audioBytes: bytes);
      }
      return null;
    }
    if (contentType.contains('audio/')) {
      return Text2AudioResult(audioBytes: response.bodyBytes);
    }
    return null;
  } catch (_) {
    return null;
  }
}
