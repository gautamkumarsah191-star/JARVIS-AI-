import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class AiService {
  Future<String> sendMessage({
    required List<Map<String, String>> messages,
  }) async {
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/api/chat',
    );

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'messages': messages,
          }),
        )
        .timeout(const Duration(seconds: 50));

    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw Exception(
        'Backend returned an unreadable response.',
      );
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      final message =
          decoded is Map && decoded['error'] is String
              ? decoded['error'] as String
              : 'AI request failed (${response.statusCode}).';

      throw Exception(message);
    }

    if (decoded is! Map ||
        decoded['reply'] is! String) {
      throw Exception(
        'The backend returned an invalid response.',
      );
    }

    return decoded['reply'] as String;
  }
}
