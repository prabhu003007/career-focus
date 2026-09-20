class Unit {
  final String id;
  final String subjectId;
  final int unitNumber;
  final String name;
  final DateTime? createdAt;

  const Unit({
    required this.id,
    required this.subjectId,
    required this.unitNumber,
    required this.name,
    this.createdAt,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      subjectId: json['subjectId']?.toString() ?? '',
      unitNumber: int.tryParse(
            json['unitNumber']?.toString() ?? '',
          ) ??
          0,
      name: json['name']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(
              json['createdAt'].toString(),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'subjectId': subjectId,
      'unitNumber': unitNumber,
      'name': name,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}