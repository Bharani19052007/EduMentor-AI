import 'package:flutter_test/flutter_test.dart';
import 'package:edumentor_ai/features/mocktests/models/mock_test_model.dart';
import 'package:edumentor_ai/features/mocktests/models/mock_test_question_model.dart';
import 'package:edumentor_ai/features/resources/models/resource_model.dart';

void main() {
  group('MockTest Model', () {
    final testDate = DateTime.parse('2026-09-01T10:00:00.000Z');

    test('instantiates correctly via constructor', () {
      final test = MockTest(
        id: 'test-123',
        title: 'Physics Mock 1',
        category: 'Physics',
        description: 'Covers Mechanics and Optics',
        durationMins: 180,
        isRecommended: true,
        createdAt: testDate,
      );

      expect(test.id, 'test-123');
      expect(test.title, 'Physics Mock 1');
      expect(test.category, 'Physics');
      expect(test.description, 'Covers Mechanics and Optics');
      expect(test.durationMins, 180);
      expect(test.isRecommended, isTrue);
      expect(test.createdAt, testDate);
    });

    test('deserializes from valid JSON map', () {
      final json = {
        'id': 'test-456',
        'title': 'Chemistry Full Test',
        'category': 'Chemistry',
        'description': 'Organic & Inorganic',
        'duration_mins': 90,
        'is_recommended': true,
        'created_at': '2026-09-01T10:00:00.000Z',
      };

      final test = MockTest.fromJson(json);

      expect(test.id, 'test-456');
      expect(test.title, 'Chemistry Full Test');
      expect(test.category, 'Chemistry');
      expect(test.description, 'Organic & Inorganic');
      expect(test.durationMins, 90);
      expect(test.isRecommended, isTrue);
      expect(test.createdAt, testDate);
    });

    test('deserializes with default isRecommended when missing or null in JSON', () {
      final json = {
        'id': 'test-789',
        'title': 'Biology Unit Test',
        'category': 'Biology',
        'description': 'Genetics and Evolution',
        'duration_mins': 60,
        'created_at': '2026-09-01T10:00:00.000Z',
      };

      final test = MockTest.fromJson(json);

      expect(test.id, 'test-789');
      expect(test.isRecommended, isFalse);
    });

    test('serializes to JSON map matching expected schema', () {
      final test = MockTest(
        id: 'test-123',
        title: 'Physics Mock 1',
        category: 'Physics',
        description: 'Covers Mechanics',
        durationMins: 180,
        isRecommended: false,
        createdAt: testDate,
      );

      final json = test.toJson();

      expect(json['id'], 'test-123');
      expect(json['title'], 'Physics Mock 1');
      expect(json['category'], 'Physics');
      expect(json['description'], 'Covers Mechanics');
      expect(json['duration_mins'], 180);
      expect(json['is_recommended'], isFalse);
      expect(json['created_at'], testDate.toIso8601String());

      // Round-trip test
      final roundTrip = MockTest.fromJson(json);
      expect(roundTrip.id, test.id);
      expect(roundTrip.title, test.title);
      expect(roundTrip.category, test.category);
      expect(roundTrip.durationMins, test.durationMins);
      expect(roundTrip.isRecommended, test.isRecommended);
      expect(roundTrip.createdAt, test.createdAt);
    });
  });

  group('ResourceModel', () {
    final resourceDate = DateTime.parse('2026-08-15T12:00:00.000Z');

    test('instantiates with defaults via constructor', () {
      final resource = ResourceModel(
        id: 'res-1',
        title: 'Formulas Cheat Sheet',
        category: 'Formulas',
        type: 'PDF',
        fileSizeOrDuration: '2.5 MB',
        fileUrl: 'https://example.com/formulas.pdf',
        isPremium: false,
        createdAt: resourceDate,
      );

      expect(resource.id, 'res-1');
      expect(resource.title, 'Formulas Cheat Sheet');
      expect(resource.category, 'Formulas');
      expect(resource.type, 'PDF');
      expect(resource.fileSizeOrDuration, '2.5 MB');
      expect(resource.fileUrl, 'https://example.com/formulas.pdf');
      expect(resource.isPremium, isFalse);
      expect(resource.targetExam, 'Both');
      expect(resource.createdAt, resourceDate);
    });

    test('deserializes from full JSON map', () {
      final json = {
        'id': 'res-2',
        'title': 'NEET Biology PYQs 2025',
        'category': 'PYQs',
        'type': 'PDF',
        'file_size_or_duration': '12 MB',
        'file_url': 'https://example.com/pyq.pdf',
        'is_premium': true,
        'created_at': '2026-08-15T12:00:00.000Z',
        'target_exam': 'NEET',
      };

      final resource = ResourceModel.fromJson(json);

      expect(resource.id, 'res-2');
      expect(resource.title, 'NEET Biology PYQs 2025');
      expect(resource.category, 'PYQs');
      expect(resource.type, 'PDF');
      expect(resource.fileSizeOrDuration, '12 MB');
      expect(resource.fileUrl, 'https://example.com/pyq.pdf');
      expect(resource.isPremium, isTrue);
      expect(resource.targetExam, 'NEET');
      expect(resource.createdAt, resourceDate);
    });

    test('deserializes with defaults when optional fields are null or absent', () {
      final json = {
        'id': 'res-3',
        'title': 'Basic Kinematics Notes',
        'category': 'Notes',
        'type': 'PDF',
        'file_size_or_duration': '1.1 MB',
        'file_url': 'https://example.com/kinematics.pdf',
        'created_at': '2026-08-15T12:00:00.000Z',
      };

      final resource = ResourceModel.fromJson(json);

      expect(resource.isPremium, isFalse);
      expect(resource.targetExam, 'Both');
    });

    test('serializes to JSON and supports round-trip', () {
      final resource = ResourceModel(
        id: 'res-4',
        title: 'JEE Advanced Revision',
        category: 'Notes',
        type: 'PDF',
        fileSizeOrDuration: '5.0 MB',
        fileUrl: 'https://example.com/revision.pdf',
        isPremium: true,
        createdAt: resourceDate,
        targetExam: 'JEE',
      );

      final json = resource.toJson();

      expect(json['id'], 'res-4');
      expect(json['title'], 'JEE Advanced Revision');
      expect(json['category'], 'Notes');
      expect(json['type'], 'PDF');
      expect(json['file_size_or_duration'], '5.0 MB');
      expect(json['file_url'], 'https://example.com/revision.pdf');
      expect(json['is_premium'], isTrue);
      expect(json['target_exam'], 'JEE');
      expect(json['created_at'], resourceDate.toIso8601String());

      final roundTrip = ResourceModel.fromJson(json);
      expect(roundTrip.id, resource.id);
      expect(roundTrip.title, resource.title);
      expect(roundTrip.targetExam, resource.targetExam);
      expect(roundTrip.isPremium, resource.isPremium);
    });
  });

  group('MockTestQuestion Model', () {
    test('instantiates correctly via constructor', () {
      final question = MockTestQuestion(
        id: 'q-1',
        testId: 'test-100',
        questionText: 'What is Newton\'s first law of motion?',
        optionA: 'Law of Inertia',
        optionB: 'Law of Acceleration',
        optionC: 'Law of Action-Reaction',
        optionD: 'Law of Gravitation',
        correctOption: 'A',
      );

      expect(question.id, 'q-1');
      expect(question.testId, 'test-100');
      expect(question.questionText, 'What is Newton\'s first law of motion?');
      expect(question.optionA, 'Law of Inertia');
      expect(question.optionB, 'Law of Acceleration');
      expect(question.optionC, 'Law of Action-Reaction');
      expect(question.optionD, 'Law of Gravitation');
      expect(question.correctOption, 'A');
    });

    test('deserializes from snake_case database JSON map', () {
      final json = {
        'id': 'q-2',
        'test_id': 'test-200',
        'question_text': 'What is the chemical formula of ozone?',
        'option_a': 'O2',
        'option_b': 'O3',
        'option_c': 'O4',
        'option_d': 'CO2',
        'correct_option': 'B',
      };

      final question = MockTestQuestion.fromJson(json);

      expect(question.id, 'q-2');
      expect(question.testId, 'test-200');
      expect(question.questionText, 'What is the chemical formula of ozone?');
      expect(question.optionA, 'O2');
      expect(question.optionB, 'O3');
      expect(question.optionC, 'O4');
      expect(question.optionD, 'CO2');
      expect(question.correctOption, 'B');
    });
  });
}
