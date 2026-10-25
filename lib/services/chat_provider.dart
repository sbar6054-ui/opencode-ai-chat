import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/chat.dart';
import '../models/message.dart';
import 'openrouter_service.dart';

class ChatProvider with ChangeNotifier {
  final OpenRouterService _service = OpenRouterService();
  List<Chat> _chats = [];
  String? _currentChatId;
  String _apiKey = '';
  String _selectedModel = 'google/gemma-2-9b-it:free';

  final List<Map<String, String>> _freeModels = [
    {'id': 'google/gemma-2-9b-it:free', 'name': 'Google Gemma 2 9B'},
    {'id': 'google/gemma-2-27b-it:free', 'name': 'Google Gemma 2 27B'},
    {'id': 'meta-llama/llama-3.1-8b-instruct:free', 'name': 'Llama 3.1 8B'},
    {'id': 'meta-llama/llama-3.2-3b-instruct:free', 'name': 'Llama 3.2 3B'},
    {'id': 'mistralai/mistral-7b-instruct:free', 'name': 'Mistral 7B'},
    {'id': 'microsoft/phi-3-mini-128k-instruct:free', 'name': 'Phi-3 Mini'},
    {'id': 'huggingfaceh4/zephyr-7b-beta:free', 'name': 'Zephyr 7B'},
    {'id': 'qwen/qwen2-7b-instruct:free', 'name': 'Qwen 2 7B'},
    {'id': 'deepseek/deepseek-chat-v3-0324:free', 'name': 'DeepSeek Chat V3'},
  ];

  ChatProvider() {
    _loadData();
  }

  List<Chat> get chats => _chats;
  String? get currentChatId => _currentChatId;
  String get apiKey => _apiKey;
  String get selectedModel => _selectedModel;
  List<Map<String, String>> get freeModels => _freeModels;

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
    _apiKey = prefs.getString('api_key') ?? '';
    _selectedModel = prefs.getString('selected_model') ?? 'google/gemma-2-9b-it:free';
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
    await prefs.setString('api_key', _apiKey);
    await prefs.setString('selected_model', _selectedModel);
    final chatsJson = jsonEncode(_chats.map((c) => c.toJson()).toList());
    await prefs.setString('chats', chatsJson);
  }

  void setApiKey(String key) {
    _apiKey = key;
    saveData();
    notifyListeners();
  }

  void setSelectedModel(String model) {
    _selectedModel = model;
    saveData();
    notifyListeners();
  }

  void createNewChat() {
    const uuid = Uuid();
    final chat = Chat(
      id: uuid.v4(),
      title: 'New Chat',
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

    final userMessage = Message(
      id: uuid.v4(),
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );
    currentChat!.messages.add(userMessage);

    if (currentChat!.title == 'New Chat' && currentChat!.messages.length == 1) {
      currentChat!.title = content.length > 30 ? '${content.substring(0, 30)}...' : content;
    }

    notifyListeners();

    if (_apiKey.isEmpty) {
      final errorMessage = Message(
        id: uuid.v4(),
        content: 'Error: API Key belum diisi. Silahkan isi API Key OpenRouter kamu di pengaturan.',
        isUser: false,
        timestamp: DateTime.now(),
      );
      currentChat!.messages.add(errorMessage);
      saveData();
      notifyListeners();
      return;
    }

    try {
      final response = await _service.sendMessage(
        apiKey: _apiKey,
        model: _selectedModel,
        messages: currentChat!.messages,
      );

      final aiMessage = Message(
        id: uuid.v4(),
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );
      currentChat!.messages.add(aiMessage);
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
