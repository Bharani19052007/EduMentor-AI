import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mock_test_model.dart';
import '../models/mock_test_question_model.dart';
import '../../dashboard/services/dashboard_service.dart';

class MockTestService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetch all mock tests
  Future<List<MockTest>> getMockTests() async {
    try {
      final response = await _supabase
          .from('mock_tests')
          .select()
          .order('created_at', ascending: false);
          
      return (response as List).map((json) => MockTest.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Fetch a single mock test by ID
  Future<MockTest> getMockTestById(String testId) async {
    try {
      final response = await _supabase
          .from('mock_tests')
          .select()
          .eq('id', testId)
          .single();
          
      return MockTest.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Fetch recommended mock tests
  Future<List<MockTest>> getRecommendedTests() async {
    try {
      final response = await _supabase
          .from('mock_tests')
          .select()
          .eq('is_recommended', true)
          .order('created_at', ascending: false);
          
      return (response as List).map((json) => MockTest.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Fetch questions for a test
  Future<List<MockTestQuestion>> getTestQuestions(String testId) async {
    try {
      final response = await _supabase
          .from('mock_test_questions')
          .select()
          .eq('test_id', testId)
          .order('created_at', ascending: true);
          
      return (response as List).map((json) => MockTestQuestion.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Save test attempt
  Future<void> saveTestAttempt({
    required String testId,
    required int score,
    required int totalQuestions,
    required int timeTakenSeconds,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      await _supabase.from('test_attempts').insert({
        'user_id': userId,
        'test_id': testId,
        'score': score,
        'total_questions': totalQuestions,
        'time_taken_seconds': timeTakenSeconds,
      });

      // Update study streak after attending the test
      await DashboardService().updateStreak(userId);
    } catch (e) {
      rethrow;
    }
  }

  // Create a new mock test with questions
  Future<void> createMockTestWithQuestions({
    required Map<String, dynamic> testData,
    required List<Map<String, dynamic>> questionsData,
  }) async {
    try {
      // 1. Insert test and get the ID back
      final testResponse = await _supabase
          .from('mock_tests')
          .insert(testData)
          .select('id')
          .single();
          
      final String testId = testResponse['id'];

      // 2. Add the testId to every question
      final List<Map<String, dynamic>> finalQuestions = questionsData.map((q) {
        return {
          ...q,
          'test_id': testId,
        };
      }).toList();

      // 3. Bulk insert the questions
      if (finalQuestions.isNotEmpty) {
        await _supabase.from('mock_test_questions').insert(finalQuestions);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Update a mock test
  Future<void> updateMockTest(String id, Map<String, dynamic> data) async {
    try {
      await _supabase.from('mock_tests').update(data).eq('id', id);
    } catch (e) {
      rethrow;
    }
  }

  // Update a mock test and replace all its questions
  Future<void> updateMockTestWithQuestions({
    required String testId,
    required Map<String, dynamic> testData,
    required List<Map<String, dynamic>> questionsData,
  }) async {
    try {
      // 1. Update test metadata
      await _supabase.from('mock_tests').update(testData).eq('id', testId);

      // 2. Delete all existing questions for this test
      await _supabase.from('mock_test_questions').delete().eq('test_id', testId);

      // 3. Prepare the new questions with the testId
      final List<Map<String, dynamic>> finalQuestions = questionsData.map((q) {
        return {
          ...q,
          'test_id': testId,
        };
      }).toList();

      // 4. Bulk insert the updated questions
      if (finalQuestions.isNotEmpty) {
        await _supabase.from('mock_test_questions').insert(finalQuestions);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Delete a mock test
  Future<void> deleteMockTest(String id) async {
    try {
      await _supabase.from('mock_tests').delete().eq('id', id);
    } catch (e) {
      rethrow;
    }
  }
}
