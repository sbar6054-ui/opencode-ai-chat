import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import '../models/chat.dart';
import '../models/message.dart';
import 'ai_service.dart';

class ChatProvider with ChangeNotifier {
  final AIService _service = AIService();
  List<Chat> _chats = [];
  String? _currentChatId;
  String _selectedModel = 'openai';

  final List<Map<String, String>> _freeModels = [
    {'id': 'openai', 'name': 'GPT'},
    {'id': 'mistral', 'name': 'Mistral'},
    {'id': 'llama', 'name': 'Llama'},
    {'id': 'gemini', 'name': 'Gemini'},
    {'id': 'flux', 'name': 'Flux'},
  ];

  String? _attachedFileName;
  String? _attachedFileContent;

  ChatProvider() {
    _loadData();
  }

  List<Chat> get chats => _chats;
  String? get currentChatId => _currentChatId;
  String get selectedModel => _selectedModel;
  List<Map<String, String>> get freeModels => _freeModels;
  String? get attachedFileName => _attachedFileName;
  String? get attachedFileContent => _attachedFileContent;

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
        String content = await file.readAsString();
        _attachedFileName = result.files.single.name;
        _attachedFileContent = content;
        notifyListeners();
      }
    } catch (e) {
      // Try to read as bytes/text anyway
      try {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.any,
        );
        if (result != null && result.files.single.bytes != null) {
          _attachedFileName = result.files.single.name;
          _attachedFileContent = String.fromCharCodes(result.files.single.bytes!);
          notifyListeners();
        }
      } catch (e2) {
        print(e2);
      }
    }
  }

  void clearAttachment() {
    _attachedFileName = null;
    _attachedFileContent = null;
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
    if (_attachedFileName != null) {
      messageContent = '[$_attachedFileName]\n$content';
    }

    final userMessage = Message(
      id: uuid.v4(),
      content: messageContent,
      isUser: true,
      timestamp: DateTime.now(),
    );
    currentChat!.messages.add(userMessage);

    if (currentChat!.title == 'Chat Baru' && currentChat!.messages.length == 1) {
      currentChat!.title = content.length > 30 ? '${content.substring(0, 30)}...' : content;
    }

    notifyListeners();

    try {
      final response = await _service.sendMessage(
        model: _selectedModel,
        messages: currentChat!.messages,
        fileContent: _attachedFileContent,
        fileName: _attachedFileName,
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
        content: 'Error: $e',
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
