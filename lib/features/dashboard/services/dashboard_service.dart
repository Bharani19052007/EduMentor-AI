import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetches the user's dashboard stats from the `profiles` table.
  /// Ensure you have a `profiles` table with `id` (uuid), `streak_count` (int), and `overall_rank_percentile` (int).
  Future<Map<String, dynamic>?> getStudentStats(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('streak_count, overall_rank_percentile, first_name, target_exam')
          .eq('id', userId)
          .maybeSingle();
      
      return response;
    } catch (e) {
      print('Error fetching student stats: $e');
      return null;
    }
  }

  /// Calculates the user's performance stats from their test attempts.
  Future<Map<String, dynamic>> getPerformanceStats(String userId) async {
    try {
      final response = await _supabase
          .from('test_attempts')
          .select('score, total_questions')
          .eq('user_id', userId);

      final List<dynamic> attempts = response as List<dynamic>;

      if (attempts.isEmpty) {
        return {
          'testsTaken': 0,
          'avgScore': 0.0,
          'accuracy': 0.0,
        };
      }

      int totalScore = 0;
      int totalQuestions = 0;

      for (var attempt in attempts) {
        totalScore += (attempt['score'] as num?)?.toInt() ?? 0;
        totalQuestions += (attempt['total_questions'] as num?)?.toInt() ?? 0;
      }

      double avgScore = 0;
      if (totalQuestions > 0) {
        avgScore = (totalScore / totalQuestions) * 100;
      }

      return {
        'testsTaken': attempts.length,
        'avgScore': avgScore,
        'accuracy': avgScore, // Assuming accuracy is calculated the same as average score
        'totalScore': totalScore,
      };
    } catch (e) {
      print('Error fetching performance stats: $e');
      return {
        'testsTaken': 0,
        'avgScore': 0.0,
        'accuracy': 0.0,
      };
    }
  }

  /// Calculates and updates the user's study streak based on test attempts.
  Future<void> updateStreak(String userId) async {
    try {
      // Fetch all test attempt dates for the user
      final response = await _supabase
          .from('test_attempts')
          .select('created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final List<dynamic> attempts = response as List<dynamic>;
      if (attempts.isEmpty) return;

      // Extract unique dates (local time)
      Set<String> uniqueDates = {};
      for (var attempt in attempts) {
        if (attempt['created_at'] != null) {
          DateTime date = DateTime.parse(attempt['created_at']).toLocal();
          String dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          uniqueDates.add(dateString);
        }
      }

      List<String> sortedDates = uniqueDates.toList()..sort((a, b) => b.compareTo(a));
      
      int streak = 0;
      DateTime currentDate = DateTime.now();
      String todayStr = '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';
      
      DateTime yesterday = currentDate.subtract(const Duration(days: 1));
      String yesterdayStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      if (!sortedDates.contains(todayStr) && !sortedDates.contains(yesterdayStr)) {
        streak = 0;
      } else {
        DateTime checkDate = sortedDates.contains(todayStr) ? currentDate : yesterday;
        
        while (true) {
          String checkDateStr = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
          if (sortedDates.contains(checkDateStr)) {
            streak++;
            checkDate = checkDate.subtract(const Duration(days: 1));
          } else {
            break;
          }
        }
      }

      // Update the profiles table with the newly calculated streak
      await _supabase.from('profiles').update({'streak_count': streak}).eq('id', userId);
    } catch (e) {
      print('Error updating streak: $e');
    }
  }

  /// Calculates detailed streak stats: current streak, longest streak, and total study days.
  Future<Map<String, dynamic>> getStreakStats(String userId) async {
    try {
      final response = await _supabase
          .from('test_attempts')
          .select('created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final List<dynamic> attempts = response as List<dynamic>;
      if (attempts.isEmpty) {
        return {'currentStreak': 0, 'longestStreak': 0, 'totalStudyDays': 0};
      }

      Set<String> uniqueDates = {};
      for (var attempt in attempts) {
        if (attempt['created_at'] != null) {
          DateTime date = DateTime.parse(attempt['created_at']).toLocal();
          String dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          uniqueDates.add(dateString);
        }
      }

      List<String> sortedDates = uniqueDates.toList()..sort((a, b) => b.compareTo(a));
      int totalStudyDays = sortedDates.length;

      // Calculate longest streak
      int longestStreak = 0;
      int currentBlock = 0;
      DateTime? prevDate;

      for (String dateStr in sortedDates) {
        DateTime date = DateTime.parse(dateStr);
        if (prevDate == null) {
          currentBlock = 1;
        } else {
          int diff = prevDate.difference(date).inDays;
          if (diff == 1) {
            currentBlock++;
          } else {
            if (currentBlock > longestStreak) longestStreak = currentBlock;
            currentBlock = 1;
          }
        }
        prevDate = date;
      }
      if (currentBlock > longestStreak) longestStreak = currentBlock;

      // Calculate current streak
      int currentStreak = 0;
      DateTime currentDate = DateTime.now();
      String todayStr = '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';
      DateTime yesterday = currentDate.subtract(const Duration(days: 1));
      String yesterdayStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      if (!sortedDates.contains(todayStr) && !sortedDates.contains(yesterdayStr)) {
        currentStreak = 0;
      } else {
        DateTime checkDate = sortedDates.contains(todayStr) ? currentDate : yesterday;
        while (true) {
          String checkDateStr = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
          if (sortedDates.contains(checkDateStr)) {
            currentStreak++;
            checkDate = checkDate.subtract(const Duration(days: 1));
          } else {
            break;
          }
        }
      }

      return {
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'totalStudyDays': totalStudyDays,
      };
    } catch (e) {
      print('Error fetching streak stats: $e');
      return {'currentStreak': 0, 'longestStreak': 0, 'totalStudyDays': 0};
    }
  }

  /// Fetches a global leaderboard by calculating total scores from test_attempts.
  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    try {
      // 1. Fetch test attempts
      final response = await _supabase
          .from('test_attempts')
          .select('user_id, score');
          
      final List<dynamic> attempts = response as List<dynamic>;
      
      // 2. Fetch profiles
      final profileResponse = await _supabase
          .from('profiles')
          .select('id, first_name, avatar_url');
          
      final List<dynamic> profilesList = profileResponse as List<dynamic>;
      Map<String, dynamic> profilesMap = {
        for (var p in profilesList) p['id'] as String: p
      };
      
      // 3. Aggregate scores by user
      Map<String, Map<String, dynamic>> userScores = {};
      
      for (var attempt in attempts) {
        String userId = attempt['user_id'];
        int score = (attempt['score'] as num?)?.toInt() ?? 0;
        
        var profile = profilesMap[userId];
        String name = profile != null ? (profile['first_name'] ?? 'User') : 'User';
        String avatar = profile != null ? (profile['avatar_url'] ?? '') : '';
        
        if (userScores.containsKey(userId)) {
          userScores[userId]!['score'] += score;
        } else {
          userScores[userId] = {
            'user_id': userId,
            'name': name,
            'avatar_url': avatar,
            'score': score,
          };
        }
      }
      
      List<Map<String, dynamic>> leaderboard = userScores.values.toList();
      
      // Sort descending by score
      leaderboard.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
      
      return leaderboard;
    } catch (e) {
      print('Error fetching leaderboard: $e');
      return [];
    }
  }
}

