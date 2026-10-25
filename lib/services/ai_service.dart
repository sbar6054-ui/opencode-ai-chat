import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  final List<String> _fallbackModels = [
    'openai',
    'mistral',
    'deepseek',
    'gemini',
    'llama',
  ];

  Future<String> sendMessage({
    required String model,
    required List messages,
    String? fileContent,
    String? fileName,
    String? imageBase64,
  }) async {
    String userMessage = '';
    if (messages.isNotEmpty) {
      for (var msg in messages.reversed) {
        final content = msg.content;
        if (msg.isUser == true) {
          userMessage = content.toString();
          break;
        }
      }
    }

    String cleanMessage = userMessage
        .replaceAll(RegExp(r'\[.*?\]\n?'), '')
        .trim();
    if (cleanMessage.isEmpty && fileName != null && imageBase64 == null) {
      cleanMessage = 'Analisis file ini dengan detail';
    } else if (cleanMessage.isEmpty && imageBase64 != null) {
      cleanMessage = 'Analisis gambar ini dengan detail';
    }

    String result = await _tryModel(
      model: model,
      cleanMessage: cleanMessage,
      fileContent: fileContent,
      fileName: fileName,
      imageBase64: imageBase64,
    );

    if (result.isNotEmpty && !result.startsWith('ERROR:')) {
      return result;
    }

    for (String fallback in _fallbackModels) {
      if (fallback == model) continue;
      String fbResult = await _tryModel(
        model: fallback,
        cleanMessage: cleanMessage,
        fileContent: fileContent,
        fileName: fileName,
        imageBase64: imageBase64,
      );
      if (fbResult.isNotEmpty && !fbResult.startsWith('ERROR:')) {
        return fbResult;
      }
    }

    throw Exception('Semua model lagi sibuk. Coba lagi beberapa saat ya.');
  }

  Future<String> _tryModel({
    required String model,
    required String cleanMessage,
    String? fileContent,
    String? fileName,
    String? imageBase64,
  }) async {
    try {
      if (imageBase64 != null) {
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
                          'You are GMpro87Ai, a helpful, smart and detailed AI assistant.'
                    },
                    {
                      'role': 'user',
                      'content': [
                        {'type': 'text', 'text': cleanMessage},
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
              .timeout(const Duration(seconds: 60));

          if (res.statusCode == 200 && res.body.isNotEmpty) {
            try {
              final data = jsonDecode(res.body);
              if (data['choices'] != null && data['choices'].isNotEmpty) {
                final content = data['choices'][0]['message']['content'];
                if (content != null && content.toString().isNotEmpty) {
                  return content.toString();
                }
              }
            } catch (_) {}
            return res.body;
          }
        } catch (_) {}
      }

      String prompt = 'You are GMpro87Ai, a helpful, smart and detailed AI assistant.\n\n';
      if (fileContent != null && fileName != null) {
        String filePrompt = fileContent.length > 8000
            ? fileContent.substring(0, 8000) + '\n\n[File truncated...]'
            : fileContent;
        prompt += 'File: $fileName\n$filePrompt\n\n';
      }
      prompt += 'User Question:\n$cleanMessage\n\nAnswer in detail and clearly.';

      final encoded = Uri.encodeComponent(prompt);
      final uri = Uri.parse('https://text.pollinations.ai/$encoded?model=$model');

      final res = await http.get(uri).timeout(const Duration(seconds: 60));

      if (res.statusCode == 200 && res.body.trim().isNotEmpty) {
        return res.body;
      }

      return 'ERROR: ${res.statusCode}';
    } catch (e) {
      return 'ERROR: $e';
    }
  }
}
