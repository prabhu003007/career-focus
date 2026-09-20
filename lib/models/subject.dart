class ExamMarks {
  final double? assess1;
  final double? assess2;
  final double? endSem;

  const ExamMarks({
    this.assess1,
    this.assess2,
    this.endSem,
  });

  factory ExamMarks.fromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return const ExamMarks();
    }

    return ExamMarks(
      assess1: _parse(json['assess1']),
      assess2: _parse(json['assess2']),
      endSem: _parse(json['endSem']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assess1': assess1,
      'assess2': assess2,
      'endSem': endSem,
    };
  }

  static double? _parse(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  double get average {
    final values = [
      assess1,
      assess2,
      endSem,
    ].whereType<double>().toList();

    if (values.isEmpty) return 0;

    return values.reduce((a, b) => a + b) /
        values.length;
  }

  int get availableCount {
    return [
      assess1,
      assess2,
      endSem,
    ].whereType<double>().length;
  }
}

class Subject {
  final String id;
  final String name;
  final String code;
  final String description;
  final ExamMarks exams;

  const Subject({
    required this.id,
    required this.name,
    this.code = '',
    this.description = '',
    this.exams = const ExamMarks(),
  });

  factory Subject.fromJson(
    Map<String, dynamic> json,
  ) {
    return Subject(
      id: json['_id']?.toString() ??
          json['id']?.toString() ??
          '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      description:
          json['description']?.toString() ?? '',
      exams: ExamMarks.fromJson(
        json['exams'] is Map
            ? Map<String, dynamic>.from(
                json['exams'],
              )
            : null,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'code': code,
      'description': description,
      'exams': exams.toJson(),
    };
  }
}