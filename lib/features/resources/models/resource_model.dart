class ResourceModel {
  final String id;
  final String title;
  final String category;
  final String type;
  final String fileSizeOrDuration;
  final String fileUrl;
  final bool isPremium;
  final DateTime createdAt;
  final String targetExam;

  ResourceModel({
    required this.id,
    required this.title,
    required this.category,
    required this.type,
    required this.fileSizeOrDuration,
    required this.fileUrl,
    required this.isPremium,
    required this.createdAt,
    this.targetExam = 'Both',
  });

  factory ResourceModel.fromJson(Map<String, dynamic> json) {
    return ResourceModel(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      type: json['type'] as String,
      fileSizeOrDuration: json['file_size_or_duration'] as String,
      fileUrl: json['file_url'] as String,
      isPremium: json['is_premium'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      targetExam: json['target_exam'] as String? ?? 'Both',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'type': type,
      'file_size_or_duration': fileSizeOrDuration,
      'file_url': fileUrl,
      'is_premium': isPremium,
      'created_at': createdAt.toIso8601String(),
      'target_exam': targetExam,
    };
  }
}
