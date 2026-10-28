import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/dashboard_service.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  final DashboardService _dashboardService = DashboardService();
  bool _isLoading = true;
  int _testsTaken = 0;
  double _avgScore = 0.0;
  double _accuracy = 0.0;
  int _totalScore = 0;
  int _overallRankPercentile = 100;
  List<Map<String, dynamic>> _leaderboard = [];
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadPerformanceData();
  }

  Future<void> _loadPerformanceData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      final stats = await _dashboardService.getPerformanceStats(userId);
      final profileStats = await _dashboardService.getStudentStats(userId);
      final leaderboardData = await _dashboardService.getLeaderboard();
      if (mounted) {
        setState(() {
          _currentUserId = userId;
          _testsTaken = stats['testsTaken'] as int;
          _avgScore = stats['avgScore'] as double;
          _accuracy = stats['accuracy'] as double;
          _totalScore = stats['totalScore'] as int;
          _overallRankPercentile = (profileStats?['overall_rank_percentile'] as num?)?.toInt() ?? 100;
          _leaderboard = leaderboardData;
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
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('Performance', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        child: Column(
          children: [
            // Header Stats
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.trophy, color: Colors.green, size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Top $_overallRankPercentile% Performer',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Based on your total score, keep pushing forward!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatBadge(title: 'Tests Taken', value: _testsTaken.toString(), color: Colors.blue),
                      _StatBadge(title: 'Avg Score', value: '${_avgScore.toStringAsFixed(1)}%', color: Colors.purple),
                      _StatBadge(title: 'Accuracy', value: '${_accuracy.toStringAsFixed(1)}%', color: Colors.orange),
                    ],
                  ),
                ],
              ),
            ),
            
            // Leaderboard
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Global Leaderboard',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'This Week',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: _leaderboard.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(child: Text('No leaderboard data yet')),
                          )
                        : Column(
                            children: [
                              for (int i = 0; i < _leaderboard.length; i++) ...[
                                _LeaderboardRow(
                                  rank: i + 1,
                                  name: _leaderboard[i]['user_id'] == _currentUserId 
                                      ? 'You' 
                                      : _leaderboard[i]['name'],
                                  score: _leaderboard[i]['score'].toString(),
                                  isMe: _leaderboard[i]['user_id'] == _currentUserId,
                                ),
                                if (i < _leaderboard.length - 1) const Divider(height: 1),
                              ]
                            ],
                          ),
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

class _StatBadge extends StatelessWidget {
  final String title;
  final String value;
  final MaterialColor color;

  const _StatBadge({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color[700],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final String name;
  final String score;
  final bool isMe;

  const _LeaderboardRow({
    required this.rank,
    required this.name,
    required this.score,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    Color bgColor = isMe ? colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent;
    
    Widget rankWidget;
    if (rank == 1) {
      rankWidget = const Icon(LucideIcons.medal, color: Colors.amber);
    } else if (rank == 2) {
      rankWidget = Icon(LucideIcons.medal, color: Colors.grey[400]);
    } else if (rank == 3) {
      rankWidget = const Icon(LucideIcons.medal, color: Colors.deepOrange);
    } else {
      rankWidget = Text(
        '#$rank',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          fontSize: 16,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(isMe ? 8 : 0),
      ),
      child: Row(
        children: [
          SizedBox(width: 40, child: Center(child: rankWidget)),
          const SizedBox(width: 16),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
              image: DecorationImage(
                image: NetworkImage('https://api.dicebear.com/7.x/avataaars/png?seed=$name'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontWeight: isMe ? FontWeight.bold : FontWeight.w600,
                fontSize: 16,
                color: isMe ? colorScheme.primary : Colors.black87,
              ),
            ),
          ),
          Text(
            score,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
