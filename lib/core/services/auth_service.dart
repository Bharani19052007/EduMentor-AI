import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Listen to auth state changes
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;

  // Get current user role
  String get currentUserRole {
    final user = currentUser;
    if (user != null && user.userMetadata != null) {
      return user.userMetadata!['role'] ?? 'student';
    }
    return 'student';
  }

  // Sign In
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Sign Up
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String role,
    required String name,
    required String preparationPath,
  }) async {
    try {
      return await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'role': role,
          'name': name,
          'preparation_path': preparationPath,
        }, // Store data in user_metadata
      );
    } catch (e) {
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      try {
        if (kIsWeb || (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS)) {
          final googleSignIn = GoogleSignIn();
          if (await googleSignIn.isSignedIn()) {
            await googleSignIn.signOut();
          }
        }
      } catch (_) {
        // Silently ignore Google sign-out failures if any
      }
      await _supabase.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Google Sign In
  Future<AuthResponse> signInWithGoogle() async {
    try {
      if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        // Fallback to Supabase OAuth for desktop platforms since google_sign_in plugin 
        // does not natively support desktop without additional setup.
        final success = await _supabase.auth.signInWithOAuth(OAuthProvider.google);
        if (!success) {
          throw 'Google Sign In failed to launch.';
        }
        // Return current state, actual login will complete via deep link & onAuthStateChange
        return AuthResponse(
          session: _supabase.auth.currentSession,
          user: _supabase.auth.currentUser,
        );
      }

      final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID']?.trim();
      if (webClientId == null || webClientId.isEmpty) {
        throw 'Google Web Client ID is not configured. Please set GOOGLE_WEB_CLIENT_ID in your .env file.';
      }
      // const iosClientId = 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com'; // Uncomment if targeting iOS

      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
        // clientId: iosClientId, 
      );
      
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw 'Google Sign In was cancelled.';
      }
      
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'No ID Token found from Google.';
      }

      return _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      rethrow;
    }
  }
}
