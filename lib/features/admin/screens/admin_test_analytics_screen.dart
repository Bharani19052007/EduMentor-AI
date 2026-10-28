import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/admin_service.dart';

class AdminTestAnalyticsScreen extends StatefulWidget {
  final String testId;
  final String testTitle;

  const AdminTestAnalyticsScreen({
    super.key,
    required this.testId,
    required this.testTitle,
  });

  @override
  State<AdminTestAnalyticsScreen> createState() => _AdminTestAnalyticsScreenState();
}

class _AdminTestAnalyticsScreenState extends State<AdminTestAnalyticsScreen> {
  final AdminService _adminService = AdminService();
  late Future<List<Map<String, dynamic>>> _analyticsFuture;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  void _fetchAnalytics() {
    setState(() {
      _analyticsFuture = _adminService.getTestAnalytics(widget.testId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Analytics'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _analyticsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.alertCircle, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text('Could not load analytics. Please run the SQL script to create test_attempts.\nError: ${snapshot.error}', textAlign: TextAlign.center, style: TextStyle(color: Colors.red[800])),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _fetchAnalytics, child: const Text('Retry')),
                  ],
                ),
              ),
            );
          }

          final attempts = snapshot.data ?? [];
          
          // Calculate summary stats
          final totalAttended = attempts.length;
          double averageScore = 0;
          int highestScore = 0;
          
          if (totalAttended > 0) {
            int totalScoreSum = 0;
            for (var attempt in attempts) {
              final rawScore = attempt['score'] as int? ?? 0;
              final totalQ = attempt['total_questions'] as int? ?? 1;
              final percentage = totalQ > 0 ? (rawScore / totalQ * 100).round() : 0;
              
              totalScoreSum += percentage;
              if (percentage > highestScore) {
                highestScore = percentage;
              }
            }
            averageScore = totalScoreSum / totalAttended;
          }

          return RefreshIndicator(
            onRefresh: () async => _fetchAnalytics(),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(24.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Text(
                        widget.testTitle,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.15,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildSummaryCard(context, 'Total Attended', '$totalAttended Students', LucideIcons.users, Colors.blue),
                          _buildSummaryCard(context, 'Average Score', '${averageScore.toStringAsFixed(1)}%', LucideIcons.barChart3, Colors.orange),
                          _buildSummaryCard(context, 'Highest Score', '$highestScore%', LucideIcons.trophy, Colors.green),
                          _buildSummaryCard(context, 'Completion Rate', '100%', LucideIcons.checkCircle, Colors.purple),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      Text(
                        'Student Performances',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      
                      if (attempts.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('No students have taken this test yet.'),
                        ),
                    ]),
                  ),
                ),
                if (attempts.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final attempt = attempts[index];
                          final name = attempt['student_name'] ?? 'Unknown Student';
                          final email = attempt['student_email'] ?? '';
                          final rawScore = attempt['score'] ?? 0;
                          final totalQ = attempt['total_questions'] ?? 1;
                          final percentage = totalQ > 0 ? (rawScore / totalQ * 100).round() : 0;
                          final timeTaken = attempt['time_taken_seconds'] ?? 0;
                          final mins = timeTaken ~/ 60;
                          
                          // Rank
                          final rank = index + 1;
                          Color rankColor = Colors.grey;
                          if (rank == 1) rankColor = Colors.amber;
                          if (rank == 2) rankColor = Colors.grey.shade400;
                          if (rank == 3) rankColor = Colors.brown.shade300;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: rank <= 3 ? rankColor.withValues(alpha: 0.2) : theme.colorScheme.primary.withValues(alpha: 0.1),
                                child: Text('#$rank', style: TextStyle(color: rank <= 3 ? rankColor : theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                              ),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('$email\nTime taken: $mins mins'),
                              isThreeLine: true,
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('$percentage%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                                  Text('$rawScore/$totalQ Correct', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: attempts.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Text(
            title,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }
}
