import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/resource_model.dart';

class ResourceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetch learning resources, optionally filtered by category
  Future<List<ResourceModel>> getResources({String category = 'All', bool showPremium = true, bool showFree = true, String? targetExam}) async {
    try {
      var query = _supabase.from('learning_resources').select();

      if (category != 'All') {
        query = query.eq('category', category);
      }
      
      if (showPremium && !showFree) {
        query = query.eq('is_premium', true);
      } else if (!showPremium && showFree) {
        query = query.eq('is_premium', false);
      }

      if (targetExam != null && targetExam != 'Both') {
        query = query.or('target_exam.eq.$targetExam,target_exam.eq.Both');
      }

      final response = await query.order('created_at', ascending: false);
          
      return (response as List).map((json) => ResourceModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }
  // Add a new resource with file upload
  Future<void> addResource({
    required File file,
    required String title,
    required String category,
    required String type,
    required String fileSize,
    required bool isPremium,
    String targetExam = 'Both',
  }) async {
    try {
      final fileExtension = file.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      
      // Upload to Supabase Storage (bucket named 'resources')
      await _supabase.storage.from('resources').upload(
        fileName,
        file,
      );

      // Get public URL
      final publicUrl = _supabase.storage.from('resources').getPublicUrl(fileName);

      // Insert into database
      await _supabase.from('learning_resources').insert({
        'title': title,
        'category': category,
        'type': type,
        'file_size_or_duration': fileSize,
        'file_url': publicUrl,
        'is_premium': isPremium,
        'target_exam': targetExam,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Delete a resource (also attempts to delete from storage)
  Future<void> deleteResource(String id, String fileUrl) async {
    try {
      // Extract filename from URL if possible to delete from storage
      final uri = Uri.parse(fileUrl);
      final fileName = uri.pathSegments.last;
      
      if (fileName.isNotEmpty) {
        try {
          await _supabase.storage.from('resources').remove([fileName]);
        } catch (_) {
          // Ignore storage delete errors (might be a dummy URL or already deleted)
        }
      }

      await _supabase.from('learning_resources').delete().eq('id', id);
    } catch (e) {
      rethrow;
    }
  }
}
