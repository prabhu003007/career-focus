class Topic {
  final String id;
  final String subjectId;
  final String? unitId;
  final String name;
  final bool completed;
  final DateTime? completedAt;

  const Topic({
    required this.id,
    required this.subjectId,
    this.unitId,
    required this.name,
    required this.completed,
    this.completedAt,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['_id']?.toString() ??
          json['id']?.toString() ??
          '',
      subjectId: json['subjectId']?.toString() ?? '',
      unitId: json['unitId']?.toString(),
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
      'unitId': unitId,
      'name': name,
      'completed': completed,
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}