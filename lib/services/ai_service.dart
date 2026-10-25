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
    String? imageBase64,
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

      if (imageBase64 != null) {
        try {
          final response = await http.post(
            Uri.parse('https://text.pollinations.ai/openai'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': model,
              'messages': [
                {'role': 'system', 'content': systemPrompt},
                {
                  'role': 'user',
                  'content': [
                    {'type': 'text', 'text': userMessage.replaceAll('[Image: $fileName]', '').trim().isEmpty ? 'Describe this image' : userMessage.replaceAll('[Image: $fileName]', '').trim()},
                    {'type': 'image_url', 'image_url': {'url': 'data:image/jpeg;base64,$imageBase64'}}
                  ]
                }
              ],
              'max_tokens': 1024,
            }),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['choices'] != null && data['choices'].isNotEmpty) {
              return data['choices'][0]['message']['content'] ?? response.body;
            }
            return response.body;
          }
        } catch (e) {
          // fallback
        }
      }

      String finalPrompt;
      if (fileContent != null && fileName != null && imageBase64 == null) {
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
            {'role': 'user', 'content': fileContent != null && fileName != null && imageBase64 == null ? 'File: $fileName\n\n$fileContent\n\n$userMessage' : userMessage.replaceAll('[Image: $fileName]', '').trim().isEmpty ? userMessage : userMessage}
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
        final encodedPrompt = Uri.encodeComponent(fileContent != null && fileName != null && imageBase64 == null 
            ? 'File: $fileName\n\n$fileContent\n\n$userMessage' 
            : userMessage.replaceAll(RegExp(r'\[.*?\]\n?'), '').trim());
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
