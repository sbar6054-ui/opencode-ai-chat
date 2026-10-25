import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';

class AIService {
  static const String baseUrl = 'https://text.pollinations.ai/';

  Future<String> sendMessage({
    required String model,
    required List<Message> messages,
    String? fileContent,
    String? fileName,
  }) async {
    try {
      String systemPrompt = 'You are GMpro87Ai, a helpful and intelligent AI assistant. Be concise, accurate, and helpful.';
      
      String userMessage = '';
      if (messages.isNotEmpty) {
        for (var msg in messages) {
          if (msg.isUser) {
            userMessage = msg.content;
          }
        }
      }
      
      if (fileContent != null && fileName != null) {
        systemPrompt += '\n\nThe user has uploaded a file: $fileName\nFile content:\n$fileContent\n\nPlease analyze and answer based on this file.';
      }

      final prompt = systemPrompt + '\n\nUser: ' + userMessage;
      
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': fileContent != null ? 'File: $fileName\n\n$content\n\n$userMessage' : userMessage}
          ],
          'model': model,
        }),
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Fallback to simple GET
        final encodedPrompt = Uri.encodeComponent(fileContent != null 
            ? 'File: $fileName\n\n$fileContent\n\n$userMessage' 
            : userMessage);
        final getResponse = await http.get(Uri.parse('$baseUrl$encodedPrompt?model=$model'));
        if (getResponse.statusCode == 200) {
          return getResponse.body;
        }
        throw Exception('Failed to get response: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
