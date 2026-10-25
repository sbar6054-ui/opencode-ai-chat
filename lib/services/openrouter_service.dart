import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';

class OpenRouterService {
  static const String baseUrl = 'https://openrouter.ai/api/v1/chat/completions';

  Future<String> sendMessage({
    required String apiKey,
    required String model,
    required List<Message> messages,
  }) async {
    try {
      final List<Map<String, String>> apiMessages = messages
          .map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.content,
              })
          .toList();

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://github.com/opencode-ai-chat',
          'X-Title': 'OpenCode AI Chat',
        },
        body: jsonEncode({
          'model': model,
          'messages': apiMessages,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? 'No response';
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error']?['message'] ?? 'Unknown error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
