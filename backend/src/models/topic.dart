class Topic {
  final String id;
  final String subjectId;
  final String name;
  final bool completed;
  final DateTime? completedAt;

  Topic({
    required this.id,
    required this.subjectId,
    required this.name,
    required this.completed,
    this.completedAt,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['_id']?.toString() ?? '',
      subjectId: json['subjectId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      completed: json['completed'] == true,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(
              json['completedAt'].toString(),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'subjectId': subjectId,
      'name': name,
      'completed': completed,
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}