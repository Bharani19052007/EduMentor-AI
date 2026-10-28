import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../mocktests/services/mock_test_service.dart';

class AdminCreateTestScreen extends StatefulWidget {
  const AdminCreateTestScreen({super.key});

  @override
  State<AdminCreateTestScreen> createState() => _AdminCreateTestScreenState();
}

class QuestionData {
  String question = '';
  String optionA = '';
  String optionB = '';
  String optionC = '';
  String optionD = '';
  String correctOption = 'A';
}

class _AdminCreateTestScreenState extends State<AdminCreateTestScreen> {
  final MockTestService _mockTestService = MockTestService();
  final _titleController = TextEditingController();
  final _durationController = TextEditingController(text: '180');
  String _subject = 'JEE Mains';
  
  final List<QuestionData> _questions = [QuestionData()];
  final _formKey = GlobalKey<FormState>();
  
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questions.add(QuestionData());
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  Future<void> _handleSaveTest() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      setState(() {
        _isSaving = true;
      });

      try {
        final testData = {
          'title': _titleController.text,
          'category': _subject,
          'description': 'A $_subject mock test.',
          'duration_mins': int.tryParse(_durationController.text) ?? 180,
          'is_recommended': false,
        };

        final questionsData = _questions.map((q) => {
          'question_text': q.question,
          'option_a': q.optionA,
          'option_b': q.optionB,
          'option_c': q.optionC,
          'option_d': q.optionD,
          'correct_option': q.correctOption,
        }).toList();

        await _mockTestService.createMockTestWithQuestions(
          testData: testData,
          questionsData: questionsData,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Test Created Successfully!'), backgroundColor: Colors.green),
          );
          context.pop(); // Returns to the previous screen which automatically refreshes
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save test: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Builder'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _handleSaveTest,
            icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(LucideIcons.save),
            tooltip: 'Save Test',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addQuestion,
        icon: const Icon(LucideIcons.plus),
        label: const Text('Add Question'),
      ),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Test Details', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Test Title',
                        hintText: 'e.g. Weekly Physics Mock',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(LucideIcons.type),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Title required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _subject,
                            decoration: const InputDecoration(
                              labelText: 'Target Exam',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(LucideIcons.target),
                            ),
                            items: ['JEE Mains', 'JEE Advanced', 'NEET'].map((s) {
                              return DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis));
                            }).toList(),
                            onChanged: (val) => setState(() => _subject = val!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _durationController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Duration (mins)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(LucideIcons.clock),
                            ),
                            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: Divider(thickness: 4)),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: _buildQuestionCard(index, colorScheme),
                  );
                },
                childCount: _questions.length,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  onPressed: _isSaving ? null : _handleSaveTest,
                  icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(LucideIcons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save Test', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)), // FAB spacing
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int index, ColorScheme colorScheme) {
    final q = _questions[index];
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Question ${index + 1}', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                ),
                if (_questions.length > 1)
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, color: Colors.red),
                    onPressed: () => _removeQuestion(index),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: q.question,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Question Text',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => q.question = val,
              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _buildOptionField('Option A', (val) => q.optionA = val, initialValue: q.optionA),
            const SizedBox(height: 8),
            _buildOptionField('Option B', (val) => q.optionB = val, initialValue: q.optionB),
            const SizedBox(height: 8),
            _buildOptionField('Option C', (val) => q.optionC = val, initialValue: q.optionC),
            const SizedBox(height: 8),
            _buildOptionField('Option D', (val) => q.optionD = val, initialValue: q.optionD),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: q.correctOption,
              decoration: const InputDecoration(
                labelText: 'Correct Answer',
                border: OutlineInputBorder(),
              ),
              items: ['A', 'B', 'C', 'D'].map((s) {
                return DropdownMenuItem(value: s, child: Text('Option $s'));
              }).toList(),
              onChanged: (val) {
                setState(() => q.correctOption = val!);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionField(String label, Function(String) onChanged, {String initialValue = ''}) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
    );
  }
}
