import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/mock_test_model.dart';
import '../models/mock_test_question_model.dart';
import '../services/mock_test_service.dart';

class TestTakingScreen extends StatefulWidget {
  final String testId;
  const TestTakingScreen({super.key, required this.testId});

  @override
  State<TestTakingScreen> createState() => _TestTakingScreenState();
}

class _TestTakingScreenState extends State<TestTakingScreen> {
  final MockTestService _mockTestService = MockTestService();
  
  MockTest? _test;
  List<MockTestQuestion> _questions = [];
  bool _isLoading = true;
  String? _error;

  int _currentIndex = 0;
  final Map<String, String> _selectedAnswers = {}; // questionId -> option (A,B,C,D)

  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchTestDetails();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchTestDetails() async {
    try {
      final test = await _mockTestService.getMockTestById(widget.testId);
      final questions = await _mockTestService.getTestQuestions(widget.testId);

      if (mounted) {
        setState(() {
          _test = test;
          _questions = questions;
          _isLoading = false;
          _remainingSeconds = test.durationMins * 60;
        });
        _startTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        _submitTest(autoSubmit: true);
      }
    });
  }

  String _formatTime(int seconds) {
    final int h = seconds ~/ 3600;
    final int m = (seconds % 3600) ~/ 60;
    final int s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _submitTest({bool autoSubmit = false}) async {
    if (_isSubmitting) return;

    if (!autoSubmit) {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Submit Test'),
          content: Text('You have answered ${_selectedAnswers.length} out of ${_questions.length} questions. Are you sure you want to submit?'),
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => context.pop(true),
              child: const Text('Submit'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() {
      _isSubmitting = true;
    });
    _timer?.cancel();

    // Calculate score
    int score = 0;
    for (var q in _questions) {
      final answer = _selectedAnswers[q.id];
      if (answer == q.correctOption) {
        score++;
      }
    }

    try {
      final totalSeconds = (_test?.durationMins ?? 0) * 60;
      final timeTaken = totalSeconds - _remainingSeconds;

      await _mockTestService.saveTestAttempt(
        testId: widget.testId,
        score: score,
        totalQuestions: _questions.length,
        timeTakenSeconds: timeTaken,
      );

      if (mounted) {
        context.pushReplacement('/test/result', extra: {
          'score': score,
          'total': _questions.length,
          'testTitle': _test?.title ?? 'Mock Test',
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save result: $e')));
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Failed to load test: $_error')),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(_test?.title ?? 'Test')),
        body: const Center(child: Text('This test has no questions yet!')),
      );
    }

    final currentQuestion = _questions[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_test!.title),
        centerTitle: true,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Quit Test?'),
                content: const Text('Your progress will be lost.'),
                actions: [
                  TextButton(onPressed: () => context.pop(false), child: const Text('Cancel')),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    onPressed: () => context.pop(true),
                    child: const Text('Quit'),
                  ),
                ],
              ),
            );
            if (confirm == true && context.mounted) {
              context.pop();
            }
          },
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: _remainingSeconds < 300 ? Colors.red.withValues(alpha: 0.1) : colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.timer, size: 18, color: _remainingSeconds < 300 ? Colors.red : colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  _formatTime(_remainingSeconds),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _remainingSeconds < 300 ? Colors.red : colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _questions.length,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Question ${_currentIndex + 1} of ${_questions.length}',
                          style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _selectedAnswers.containsKey(currentQuestion.id) 
                              ? Colors.green.withValues(alpha: 0.1) 
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _selectedAnswers.containsKey(currentQuestion.id) ? 'Answered' : 'Unanswered',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _selectedAnswers.containsKey(currentQuestion.id) ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    currentQuestion.questionText,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.4),
                  ),
                  const SizedBox(height: 32),
                  _buildOptionCard(currentQuestion, 'A', currentQuestion.optionA, colorScheme),
                  const SizedBox(height: 12),
                  _buildOptionCard(currentQuestion, 'B', currentQuestion.optionB, colorScheme),
                  const SizedBox(height: 12),
                  _buildOptionCard(currentQuestion, 'C', currentQuestion.optionC, colorScheme),
                  const SizedBox(height: 12),
                  _buildOptionCard(currentQuestion, 'D', currentQuestion.optionD, colorScheme),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentIndex > 0)
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _currentIndex--),
                      icon: const Icon(LucideIcons.arrowLeft),
                      label: const Text('Previous'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                    )
                  else
                    const SizedBox.shrink(),
                    
                  if (_currentIndex < _questions.length - 1)
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _currentIndex++),
                      icon: const Icon(LucideIcons.arrowRight),
                      label: const Text('Next'),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitTest,
                      icon: _isSubmitting 
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(LucideIcons.checkCircle),
                      label: Text(_isSubmitting ? 'Submitting...' : 'Submit Test'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(MockTestQuestion question, String optionId, String optionText, ColorScheme colorScheme) {
    final isSelected = _selectedAnswers[question.id] == optionId;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedAnswers[question.id] = optionId;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Text(
                optionId,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                optionText,
                style: TextStyle(
                  fontSize: 16,
                  color: isSelected ? colorScheme.primary : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
