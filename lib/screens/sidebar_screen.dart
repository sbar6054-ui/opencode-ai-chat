import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/chat_provider.dart';

class SidebarScreen extends StatelessWidget {
  const SidebarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChatProvider>(context);
    
    return Drawer(
      backgroundColor: const Color(0xFF171717),
      child: Column(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton.icon(
                onPressed: () {
                  provider.createNewChat();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New chat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: provider.chats.length,
              itemBuilder: (context, index) {
                final chat = provider.chats[index];
                final isSelected = chat.id == provider.currentChatId;
                return Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF2A2A2A) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.white70),
                    title: Text(
                      chat.title,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      provider.setCurrentChat(chat.id);
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
          ),
          const Divider(color: Color(0xFF2A2A2A)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'GMpro87Ai',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
