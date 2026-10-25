import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';

class AIService {
  static const String baseUrl = 'https://api.opencode.ai/v1/chat/completions';

  Future<String> sendMessage({
    required String model,
    required List<Message> messages,
    String? fileContent,
    String? fileName,
  }) async {
    try {
      List<Map<String, String>> msgs = [];
      
      if (fileContent != null && fileName != null) {
        msgs.add({
          'role': 'system',
          'content': 'You are a helpful assistant. The user uploaded a file named $fileName. Here is its content:\n\n$fileContent\n\nUse this file to answer questions.'
        });
      } else {
        msgs.add({
          'role': 'system',
          'content': 'You are a helpful, accurate, and concise assistant.'
        });
      }
      
      for (var m in messages) {
        msgs.add({
          'role': m.isUser ? 'user' : 'assistant',
          'content': m.content.replaceAll(RegExp(r'\[.*?\]\n'), '').trim(),
        });
      }
      
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': model,
          'messages': msgs,
          'stream': false,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          return data['choices'][0]['message']['content'] ?? '';
        }
      }
      
      throw Exception('Failed to get response: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
