import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  final SupabaseClient _supabase = Supabase.instance.client;
  // Fetch Dashboard Analytics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      // 1. Get Total Students (via RPC)
      final studentCount = await _supabase.rpc('get_student_count');
      
      // 2. Get Active Tests Count
      final testsResponse = await _supabase.from('mock_tests').select('id');
      final testsCount = (testsResponse as List).length;

      // 3. Get Total Resources
      final resourcesResponse = await _supabase.from('learning_resources').select('id');
      final resourcesCount = (resourcesResponse as List).length;

      return {
        'totalStudents': studentCount ?? 0,
        'activeTests': testsCount,
        'totalResources': resourcesCount,
      };
    } catch (e) {
      rethrow;
    }
  }
  // Fetch all users
  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final response = await _supabase.rpc('get_all_users');
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      rethrow;
    }
  }
  // Fetch test analytics for a specific test
  Future<List<Map<String, dynamic>>> getTestAnalytics(String testId) async {
    try {
      final response = await _supabase.rpc('get_test_analytics', params: {'p_test_id': testId});
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      rethrow;
    }
  }
}
