import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:edumentor_ai/features/ai/services/ai_service.dart';

/// Lightweight fake http client for mocking Groq API responses without live network calls.
class FakeHttpClient extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest request) handler;

  FakeHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => handler(request);
}

void main() {
  group('AiService Model Configuration Tests', () {
    test('uses openai/gpt-oss-120b as default model when no model is configured', () {
      final aiService = AiService(
        apiKey: 'test-api-key',
        httpClient: FakeHttpClient((_) async => http.StreamedResponse(const Stream.empty(), 200)),
      );

      expect(aiService.modelName, equals('openai/gpt-oss-120b'));
      expect(AiService.defaultModel, equals('openai/gpt-oss-120b'));
    });

    test('uses custom model passed via constructor parameter', () {
      final aiService = AiService(
        apiKey: 'test-api-key',
        model: 'openai/gpt-oss-20b',
        httpClient: FakeHttpClient((_) async => http.StreamedResponse(const Stream.empty(), 200)),
      );

      expect(aiService.modelName, equals('openai/gpt-oss-20b'));
    });

    test('uses model from dotenv when constructor model is omitted', () {
      dotenv.loadFromString(envString: 'GROQ_MODEL=qwen/qwen3.8-27b\nGROQ_API_KEY=test-dotenv-key');

      final aiService = AiService(
        httpClient: FakeHttpClient((_) async => http.StreamedResponse(const Stream.empty(), 200)),
      );

      expect(aiService.modelName, equals('qwen/qwen3.8-27b'));
    });

    test('constructor model takes precedence over dotenv model', () {
      dotenv.loadFromString(envString: 'GROQ_MODEL=qwen/qwen3.8-27b\nGROQ_API_KEY=test-dotenv-key');

      final aiService = AiService(
        model: 'openai/gpt-oss-120b',
        httpClient: FakeHttpClient((_) async => http.StreamedResponse(const Stream.empty(), 200)),
      );

      expect(aiService.modelName, equals('openai/gpt-oss-120b'));
    });

    test('throws Exception when GROQ_API_KEY is not defined', () {
      dotenv.clean();

      expect(
        () => AiService(
          httpClient: FakeHttpClient((_) async => http.StreamedResponse(const Stream.empty(), 200)),
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('GROQ_API_KEY is not defined in .env file'),
        )),
      );
    });

    test('initializes empty chat history and supports clearHistory', () {
      final aiService = AiService(
        apiKey: 'test-key',
        httpClient: FakeHttpClient((_) async => http.StreamedResponse(const Stream.empty(), 200)),
      );

      expect(aiService.history.isEmpty, isTrue);
      aiService.clearHistory();
      expect(aiService.history.isEmpty, isTrue);
    });
  });

  group('AiService Error Formatting & Sanitization Tests', () {
    test('formats invalid API key error correctly without leaking secrets', () {
      final message = AiService.formatErrorMessage(Exception('invalid_api_key: The API key is invalid [401]'));
      expect(message, contains('Authentication error'));
      expect(message, contains('invalid'));
      expect(message, isNot(contains('secret')));
    });

    test('formats missing GROQ_API_KEY in .env cleanly', () {
      final message = AiService.formatErrorMessage(Exception('GROQ_API_KEY is not defined in .env file'));
      expect(message, contains('Configuration error'));
      expect(message, contains('GROQ_API_KEY'));
    });

    test('formats HTTP 404 (model not found / unsupported) correctly', () {
      const errorMsg = 'The model `invalid-model` does not exist or you do not have access to it. [404]';
      final message = AiService.formatErrorMessage(Exception(errorMsg));
      expect(message, contains('Model error'));
      expect(message, contains('unavailable or unsupported'));
    });

    test('formats HTTP 429 (quota exhausted / rate limit) gracefully', () {
      const errorMsg = 'Rate limit reached for requests per minute (RPM). [429 rate_limit_exceeded]';
      final message = AiService.formatErrorMessage(Exception(errorMsg));
      expect(message, contains('Service limit reached'));
      expect(message, contains('quota'));
    });

    test('formats HTTP 400 (malformed / invalid argument) clearly', () {
      const errorMsg = 'Request contains an invalid argument. [400 invalid_request_error]';
      final message = AiService.formatErrorMessage(Exception(errorMsg));
      expect(message, contains('Request error'));
      expect(message, contains('could not be processed'));
    });

    test('formats HTTP 403 (permission denied) clearly', () {
      const errorMsg = 'The caller does not have permission [403 PERMISSION_DENIED]';
      final message = AiService.formatErrorMessage(Exception(errorMsg));
      expect(message, contains('Access denied'));
      expect(message, contains('permission'));
    });

    test('formats HTTP 500 / 503 Server Errors without exposing stack trace', () {
      final message = AiService.formatErrorMessage(Exception('Server Error [500]: Internal error'));
      expect(message, contains('Server error'));
      expect(message, contains('temporarily unavailable'));
      expect(message, isNot(contains('Internal error')));
    });

    test('formats Network and SocketException failures gracefully', () {
      final message = AiService.formatErrorMessage(const SocketException('Failed host lookup: api.groq.com'));
      expect(message, contains('Network error'));
      expect(message, contains('check your internet connection'));
      expect(message, isNot(contains('api.groq.com')));
    });

    test('formats TimeoutException failures gracefully', () {
      final message = AiService.formatErrorMessage(TimeoutException('Request timed out'));
      expect(message, contains('Network error'));
    });

    test('never exposes private API keys or tokens even if present in raw error string', () {
      const rawErrorWithSecret = 'Server error occurred with key gsk_test_SECRET_KEY_12345: request failed';
      final message = AiService.formatErrorMessage(Exception(rawErrorWithSecret));
      expect(message, isNot(contains('gsk_test_SECRET_KEY_12345')));
      expect(message, isNot(contains('SECRET')));
    });
  });

  group('AiService End-to-End Mock Execution Tests', () {
    test('sendMessage returns successful text response from mocked model', () async {
      final fakeClient = FakeHttpClient((request) async {
        final responseBody = jsonEncode({
          'choices': [
            {
              'message': {
                'role': 'assistant',
                'content': 'Photosynthesis is the process by which green plants convert sunlight into chemical energy.'
              },
              'finish_reason': 'stop'
            }
          ]
        });

        return http.StreamedResponse(
          Stream.value(utf8.encode(responseBody)),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final aiService = AiService(
        apiKey: 'test-api-key',
        model: 'openai/gpt-oss-120b',
        httpClient: fakeClient,
      );

      final response = await aiService.sendMessage('Explain photosynthesis in one sentence.');
      expect(response, equals('Photosynthesis is the process by which green plants convert sunlight into chemical energy.'));
      expect(aiService.history.length, equals(2));
      expect(aiService.history[0]['content'], equals('Explain photosynthesis in one sentence.'));
      expect(aiService.history[1]['content'], equals('Photosynthesis is the process by which green plants convert sunlight into chemical energy.'));
    });

    test('sendMessage handles HTTP 404 model not found error gracefully', () async {
      final fakeClient = FakeHttpClient((request) async {
        final errorBody = jsonEncode({
          'error': {
            'code': 'model_not_found',
            'message': 'The model `invalid-model` does not exist or you do not have access to it.',
            'type': 'invalid_request_error'
          }
        });

        return http.StreamedResponse(
          Stream.value(utf8.encode(errorBody)),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final aiService = AiService(
        apiKey: 'test-api-key',
        model: 'invalid-model',
        httpClient: fakeClient,
      );

      final response = await aiService.sendMessage('Hello');
      expect(response, contains('Sorry, I encountered an error: Model error'));
      expect(response, contains('unavailable or unsupported'));
    });

    test('sendMessage handles HTTP 429 quota exhausted gracefully', () async {
      final fakeClient = FakeHttpClient((request) async {
        final errorBody = jsonEncode({
          'error': {
            'code': 'rate_limit_exceeded',
            'message': 'Rate limit reached for requests per minute (RPM).',
            'type': 'tokens'
          }
        });

        return http.StreamedResponse(
          Stream.value(utf8.encode(errorBody)),
          429,
          headers: {'content-type': 'application/json'},
        );
      });

      final aiService = AiService(
        apiKey: 'test-api-key',
        model: 'openai/gpt-oss-120b',
        httpClient: fakeClient,
      );

      final response = await aiService.sendMessage('Hello');
      expect(response, contains('Sorry, I encountered an error: Service limit reached'));
      expect(response, contains('quota'));
    });

    test('sendMessageStream streams text chunks and handles errors securely', () async {
      final fakeClient = FakeHttpClient((request) async {
        final chunk1 = 'data: ${jsonEncode({
          'choices': [
            {
              'delta': {'content': 'Chunk 1 '},
              'finish_reason': null
            }
          ]
        })}\n\n';

        final chunk2 = 'data: ${jsonEncode({
          'choices': [
            {
              'delta': {'content': 'Chunk 2'},
              'finish_reason': null
            }
          ]
        })}\n\n';

        final chunk3 = 'data: [DONE]\n\n';

        return http.StreamedResponse(
          Stream.value(utf8.encode('$chunk1$chunk2$chunk3')),
          200,
          headers: {'content-type': 'text/event-stream'},
        );
      });

      final aiService = AiService(
        apiKey: 'test-api-key',
        model: 'openai/gpt-oss-120b',
        httpClient: fakeClient,
      );

      final chunks = await aiService.sendMessageStream('Tell me something.').toList();
      expect(chunks, equals(['Chunk 1 ', 'Chunk 2']));
      expect(aiService.history.length, equals(2));
      expect(aiService.history[1]['content'], equals('Chunk 1 Chunk 2'));
    });
  });
}
