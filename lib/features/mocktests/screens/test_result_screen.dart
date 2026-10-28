import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

class TestResultScreen extends StatelessWidget {
  final int score;
  final int total;
  final String testTitle;

  const TestResultScreen({
    super.key,
    required this.score,
    required this.total,
    required this.testTitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final percentage = total > 0 ? (score / total) * 100 : 0;
    
    // Determine feedback based on score
    String feedback = 'Good Effort!';
    Color feedbackColor = Colors.orange;
    IconData feedbackIcon = LucideIcons.star;
    
    if (percentage >= 80) {
      feedback = 'Outstanding!';
      feedbackColor = Colors.green;
      feedbackIcon = LucideIcons.award;
    } else if (percentage >= 50) {
      feedback = 'Well Done!';
      feedbackColor = Colors.blue;
      feedbackIcon = LucideIcons.thumbsUp;
    } else {
      feedback = 'Keep Practicing!';
      feedbackColor = Colors.red;
      feedbackIcon = LucideIcons.bookOpen;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Test Results'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Prevent going back to test
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: feedbackColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(feedbackIcon, size: 80, color: feedbackColor),
              ),
              const SizedBox(height: 32),
              Text(
                feedback,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: feedbackColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                testTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Your Score',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$score',
                          style: TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                            height: 1,
                          ),
                        ),
                        Text(
                          ' / $total',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black38,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: total > 0 ? score / total : 0,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(feedbackColor),
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: feedbackColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/mocktests'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Return to Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
