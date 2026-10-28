import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/mock_test_model.dart';
import '../services/mock_test_service.dart';

class SubjectTestsScreen extends StatefulWidget {
  final String category;

  const SubjectTestsScreen({super.key, required this.category});

  @override
  State<SubjectTestsScreen> createState() => _SubjectTestsScreenState();
}

class _SubjectTestsScreenState extends State<SubjectTestsScreen> {
  final MockTestService _mockTestService = MockTestService();
  late Future<List<MockTest>> _testsFuture;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    _testsFuture = _mockTestService.getMockTests().then((allTests) {
      return allTests.where((test) => test.category == widget.category).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('${widget.category} Tests'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
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
            return const Center(child: Text('No tests found in this category.'));
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tests.length,
            itemBuilder: (context, index) {
              final test = tests[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(LucideIcons.fileText, color: theme.colorScheme.primary),
                  ),
                  title: Text(
                    test.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(test.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(LucideIcons.timer, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('${test.durationMins} Mins', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      context.push('/test/${test.id}/take');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Start'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
