import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  final List<String> _fallbackModels = [
    'openai',
    'gemini',
    'deepseek',
    'mistral',
    'llama',
    'qwen',
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

    throw Exception('Gagal konek. Coba lagi ya.');
  }

  Future<String> _tryModel({
    required String model,
    required String cleanMessage,
    String? fileContent,
    String? fileName,
    String? imageBase64,
  }) async {
    try {
      List<Map<String, dynamic>> userContent = [];
      if (imageBase64 != null) {
        userContent.add({
          'type': 'image_url',
          'image_url': {'url': 'data:image/jpeg;base64,$imageBase64'}
        });
      }
      userContent.add({
        'type': 'text',
        'text': imageBase64 != null
            ? cleanMessage
            : (fileContent != null && fileName != null
                ? 'File: $fileName\n${fileContent.length > 6000 ? fileContent.substring(0, 6000) + "\n[truncated]" : fileContent}\n\n$cleanMessage'
                : cleanMessage)
      });

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
                    'content': 'You are GMpro87Ai, a helpful, concise, and accurate AI assistant. Answer directly and clearly.'
                  },
                  {'role': 'user', 'content': userContent.length == 1 && userContent[0]['type'] == 'text' ? cleanMessage : userContent}
                ],
                'temperature': 0.7,
                'max_tokens': 2048,
              }),
            )
            .timeout(const Duration(seconds: 90));

        if (res.statusCode == 200 && res.body.isNotEmpty) {
          try {
            final data = jsonDecode(res.body);
            if (data['choices'] != null && data['choices'].isNotEmpty) {
              final content = data['choices'][0]['message']?['content'];
              if (content != null && content.toString().trim().isNotEmpty) {
                return content.toString();
              }
            }
          } catch (_) {}
          // if it's plain text
          if (!res.body.trim().startsWith('{')) {
            return res.body;
          }
        }
      } catch (_) {}

      // fallback to GET
      try {
        String prompt = 'You are GMpro87Ai. ';
        if (fileContent != null && fileName != null) {
          String filePrompt = fileContent.length > 4000
              ? fileContent.substring(0, 4000)
              : fileContent;
          prompt += 'File: $fileName\n$filePrompt\n\n';
        }
        prompt += cleanMessage;
        final encoded = Uri.encodeComponent(prompt);
        final uri = Uri.parse('https://text.pollinations.ai/$encoded?model=$model');
        final res = await http.get(uri).timeout(const Duration(seconds: 90));
        if (res.statusCode == 200 && res.body.trim().isNotEmpty) {
          return res.body;
        }
      } catch (_) {}

      return 'ERROR: failed';
    } catch (e) {
      return 'ERROR: $e';
    }
  }
}
