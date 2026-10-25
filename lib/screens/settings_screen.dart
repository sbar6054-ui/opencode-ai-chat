import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/chat_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChatProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.model_training, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Pilih Model AI (Gratis)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                ...provider.freeModels.map((model) {
                  final isSelected = provider.selectedModel == model['id'];
                  return ListTile(
                    title: Text(model['name']!),
                    leading: Radio<String>(
                      value: model['id']!,
                      groupValue: provider.selectedModel,
                      onChanged: (value) {
                        provider.setSelectedModel(value!);
                      },
                    ),
                    selected: isSelected,
                    onTap: () {
                      provider.setSelectedModel(model['id']!);
                    },
                  );
                }).toList(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Tentang GMpro87Ai',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('GMpro87Ai v1.0.0'),
                  const SizedBox(height: 4),
                  const Text('AI Chat Gratis Tanpa API Key'),
                  const SizedBox(height: 4),
                  const Text('Bisa baca & analisis semua jenis file'),
                  const SizedBox(height: 4),
                  const Text('Powered by Pollinations AI'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
