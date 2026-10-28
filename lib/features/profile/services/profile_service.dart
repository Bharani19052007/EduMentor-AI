import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('first_name, target_exam, grade, notifications_enabled, dark_mode, avatar_url')
          .eq('id', userId)
          .maybeSingle();
      
      return response;
    } catch (e) {
      print('Error fetching profile stats: $e');
      return null;
    }
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    try {
      final updateData = Map<String, dynamic>.from(data);
      updateData['id'] = userId; // Required for upsert
      final response = await _supabase
          .from('profiles')
          .upsert(updateData)
          .select();
          
      if ((response as List).isEmpty) {
        throw Exception("Database update failed (RLS Policy blocked it or user not found)");
      }
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  Future<String?> uploadProfileImage(String userId, File imageFile) async {
    try {
      print('Starting uploadProfileImage...');
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$userId/$fileName'; // Put in a folder named by userId to match RLS

      print('Uploading File directly to Supabase storage...');
      // Use upsert: true so we don't accumulate junk files in the bucket
      await _supabase.storage.from('avatars').upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '0', upsert: true),
          ).timeout(const Duration(seconds: 15));

      print('Upload complete. Getting public URL...');
      // Append a timestamp to the URL to force Flutter to download the new image instead of using the cached old one
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imageUrl = '${_supabase.storage.from('avatars').getPublicUrl(filePath)}?t=$timestamp';
      
      print('Updating profile with new URL...');
      await updateProfile(userId, {'avatar_url': imageUrl}).timeout(const Duration(seconds: 15));
      
      print('Profile update complete!');
      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }

  Future<String?> uploadProfileImageBytes(String userId, List<int> bytes, String fileExt) async {
    try {
      print('Starting uploadProfileImageBytes...');
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$userId/$fileName'; // Put in a folder named by userId to match RLS

      print('Converting bytes to Uint8List...');
      final Uint8List uint8Bytes = Uint8List.fromList(bytes);

      print('Uploading binary to Supabase storage...');
      await _supabase.storage.from('avatars').uploadBinary(
            filePath,
            uint8Bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          ).timeout(const Duration(seconds: 15));

      print('Upload complete. Getting public URL...');
      final imageUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);
      
      print('Updating profile with new URL...');
      await updateProfile(userId, {'avatar_url': imageUrl}).timeout(const Duration(seconds: 15));
      
      print('Profile update complete!');
      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }
}
