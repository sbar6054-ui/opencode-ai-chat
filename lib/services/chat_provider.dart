import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../models/chat.dart';
import '../models/message.dart';
import 'ai_service.dart';

class ChatProvider with ChangeNotifier {
  final AIService _service = AIService();
  List<Chat> _chats = [];
  String? _currentChatId;
  String _selectedModel = 'openai';

  final List<Map<String, String>> _freeModels = [
    {'id': 'openai', 'name': 'GPT (OpenAI) [Vision]'},
    {'id': 'gemini', 'name': 'Google Gemini [Vision]'},
    {'id': 'big-pickle', 'name': 'Big Pickle [Vision]'},
    {'id': 'mistral', 'name': 'Mistral'},
    {'id': 'llama', 'name': 'LLaMA'},
    {'id': 'deepseek', 'name': 'DeepSeek'},
    {'id': 'qwen', 'name': 'Qwen'},
    {'id': 'groq', 'name': 'Groq'},
    {'id': 'claude', 'name': 'Claude'},
    {'id': 'phi', 'name': 'Phi'},
    {'id': 'kimi', 'name': 'Kimi'},
  ];

  final Set<String> _visionModels = {
    'openai',
    'gemini',
    'big-pickle',
  };

  String? _attachedFileName;
  String? _attachedFileContent;
  String? _attachedImagePath;
  String? _attachedImageBase64;

  ChatProvider() {
    _loadData();
  }

  List<Chat> get chats => _chats;
  String? get currentChatId => _currentChatId;
  String get selectedModel => _selectedModel;
  List<Map<String, String>> get freeModels => _freeModels;
  String? get attachedFileName => _attachedFileName;
  String? get attachedFileContent => _attachedFileContent;
  String? get attachedImagePath => _attachedImagePath;
  String? get attachedImageBase64 => _attachedImageBase64;
  bool get supportsVision => _visionModels.contains(_selectedModel);

  Chat? get currentChat {
    if (_currentChatId == null) return null;
    try {
      return _chats.firstWhere((c) => c.id == _currentChatId);
    } catch (e) {
      return null;
    }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedModel = prefs.getString('selected_model') ?? 'openai';
    final chatsJson = prefs.getString('chats');
    if (chatsJson != null) {
      final List decoded = jsonDecode(chatsJson);
      _chats = decoded.map((c) => Chat.fromJson(c)).toList();
    }
    if (_chats.isEmpty) {
      createNewChat();
    } else if (_currentChatId == null) {
      _currentChatId = _chats.first.id;
    }
    notifyListeners();
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_model', _selectedModel);
    final chatsJson = jsonEncode(_chats.map((c) => c.toJson()).toList());
    await prefs.setString('chats', chatsJson);
  }

  void setSelectedModel(String model) {
    _selectedModel = model;
    saveData();
    notifyListeners();
  }

  Future<void> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        try {
          String content = await file.readAsString();
          _attachedFileName = result.files.single.name;
          _attachedFileContent = content;
          notifyListeners();
          return;
        } catch (e) {
        }
      }
      if (result != null && result.files.single.bytes != null) {
        _attachedFileName = result.files.single.name;
        _attachedFileContent = String.fromCharCodes(result.files.single.bytes!);
        notifyListeners();
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image != null) {
        final bytes = await image.readAsBytes();
        _attachedImagePath = image.path;
        _attachedImageBase64 = base64Encode(bytes);
        _attachedFileName = image.name;
        if (!_visionModels.contains(_selectedModel)) {
          _selectedModel = 'openai';
          await saveData();
        }
        notifyListeners();
      }
    } catch (e) {
      print(e);
    }
  }

  void clearAttachment() {
    _attachedFileName = null;
    _attachedFileContent = null;
    _attachedImagePath = null;
    _attachedImageBase64 = null;
    notifyListeners();
  }

  void createNewChat() {
    const uuid = Uuid();
    final chat = Chat(
      id: uuid.v4(),
      title: 'Chat Baru',
      messages: [],
      createdAt: DateTime.now(),
    );
    _chats.insert(0, chat);
    _currentChatId = chat.id;
    saveData();
    notifyListeners();
  }

  void setCurrentChat(String chatId) {
    _currentChatId = chatId;
    notifyListeners();
  }

  Future<void> sendMessage(String content) async {
    if (currentChat == null) return;
    const uuid = Uuid();

    String messageContent = content;
    if (_attachedFileName != null && _attachedImageBase64 == null) {
      messageContent = '[$_attachedFileName] ${content.isEmpty ? "Analisis file ini" : content}';
    } else if (_attachedImageBase64 != null) {
      messageContent = '[Image: $_attachedFileName] ${content.isEmpty ? "Analisis gambar ini" : content}';
      if (!_visionModels.contains(_selectedModel)) {
        _selectedModel = 'openai';
        await saveData();
        notifyListeners();
      }
    }

    final userMessage = Message(
      id: uuid.v4(),
      content: messageContent,
      isUser: true,
      timestamp: DateTime.now(),
    );
    currentChat!.messages.add(userMessage);

    if (currentChat!.title == 'Chat Baru' && (content.isNotEmpty || _attachedFileName != null)) {
      String titleSource = content.isNotEmpty ? content : (_attachedFileName ?? 'Chat');
      currentChat!.title = titleSource.length > 30 ? '${titleSource.substring(0, 30)}...' : titleSource;
    }

    notifyListeners();

    try {
      final response = await _service.sendMessage(
        model: _selectedModel,
        messages: currentChat!.messages,
        fileContent: _attachedFileContent,
        fileName: _attachedFileName,
        imageBase64: _attachedImageBase64,
      );

      final aiMessage = Message(
        id: uuid.v4(),
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );
      currentChat!.messages.add(aiMessage);
      clearAttachment();
      saveData();
      notifyListeners();
    } catch (e) {
      final errorMessage = Message(
        id: uuid.v4(),
        content: 'Error: ${e.toString().replaceAll('Exception: ', '')}\n\nCoba ganti model atau coba lagi ya.',
        isUser: false,
        timestamp: DateTime.now(),
      );
      currentChat!.messages.add(errorMessage);
      clearAttachment();
      saveData();
      notifyListeners();
    }
  }

  void deleteChat(String chatId) {
    _chats.removeWhere((c) => c.id == chatId);
    if (_currentChatId == chatId) {
      if (_chats.isNotEmpty) {
        _currentChatId = _chats.first.id;
      } else {
        createNewChat();
      }
    }
    saveData();
    notifyListeners();
  }
}
