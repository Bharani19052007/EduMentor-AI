import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../mocktests/models/mock_test_model.dart';
import '../../mocktests/services/mock_test_service.dart';

class AdminTestsScreen extends StatefulWidget {
  const AdminTestsScreen({super.key});

  @override
  State<AdminTestsScreen> createState() => _AdminTestsScreenState();
}

class _AdminTestsScreenState extends State<AdminTestsScreen> {
  final MockTestService _mockTestService = MockTestService();
  late Future<List<MockTest>> _testsFuture;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    setState(() {
      _testsFuture = _mockTestService.getMockTests();
    });
  }

  void _showAnalyticsDialog(MockTest test) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Analytics: ${test.title}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const ListTile(
              leading: Icon(LucideIcons.users, color: Colors.blue),
              title: Text('Total Attempts'),
              trailing: Text('120', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), // Dummy stat
            ),
            const ListTile(
              leading: Icon(LucideIcons.target, color: Colors.green),
              title: Text('Average Score'),
              trailing: Text('75%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), // Dummy stat
            ),
            ListTile(
              leading: const Icon(LucideIcons.clock, color: Colors.orange),
              title: const Text('Duration'),
              trailing: Text('${test.durationMins}m', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Close Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }



  void _confirmDelete(MockTest test) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Test'),
        content: Text('Are you sure you want to delete "${test.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              dialogContext.pop(); // Close dialog
              try {
                await _mockTestService.deleteMockTest(test.id);
                if (mounted) { // Check State's mounted, not dialog context
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test deleted successfully')));
                  _fetchData(); // Refresh list
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Mock Tests'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            tooltip: 'Create Test',
            onPressed: () async {
              await context.push('/admin/tests/create');
              if (mounted) {
                _fetchData();
              }
            },
          ),
        ],
      ),

      body: FutureBuilder<List<MockTest>>(
        future: _testsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading tests: ${snapshot.error}'));
          }

          final tests = snapshot.data ?? [];

          if (tests.isEmpty) {
            return const Center(child: Text('No mock tests found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tests.length,
            itemBuilder: (context, index) {
              final test = tests[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              test.title,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: test.isRecommended ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              test.isRecommended ? 'Recommended' : 'Standard', 
                              style: TextStyle(
                                color: test.isRecommended ? Colors.green : Colors.grey[600], 
                                fontSize: 12
                              )
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(LucideIcons.book, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(test.category, style: TextStyle(color: Colors.grey[600])),
                          const SizedBox(width: 16),
                          Icon(LucideIcons.clock, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text('${test.durationMins} mins', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          PopupMenuButton(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                await context.push('/admin/tests/edit/${test.id}');
                                if (mounted) {
                                  _fetchData();
                                }
                              } else if (value == 'analytics') {
                                context.push(
                                  '/admin/tests/analytics',
                                  extra: {
                                    'testId': test.id,
                                    'testTitle': test.title,
                                  },
                                );
                              } else if (value == 'delete') {
                                _confirmDelete(test);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'edit', child: Text('Edit Test')),
                              const PopupMenuItem(value: 'analytics', child: Text('View Analytics')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete Test', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        ],
                      )
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
}
