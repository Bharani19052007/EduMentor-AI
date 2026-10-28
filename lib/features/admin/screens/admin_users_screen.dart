import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/admin_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final AdminService _adminService = AdminService();
  late Future<List<Map<String, dynamic>>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  void _fetchUsers() {
    setState(() {
      _usersFuture = _adminService.getUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.alertCircle, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('Error loading users:\n${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchUsers,
                    child: const Text('Retry'),
                  ),
                ],
              )
            );
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final name = user['name'] ?? 'Unknown User';
              final email = user['email'] ?? 'No email';
              final prepPath = (user['preparation_path'] ?? 'student').toString().toUpperCase();
              final role = user['role'] ?? 'student';
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                    child: Icon(LucideIcons.user, color: colorScheme.primary),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('$email\n$prepPath Aspirant'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Active', style: TextStyle(color: Colors.green, fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton(
                        onSelected: (value) {
                          if (value == 'view') {
                            _showUserProfile(context, user);
                          } else if (value == 'ban') {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Suspend feature coming soon')));
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'view', child: Text('View Profile')),
                          const PopupMenuItem(value: 'ban', child: Text('Suspend Account', style: TextStyle(color: Colors.orange))),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      ),
    );
  }

  void _showUserProfile(BuildContext context, Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    child: Icon(LucideIcons.user, size: 30, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user['name'] ?? 'Unknown User', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        Text(user['email'] ?? 'No email', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _buildProfileDetailRow('Preparation Path', (user['preparation_path'] ?? 'N/A').toString().toUpperCase()),
              const SizedBox(height: 12),
              _buildProfileDetailRow('Account Created', _formatDate(user['created_at'])),
              const SizedBox(height: 12),
              _buildProfileDetailRow('User ID', user['id'].toString()),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
