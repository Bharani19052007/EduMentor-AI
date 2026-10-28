import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/auth_service.dart';
import '../services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isLoggingOut = false;
  String _name = 'John Doe';
  String _exam = 'NEET Aspirant';
  String _grade = '12th Grade';
  bool _notificationsEnabled = true;
  bool _darkMode = false;
  String? _avatarUrl;
  File? _profileImageFile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final data = await _profileService.getProfile(user.id);
      if (data != null && mounted) {
        setState(() {
          _name = data['first_name'] ?? _name;
          _exam = data['target_exam'] ?? _exam;
          _grade = data['grade'] ?? _grade;
          _notificationsEnabled = data['notifications_enabled'] ?? _notificationsEnabled;
          _darkMode = data['dark_mode'] ?? _darkMode;
          _avatarUrl = data['avatar_url'];
          _isLoading = false;
        });
        return;
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfileData(Map<String, dynamic> updates) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await _profileService.updateProfile(user.id, updates);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update profile.')),
          );
        }
      }
    }
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    try {
      await _authService.signOut();
      if (!mounted) return;
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log out: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      // Compress and resize the image before loading into memory to prevent OOM crash
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 20, // Lower quality for smaller file size (faster upload)
        maxWidth: 256, // Smaller dimension for instant upload
        maxHeight: 256,
      );
      
      if (image != null && mounted) {
        setState(() {
          _profileImageFile = File(image.path);
        });
        
        final user = Supabase.instance.client.auth.currentUser;
        
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: User not logged in')));
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading profile photo...')),
        );
        
        try {
          final imageUrl = await _profileService.uploadProfileImage(
            user.id,
            _profileImageFile!,
          );
          
          if (imageUrl != null && mounted) {
            setState(() {
              _avatarUrl = imageUrl;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile photo updated successfully!')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to upload image: $e')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _showPersonalDetailsDialog() {
    final nameController = TextEditingController(text: _name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Personal Details'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _name = nameController.text);
              _updateProfileData({'first_name': _name});
              context.pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showTargetExamDialog() {
    String tempExam = _exam;
    String tempGrade = _grade;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Target Exam & Subject', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: tempExam,
                decoration: const InputDecoration(labelText: 'Target Exam', border: OutlineInputBorder()),
                items: ['NEET Aspirant', 'JEE Mains Aspirant', 'JEE Advanced Aspirant'].map((e) {
                  return DropdownMenuItem(value: e, child: Text(e));
                }).toList(),
                onChanged: (val) => setSheetState(() => tempExam = val!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: tempGrade,
                decoration: const InputDecoration(labelText: 'Grade', border: OutlineInputBorder()),
                items: ['11th Grade', '12th Grade', 'Dropper'].map((e) {
                  return DropdownMenuItem(value: e, child: Text(e));
                }).toList(),
                onChanged: (val) => setSheetState(() => tempGrade = val!),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _exam = tempExam;
                      _grade = tempGrade;
                    });
                    _updateProfileData({
                      'target_exam': _exam,
                      'grade': _grade,
                    });
                    context.pop();
                  },
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.crown, color: Colors.orange),
            SizedBox(width: 8),
            Text('Pro Plan'),
          ],
        ),
        content: const Text('You are currently on the EduMentor Pro Plan.\n\nYour subscription is active until Dec 2026.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              context.pop();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Redirecting to billing portal...')));
            },
            child: const Text('Manage Billing'),
          ),
        ],
      ),
    );
  }

  void _showAppSettingsDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('App Settings', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Push Notifications'),
                subtitle: const Text('Receive mock test reminders'),
                value: _notificationsEnabled,
                onChanged: (val) {
                  setSheetState(() => _notificationsEnabled = val);
                  setState(() => _notificationsEnabled = val);
                  _updateProfileData({'notifications_enabled': val});
                },
              ),
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Toggle app theme'),
                value: _darkMode,
                onChanged: (val) {
                  setSheetState(() => _darkMode = val);
                  setState(() => _darkMode = val);
                  _updateProfileData({'dark_mode': val});
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Theme settings applied.')));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Profile Header
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue[100],
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    image: DecorationImage(
                      image: _profileImageFile != null
                          ? FileImage(_profileImageFile!) as ImageProvider
                          : (_avatarUrl != null
                              ? NetworkImage(_avatarUrl!)
                              : const NetworkImage('https://api.dicebear.com/7.x/avataaars/png?seed=John')),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              GestureDetector(
                onTap: _pickProfileImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(LucideIcons.edit2, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _name,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '$_exam • $_grade',
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 32),

            // Settings List
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  _SettingsTile(
                    icon: LucideIcons.user,
                    iconColor: Colors.blue[600]!,
                    iconBg: Colors.blue[50]!,
                    title: 'Personal Details',
                    onTap: _showPersonalDetailsDialog,
                  ),
                  Divider(color: Colors.grey[100], height: 1),
                  _SettingsTile(
                    icon: LucideIcons.target,
                    iconColor: Colors.green[600]!,
                    iconBg: Colors.green[50]!,
                    title: 'Target Exam & Subject',
                    onTap: _showTargetExamDialog,
                  ),
                  Divider(color: Colors.grey[100], height: 1),
                  _SettingsTile(
                    icon: LucideIcons.creditCard,
                    iconColor: Colors.purple[600]!,
                    iconBg: Colors.purple[50]!,
                    title: 'Subscription',
                    onTap: _showSubscriptionDialog,
                  ),
                  Divider(color: Colors.grey[100], height: 1),
                  _SettingsTile(
                    icon: LucideIcons.settings,
                    iconColor: Colors.orange[600]!,
                    iconBg: Colors.orange[50]!,
                    title: 'App Settings',
                    onTap: _showAppSettingsDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoggingOut ? null : _handleLogout,
                icon: _isLoggingOut
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                      )
                    : const Icon(LucideIcons.logOut, color: Colors.red),
                label: Text(
                  _isLoggingOut ? 'Logging Out...' : 'Log Out',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      trailing: Icon(LucideIcons.chevronRight, color: Colors.grey[400]),
    );
  }
}

