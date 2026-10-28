import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../dashboard/services/dashboard_service.dart';
import '../models/resource_model.dart';
import '../services/resource_service.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  final ResourceService _resourceService = ResourceService();
  final DashboardService _dashboardService = DashboardService();
  late Future<List<ResourceModel>> _resourcesFuture;
  
  String _selectedCategory = 'All';
  bool _showFree = true;
  bool _showPremium = false;
  String _targetExam = 'Both';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    setState(() {
      _resourcesFuture = _fetchFilteredResources();
    });
  }

  Future<List<ResourceModel>> _fetchFilteredResources() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final stats = await _dashboardService.getStudentStats(userId);
        if (stats != null && stats['target_exam'] != null) {
          String examStr = stats['target_exam'].toString().toUpperCase();
          if (examStr.contains('JEE')) {
            _targetExam = 'JEE';
          } else if (examStr.contains('NEET')) {
            _targetExam = 'NEET';
          }
        }
      }
    } catch (e) {
      // Ignore error and proceed with 'Both' if not logged in or no profile
    }

    return _resourceService.getResources(
      category: _selectedCategory,
      showFree: _showFree,
      showPremium: _showPremium,
      targetExam: _targetExam,
    );
  }

  void _setCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _fetchData();
    });
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $urlString')),
        );
      }
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Filter Options', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Show Free Resources'),
                  value: _showFree,
                  onChanged: (val) {
                    setModalState(() => _showFree = val ?? true);
                  },
                ),
                CheckboxListTile(
                  title: const Text('Show Premium Resources'),
                  value: _showPremium,
                  onChanged: (val) {
                    setModalState(() => _showPremium = val ?? false);
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _fetchData(); // Refresh data with new filters
                      });
                    },
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          );
        }
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
        title: const Text('Library', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: IconButton(
              icon: const Icon(LucideIcons.filter),
              onPressed: _showFilterDialog,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search notes, formulas, PDFs...',
                prefixIcon: Icon(LucideIcons.search, color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              children: [
                Text(
                  'Categories',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _CategoryChip(
                        title: 'All', 
                        isSelected: _selectedCategory == 'All', 
                        colorScheme: colorScheme,
                        onTap: () => _setCategory('All'),
                      ),
                      const SizedBox(width: 12),
                      _CategoryChip(
                        title: 'Notes', 
                        isSelected: _selectedCategory == 'Notes', 
                        colorScheme: colorScheme,
                        onTap: () => _setCategory('Notes'),
                      ),
                      const SizedBox(width: 12),
                      _CategoryChip(
                        title: 'Formulas', 
                        isSelected: _selectedCategory == 'Formulas', 
                        colorScheme: colorScheme,
                        onTap: () => _setCategory('Formulas'),
                      ),
                      const SizedBox(width: 12),
                      _CategoryChip(
                        title: 'PYQs', 
                        isSelected: _selectedCategory == 'PYQs', 
                        colorScheme: colorScheme,
                        onTap: () => _setCategory('PYQs'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedCategory == 'All' ? 'Recent Uploads' : '$_selectedCategory Resources',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.refreshCw, size: 20),
                      onPressed: () => setState(() => _fetchData()),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<ResourceModel>>(
                  future: _resourcesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ));
                    }
                    
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error loading resources: ${snapshot.error}'),
                      );
                    }
                    
                    final resources = snapshot.data ?? [];
                    
                    if (resources.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text('No resources found.'),
                        ),
                      );
                    }

                    return Column(
                      children: resources.map((resource) {
                        // Determine icon/colors based on type
                        IconData icon = LucideIcons.fileText;
                        Color color = Colors.blue[600]!;
                        Color bgColor = Colors.blue[50]!;
                        
                        if (resource.type.toLowerCase().contains('pdf') || resource.category == 'Notes') {
                          icon = LucideIcons.fileText;
                          color = Colors.red[600]!;
                          bgColor = Colors.red[50]!;
                        } else if (resource.type.toLowerCase().contains('video')) {
                          icon = LucideIcons.fileVideo;
                          color = Colors.purple[600]!;
                          bgColor = Colors.purple[50]!;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _ResourceItem(
                            icon: icon,
                            iconColor: color,
                            iconBg: bgColor,
                            title: resource.title,
                            subtitle: '${resource.type} • ${resource.fileSizeOrDuration}',
                            isPremium: resource.isPremium,
                            onTap: () => _launchUrl(resource.fileUrl),
                            onDownload: () => _launchUrl(resource.fileUrl),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String title;
  final bool isSelected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.title,
    required this.isSelected,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isSelected ? colorScheme.primary : Colors.grey[200]!),
          boxShadow: isSelected
              ? [BoxShadow(color: colorScheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]
              : [],
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ResourceItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final bool isPremium;
  final VoidCallback onTap;
  final VoidCallback onDownload;

  const _ResourceItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.isPremium = false,
    required this.onTap,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      if (isPremium)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(LucideIcons.download, color: Colors.grey[400]),
              onPressed: onDownload,
            ),
          ],
        ),
      ),
    );
  }
}

