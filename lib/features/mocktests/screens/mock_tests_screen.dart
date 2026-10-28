import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/mock_test_model.dart';
import '../services/mock_test_service.dart';
import 'subject_tests_screen.dart';

class MockTestsScreen extends StatefulWidget {
  const MockTestsScreen({super.key});

  @override
  State<MockTestsScreen> createState() => _MockTestsScreenState();
}

class _MockTestsScreenState extends State<MockTestsScreen> {
  final MockTestService _mockTestService = MockTestService();
  late Future<List<MockTest>> _recommendedTestsFuture;
  late Future<List<MockTest>> _allTestsFuture;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    _recommendedTestsFuture = _mockTestService.getRecommendedTests();
    _allTestsFuture = _mockTestService.getMockTests();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: const EdgeInsets.only(left: 24, bottom: 16, right: 24, top: 60),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Practice',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 32),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Test your knowledge with mock exams.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Recommended For You',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.refreshCw, size: 20),
                        onPressed: () {
                          setState(() {
                            _fetchData();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Recommended Tests FutureBuilder
                  FutureBuilder<List<MockTest>>(
                    future: _recommendedTestsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ));
                      }
                      
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error loading tests: ${snapshot.error}'),
                        );
                      }
                      
                      final tests = snapshot.data ?? [];
                      
                      if (tests.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text('No recommended tests found.'),
                          ),
                        );
                      }
                      
                      // For now, just show the first recommended test in the big card
                      final test = tests.first;
                      
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)], // Green gradients
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        test.category.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        test.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          height: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(LucideIcons.timer, color: Colors.white, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${test.durationMins} Mins',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              test.description,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                context.push('/test/${test.id}/take');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF059669),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              child: const Text('Start Test', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  Text(
                    'Subject Wise Tests',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // All Tests FutureBuilder (Grouped by Category)
                  FutureBuilder<List<MockTest>>(
                    future: _allTestsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ));
                      }
                      
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error loading tests: ${snapshot.error}'),
                        );
                      }
                      
                      final tests = snapshot.data ?? [];
                      
                      if (tests.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text('No tests found.'),
                          ),
                        );
                      }
                      
                      // Group tests by category
                      final Map<String, List<MockTest>> grouped = {};
                      for (var test in tests) {
                        if (!test.isRecommended) {
                          if (!grouped.containsKey(test.category)) {
                            grouped[test.category] = [];
                          }
                          grouped[test.category]!.add(test);
                        }
                      }
                      
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: grouped.entries.map((entry) {
                          final category = entry.key;
                          final count = entry.value.length;
                          
                          // Determine icon/colors based on category
                          IconData icon = LucideIcons.bookOpen;
                          Color color = Colors.blue[600]!;
                          Color bgColor = Colors.blue[50]!;
                          
                          if (category.toLowerCase().contains('physics')) {
                            icon = LucideIcons.atom;
                            color = Colors.blue[600]!;
                            bgColor = Colors.blue[50]!;
                          } else if (category.toLowerCase().contains('chemistry')) {
                            icon = LucideIcons.testTube;
                            color = Colors.purple[600]!;
                            bgColor = Colors.purple[50]!;
                          } else if (category.toLowerCase().contains('bio')) {
                            icon = LucideIcons.microscope;
                            color = Colors.green[600]!;
                            bgColor = Colors.green[50]!;
                          }
                          
                          return SizedBox(
                            width: (MediaQuery.of(context).size.width - 48 - 16) / 2, // Half width minus padding and spacing
                            child: _SubjectCard(
                              icon: icon,
                              iconColor: color,
                              iconBgColor: bgColor,
                              title: category,
                              subtitle: '$count Tests',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SubjectTestsScreen(category: category),
                                  ),
                                );
                              },
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
          ),
        ],
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SubjectCard({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

