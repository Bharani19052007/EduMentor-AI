import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiService {
  /// Default verified high-performance Groq model for NEET/JEE tutoring
  static const String defaultModel = 'openai/gpt-oss-120b';

  /// Groq Chat Completions API endpoint
  static const String apiEndpoint = 'https://api.groq.com/openai/v1/chat/completions';

  /// Pedagogical system instruction for the AI Teacher
  static const String systemInstruction =
      'You are an expert AI teacher. You help students learn about various topics. '
      'Your name is EduMentor. Respond in a friendly, encouraging, and educational manner. '
      'Keep your responses concise and easy to understand. If the student asks a question '
      'in Tamil or requests an explanation in Tamil, you MUST explain the concepts clearly '
      'in fluent Tamil. CRITICAL: Do NOT use LaTeX formatting for math equations (e.g., '
      'do not use \\frac, \\sqrt, \$, \$\$, etc.). Instead, write all math using plain text '
      'and standard Unicode characters (e.g., x^2, (a+b)/c, √x, θ) so that it is perfectly '
      'readable as plain text without a math renderer.';

  final String modelName;
  final String _apiKey;
  final http.Client _client;
  final List<Map<String, String>> _messages = [];

  AiService({
    String? apiKey,
    String? model,
    http.Client? httpClient,
  })  : _client = httpClient ?? http.Client(),
        modelName = (model?.trim().isNotEmpty == true)
            ? model!.trim()
            : ((dotenv.isInitialized && dotenv.env['GROQ_MODEL']?.trim().isNotEmpty == true)
                ? dotenv.env['GROQ_MODEL']!.trim()
                : ((dotenv.isInitialized && dotenv.env['GEMINI_MODEL']?.trim().isNotEmpty == true)
                    ? dotenv.env['GEMINI_MODEL']!.trim()
                    : defaultModel)),
        _apiKey = _resolveApiKey(apiKey) {
    _initChat();
  }

  static String _resolveApiKey(String? explicitKey) {
    if (explicitKey?.trim().isNotEmpty == true) {
      return explicitKey!.trim();
    }
    if (dotenv.isInitialized) {
      final groqKey = dotenv.env['GROQ_API_KEY']?.trim();
      if (groqKey != null && groqKey.isNotEmpty) {
        return groqKey;
      }
      final geminiKey = dotenv.env['GEMINI_API_KEY']?.trim();
      if (geminiKey != null && geminiKey.isNotEmpty) {
        return geminiKey;
      }
    }
    throw Exception('GROQ_API_KEY is not defined in .env file');
  }

  void _initChat() {
    _messages.clear();
    _messages.add({'role': 'system', 'content': systemInstruction});
  }

  void clearHistory() {
    _initChat();
  }

  /// Returns user & assistant conversational turns (excluding system prompt)
  List<Map<String, String>> get history =>
      List.unmodifiable(_messages.where((m) => m['role'] != 'system'));

  Future<String> sendMessage(
    String message, {
    Uint8List? imageBytes,
    String? mimeType,
  }) async {
    try {
      String promptText = message.trim();
      if (promptText.isEmpty) {
        promptText = imageBytes != null
            ? 'Please help me understand the concept related to this image.'
            : 'Hello!';
      }

      final userTurn = {'role': 'user', 'content': promptText};
      _messages.add(userTurn);

      final response = await _client.post(
        Uri.parse(apiEndpoint),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: jsonEncode({
          'model': modelName,
          'messages': _messages,
          'stream': false,
        }),
      );

      if (response.statusCode != 200) {
        _messages.removeLast();
        throw Exception('Groq API error [${response.statusCode}]: ${response.body}');
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw Exception('No response choices returned by Groq AI');
      }

      final content = choices[0]['message']?['content'] as String? ?? 'I could not generate a response.';
      _messages.add({'role': 'assistant', 'content': content});
      return content;
    } catch (e) {
      return 'Sorry, I encountered an error: ${formatErrorMessage(e)}';
    }
  }

  Stream<String> sendMessageStream(
    String message, {
    Uint8List? imageBytes,
    String? mimeType,
  }) async* {
    try {
      String promptText = message.trim();
      if (promptText.isEmpty) {
        promptText = imageBytes != null
            ? 'Please help me understand the concept related to this image.'
            : 'Hello!';
      }

      final userTurn = {'role': 'user', 'content': promptText};
      _messages.add(userTurn);

      final request = http.Request('POST', Uri.parse(apiEndpoint))
        ..headers.addAll({
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json; charset=utf-8',
        })
        ..body = jsonEncode({
          'model': modelName,
          'messages': _messages,
          'stream': true,
        });

      final streamedResponse = await _client.send(request);

      if (streamedResponse.statusCode != 200) {
        _messages.removeLast();
        final errorBody = await streamedResponse.stream.bytesToString();
        throw Exception('Groq API error [${streamedResponse.statusCode}]: $errorBody');
      }

      final StringBuffer fullResponse = StringBuffer();

      final lines = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        if (trimmed == 'data: [DONE]') break;
        if (trimmed.startsWith('data: ')) {
          final jsonStr = trimmed.substring(6).trim();
          if (jsonStr.isEmpty) continue;
          try {
            final chunk = jsonDecode(jsonStr) as Map<String, dynamic>;
            final choices = chunk['choices'] as List<dynamic>?;
            if (choices != null && choices.isNotEmpty) {
              final delta = choices[0]['delta'] as Map<String, dynamic>?;
              final content = delta?['content'] as String?;
              if (content != null && content.isNotEmpty) {
                fullResponse.write(content);
                yield content;
              }
            }
          } catch (_) {
            // Ignore malformed chunk
          }
        }
      }

      if (fullResponse.isNotEmpty) {
        _messages.add({'role': 'assistant', 'content': fullResponse.toString()});
      }
    } catch (e) {
      yield 'Sorry, I encountered an error: ${formatErrorMessage(e)}';
    }
  }

  /// Categorizes errors and provides user-friendly, security-hardened explanations.
  /// Never displays API keys, tokens, credentials, or internal stack traces to students.
  static String formatErrorMessage(Object error) {
    final errorStr = error.toString();
    final errorLower = errorStr.toLowerCase();

    // 1. Missing environment variable
    if (errorLower.contains('groq_api_key is not defined') ||
        errorLower.contains('groq_api_key is not set') ||
        errorLower.contains('gemini_api_key is not defined') ||
        errorLower.contains('gemini_api_key is not set')) {
      return 'Configuration error: GROQ_API_KEY is not configured in .env. Please configure a valid API key.';
    }

    // 2. Authentication and Authorization (HTTP 401 / 403)
    if (errorLower.contains('invalid_api_key') ||
        errorLower.contains('api key not valid') ||
        errorLower.contains('401') ||
        errorLower.contains('unauthenticated') ||
        errorLower.contains('invalid api key')) {
      return 'Authentication error: The configured Groq API key is invalid or expired. Please verify your GROQ_API_KEY in .env.';
    }
    if (errorLower.contains('403') ||
        errorLower.contains('permission_denied') ||
        errorLower.contains('permission denied') ||
        errorLower.contains('caller does not have permission')) {
      return 'Access denied: The provided API key lacks permission to access the requested model or feature.';
    }

    // 3. Model Not Found or Unsupported (HTTP 404)
    if (errorLower.contains('404') ||
        errorLower.contains('not found') ||
        errorLower.contains('not_found') ||
        errorLower.contains('model_not_found') ||
        errorLower.contains('does not exist or you do not have access') ||
        errorLower.contains('unsupported model')) {
      return 'Model error: The requested AI model is unavailable or unsupported. Please check GROQ_MODEL in your configuration.';
    }

    // 4. Rate Limits and Quotas (HTTP 429)
    if (errorLower.contains('429') ||
        errorLower.contains('resource_exhausted') ||
        errorLower.contains('quota') ||
        errorLower.contains('exhausted') ||
        errorLower.contains('rate limit') ||
        errorLower.contains('rate_limit_exceeded') ||
        errorLower.contains('too many requests')) {
      return 'Service limit reached: The AI service has temporarily exceeded its request quota. Please wait a moment before trying again.';
    }

    // 5. Malformed Request (HTTP 400)
    if (errorLower.contains('400') ||
        errorLower.contains('invalid_argument') ||
        errorLower.contains('invalid argument') ||
        errorLower.contains('malformed') ||
        errorLower.contains('invalid_request_error')) {
      return 'Request error: The question or input format could not be processed. Please rephrase your question.';
    }

    // 6. Server Errors (HTTP 5xx)
    if (errorLower.contains('500') ||
        errorLower.contains('502') ||
        errorLower.contains('503') ||
        errorLower.contains('504') ||
        errorLower.contains('server error') ||
        errorLower.contains('internal') ||
        errorLower.contains('unavailable')) {
      return 'Server error: Groq AI services are temporarily unavailable. Please try again in a few moments.';
    }

    // 7. Network / Connectivity Failures
    if (error is SocketException ||
        error is TimeoutException ||
        errorLower.contains('socketexception') ||
        errorLower.contains('clientexception') ||
        errorLower.contains('failed host lookup') ||
        errorLower.contains('network is unreachable') ||
        errorLower.contains('timeoutexception') ||
        errorLower.contains('connection closed') ||
        errorLower.contains('connection abort') ||
        errorLower.contains('network error')) {
      return 'Network error: Unable to reach AI services. Please check your internet connection.';
    }

    // Safe fallback: never expose raw stack traces, API keys, or internal details
    return 'An unexpected error occurred while communicating with the AI service. Please try again later.';
  }
}
