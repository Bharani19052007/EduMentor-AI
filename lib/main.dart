import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/theme/app_theme.dart';
import 'navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  bool envLoaded = false;
  try {
    await dotenv.load(fileName: ".env");
    envLoaded = true;
  } catch (_) {
    envLoaded = false;
  }
  
  final supabaseUrl = dotenv.env['SUPABASE_URL']?.trim();
  final supabasePublishableKey = (dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ?? dotenv.env['SUPABASE_ANON_KEY'])?.trim();

  final List<String> missingKeys = [];
  if (!envLoaded) {
    missingKeys.add('.env file not found or inaccessible');
  }
  if (supabaseUrl == null || supabaseUrl.isEmpty) {
    missingKeys.add('SUPABASE_URL');
  } else {
    final uri = Uri.tryParse(supabaseUrl);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      missingKeys.add('SUPABASE_URL (must be a valid http/https URL)');
    }
  }
  if (supabasePublishableKey == null || supabasePublishableKey.isEmpty) {
    missingKeys.add('SUPABASE_PUBLISHABLE_KEY');
  }

  if (missingKeys.isNotEmpty) {
    runApp(ConfigurationErrorApp(missingKeys: missingKeys));
    return;
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl!,
    publishableKey: supabasePublishableKey,
  );

  runApp(const EduMentorApp());
}

class ConfigurationErrorApp extends StatelessWidget {
  final List<String> missingKeys;

  const ConfigurationErrorApp({
    super.key,
    required this.missingKeys,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Configuration Error',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 64,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Configuration Required',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'The application could not start because required configuration is missing from your .env file.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Missing or invalid configuration:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final key in missingKeys)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3.0),
                            child: Row(
                              children: [
                                const Icon(Icons.circle, size: 8, color: Colors.red),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    key,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Please update your .env file based on .env.example and restart the app.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EduMentorApp extends StatelessWidget {
  const EduMentorApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Note: Add Providers here later
    return MultiProvider(
      providers: [
        Provider.value(value: 'dummy'), // Replace with actual providers
      ],
      child: MaterialApp.router(
        title: 'EduMentor AI',
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
