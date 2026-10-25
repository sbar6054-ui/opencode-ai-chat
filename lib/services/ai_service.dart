import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  Future<String> sendMessage({
    required String model,
    required List messages,
    String? fileContent,
    String? fileName,
    String? imageBase64,
  }) async {
    try {
      String userMessage = '';
      if (messages.isNotEmpty) {
        for (var msg in messages.reversed) {
          if (msg.isUser) {
            userMessage = msg.content.toString();
            break;
          }
        }
      }

      String cleanMessage = userMessage
          .replaceAll(RegExp(r'\[.*?\]\n?'), '')
          .trim();

      if (imageBase64 != null && fileName != null) {
        try {
          final res = await http
              .post(
                Uri.parse('https://text.pollinations.ai/openai'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'model': model,
                  'messages': [
                    {
                      'role': 'system',
                      'content':
                          'You are GMpro87Ai, a helpful and intelligent AI assistant.'
                    },
                    {
                      'role': 'user',
                      'content': [
                        {
                          'type': 'text',
                          'text': cleanMessage.isEmpty
                              ? 'Describe this image'
                              : cleanMessage
                        },
                        {
                          'type': 'image_url',
                          'image_url': {'url': 'data:image/jpeg;base64,$imageBase64'}
                        }
                      ]
                    }
                  ],
                  'temperature': 0.7,
                  'max_tokens': 2048,
                }),
              )
              .timeout(const Duration(seconds: 90));

          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            if (data['choices'] != null && data['choices'].isNotEmpty) {
              return data['choices'][0]['message']['content'] ?? res.body;
            }
            return res.body;
          }
        } catch (e) {
          // fall through to text only
        }
      }

      String prompt = 'You are GMpro87Ai, a helpful and intelligent AI assistant.\n\n';
      if (fileContent != null && fileName != null) {
        prompt += 'File: $fileName\n$fileContent\n\n';
      }
      prompt += 'User: $cleanMessage.isEmpty ? userMessage : cleanMessage';

      final encoded = Uri.encodeComponent(prompt);
      final uri =
          Uri.parse('https://text.pollinations.ai/$encoded?model=$model');
      final res = await http.get(uri).timeout(const Duration(seconds: 90));

      if (res.statusCode == 200 && res.body.trim().isNotEmpty) {
        return res.body;
      }

      throw Exception('Failed to get response: ${res.statusCode}');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
