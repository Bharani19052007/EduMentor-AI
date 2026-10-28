import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/dashboard_service.dart';

class StudyStreakScreen extends StatefulWidget {
  const StudyStreakScreen({super.key});

  @override
  State<StudyStreakScreen> createState() => _StudyStreakScreenState();
}

class _StudyStreakScreenState extends State<StudyStreakScreen> {
  final DashboardService _dashboardService = DashboardService();
  final String? _userId = Supabase.instance.client.auth.currentUser?.id;
  
  int _streakCount = 0;
  int _longestStreak = 0;
  int _totalStudyDays = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStreak();
  }

  Future<void> _loadStreak() async {
    if (_userId != null) {
      final stats = await _dashboardService.getStreakStats(_userId!);
      if (mounted) {
        setState(() {
          _streakCount = (stats['currentStreak'] as num?)?.toInt() ?? 0;
          _longestStreak = (stats['longestStreak'] as num?)?.toInt() ?? 0;
          _totalStudyDays = (stats['totalStudyDays'] as num?)?.toInt() ?? 0;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('Study Streak', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Center Hero
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange[50],
                border: Border.all(color: Colors.orange[200]!, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(LucideIcons.flame, color: Colors.orange, size: 80),
                  const SizedBox(height: 8),
                  Text(
                    '$_streakCount',
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                  Text(
                    'DAYS',
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'You\'re on fire! 🔥',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete at least one lesson or mock test every day to keep your streak alive.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 40),

            // Stats
            Row(
              children: [
                Expanded(
                  child: _StreakStat(
                    title: 'Longest Streak',
                    value: '$_longestStreak Days',
                    icon: LucideIcons.trendingUp,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StreakStat(
                    title: 'Total Study Days',
                    value: '$_totalStudyDays Days',
                    icon: LucideIcons.calendar,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Heatmap mockup
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This Month',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: 30, // Mock 30 days
                    itemBuilder: (context, index) {
                      // Simple dynamic mock for heatmap based on actual streak
                      bool isFuture = index > (_streakCount > 0 ? _streakCount - 1 : 0);
                      bool isActive = index <= (_streakCount > 0 ? _streakCount - 1 : 0); 
                      
                      Color boxColor;
                      if (isFuture) {
                        boxColor = Colors.grey[100]!;
                      } else if (isActive) {
                        boxColor = Colors.orange[400]!;
                      } else {
                        boxColor = Colors.orange[100]!;
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: boxColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakStat extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final MaterialColor color;

  const _StreakStat({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color[600], size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );
  }
}
