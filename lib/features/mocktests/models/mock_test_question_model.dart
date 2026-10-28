class MockTestQuestion {
  final String id;
  final String testId;
  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctOption;

  MockTestQuestion({
    required this.id,
    required this.testId,
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctOption,
  });

  factory MockTestQuestion.fromJson(Map<String, dynamic> json) {
    return MockTestQuestion(
      id: json['id'],
      testId: json['test_id'],
      questionText: json['question_text'],
      optionA: json['option_a'],
      optionB: json['option_b'],
      optionC: json['option_c'],
      optionD: json['option_d'],
      correctOption: json['correct_option'],
    );
  }
}
