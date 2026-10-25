import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';

class AIService {
  Future<String> sendMessage({
    required String model,
    required List<Message> messages,
    String? fileContent,
    String? fileName,
  }) async {
    try {
      List<Map<String, String>> msgs = [];
      
      String systemMsg = 'You are a helpful assistant.';
      if (fileContent != null && fileName != null) {
        systemMsg = 'You are a helpful assistant. The user uploaded a file named $fileName. Here is its content:\n\n$fileContent\n\nAnalyze and answer based on the file.';
      }
      msgs.add({'role': 'system', 'content': systemMsg});
      
      for (var m in messages) {
        String content = m.content;
        if (content.contains('[')) {
          content = content.replaceAll(RegExp(r'\[.*?\]\s*'), '').trim();
        }
        msgs.add({
          'role': m.isUser ? 'user' : 'assistant',
          'content': content,
        });
      }
      
      // Try opencode's actual endpoint
      final endpoints = [
        'https://api.opencode.ai/chat/completions',
        'https://opencode.ai/api/chat/completions',
        'https://app.opencode.ai/api/chat/completions',
      ];
      
      for (String endpoint in endpoints) {
        try {
          final response = await http.post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'User-Agent': 'Mozilla/5.0',
            },
            body: jsonEncode({
              'model': model,
              'messages': msgs,
              'stream': false,
            }),
          ).timeout(const Duration(seconds: 30));
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['choices'] != null && data['choices'].isNotEmpty) {
              return data['choices'][0]['message']['content'] ?? '';
            } else if (data['content'] != null) {
              return data['content'];
            } else if (data['message'] != null) {
              return data['message'];
            }
            return response.body;
          }
        } catch (e) {
          continue;
        }
      }
      
      throw Exception('404 - Could not connect to API');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
