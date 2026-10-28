import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/services/auth_service.dart';
import '../services/admin_service.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final AdminService _adminService = AdminService();
  final AuthService _authService = AuthService();
  late Future<Map<String, dynamic>> _statsFuture;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  void _fetchStats() {
    setState(() {
      _statsFuture = _adminService.getDashboardStats();
    });
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          _isLoggingOut
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(LucideIcons.logOut),
                  tooltip: 'Log Out',
                  onPressed: _handleLogout,
                ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _fetchStats(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, Administrator',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your students, content, and system analytics.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                
                FutureBuilder<Map<String, dynamic>>(
                  future: _statsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    
                    if (snapshot.hasError) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Could not load analytics. Did you run the SQL script?',
                          style: TextStyle(color: Colors.red[800]),
                        ),
                      );
                    }

                    final stats = snapshot.data ?? {};
                    
                    return GridView.extent(
                      maxCrossAxisExtent: 250,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.6,
                      children: [
                        _buildStatCard(
                          context, 
                          title: 'Total Students', 
                          value: '${stats['totalStudents'] ?? 0}', 
                          icon: LucideIcons.users, 
                          color: Colors.blue,
                        ),
                        _buildStatCard(
                          context, 
                          title: 'Active Tests', 
                          value: '${stats['activeTests'] ?? 0}', 
                          icon: LucideIcons.fileText, 
                          color: Colors.green,
                        ),
                        _buildStatCard(
                          context, 
                          title: 'Library Resources', 
                          value: '${stats['totalResources'] ?? 0}', 
                          icon: LucideIcons.bookOpen, 
                          color: Colors.purple,
                        ),
                      ],
                    );
                  }
                ),
                
                const SizedBox(height: 32),
                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildActionTile(
                  context,
                  title: 'Manage Users',
                  subtitle: 'View and manage student accounts',
                  icon: LucideIcons.users,
                  onTap: () => context.push('/admin/users'),
                ),
                const SizedBox(height: 12),
                _buildActionTile(
                  context,
                  title: 'Manage Content',
                  subtitle: 'Upload new PDFs, videos, and study materials',
                  icon: LucideIcons.folderUp,
                  onTap: () => context.push('/admin/content'),
                ),
                const SizedBox(height: 12),
                _buildActionTile(
                  context,
                  title: 'Review Mock Tests',
                  subtitle: 'Analyze student performance and edit questions',
                  icon: LucideIcons.clipboardCheck,
                  onTap: () => context.push('/admin/tests'),
                ),
                const SizedBox(height: 12),
                _buildActionTile(
                  context,
                  title: 'System Settings',
                  subtitle: 'Configure AI models and app preferences',
                  icon: LucideIcons.settings,
                  onTap: () => context.push('/admin/settings'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, {required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        trailing: const Icon(LucideIcons.chevronRight, size: 20),
        onTap: onTap,
      ),
    );
  }
}
