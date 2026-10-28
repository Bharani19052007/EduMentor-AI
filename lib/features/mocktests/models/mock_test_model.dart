class MockTest {
  final String id;
  final String title;
  final String category;
  final String description;
  final int durationMins;
  final bool isRecommended;
  final DateTime createdAt;

  MockTest({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.durationMins,
    required this.isRecommended,
    required this.createdAt,
  });

  factory MockTest.fromJson(Map<String, dynamic> json) {
    return MockTest(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      durationMins: json['duration_mins'] as int,
      isRecommended: json['is_recommended'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'description': description,
      'duration_mins': durationMins,
      'is_recommended': isRecommended,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
