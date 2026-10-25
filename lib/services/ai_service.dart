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

      String finalPrompt;
      if (fileContent != null && fileName != null) {
        finalPrompt = '$systemPrompt\n\nThe user has uploaded a file: $fileName\nFile content:\n$fileContent\n\nUser: $userMessage';
      } else {
        finalPrompt = '$systemPrompt\n\nUser: $userMessage';
      }
      
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': fileContent != null && fileName != null ? 'File: $fileName\n\n$fileContent\n\n$userMessage' : userMessage}
          ],
          'model': model,
        }),
      );

      if (response.statusCode == 200) {
        String body = response.body;
        if (body.isEmpty) {
          throw Exception('Empty response');
        }
        return body;
      } else {
        final encodedPrompt = Uri.encodeComponent(fileContent != null && fileName != null 
            ? 'File: $fileName\n\n$fileContent\n\n$userMessage' 
            : userMessage);
        final getResponse = await http.get(Uri.parse('$baseUrl$encodedPrompt?model=$model'));
        if (getResponse.statusCode == 200 && getResponse.body.isNotEmpty) {
          return getResponse.body;
        }
        throw Exception('Failed to get response');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
