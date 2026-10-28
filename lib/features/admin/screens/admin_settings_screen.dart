import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Settings'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('AI Teacher Configuration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Enable Advanced AI Models'),
            subtitle: const Text('Use GPT-4 instead of GPT-3.5 for tougher doubts'),
            value: true,
            onChanged: (val) {},
            secondary: const Icon(LucideIcons.brain),
          ),
          SwitchListTile(
            title: const Text('Strict Syllabus Mode'),
            subtitle: const Text('Restrict AI answers to only NEET/JEE syllabus'),
            value: true,
            onChanged: (val) {},
            secondary: const Icon(LucideIcons.bookOpen),
          ),
          const Divider(height: 32),
          const Text('App Maintenance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Clear Server Cache'),
            subtitle: const Text('Free up 1.2 GB of temporary storage'),
            leading: const Icon(LucideIcons.trash2),
            trailing: OutlinedButton(onPressed: () {}, child: const Text('Clear')),
          ),
          ListTile(
            title: const Text('System Status'),
            subtitle: const Text('All services operational'),
            leading: const Icon(LucideIcons.activity),
            trailing: const Icon(LucideIcons.checkCircle, color: Colors.green),
          ),
        ],
      ),
    );
  }
}
