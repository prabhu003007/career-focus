import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/subject.dart';
import '../models/topic.dart';
import '../models/unit.dart';

class ApiService {
  static const String baseUrl =
      'http://10.146.105.100:5000/api';

  // ============================================================
  // HEADERS
  // ============================================================

  Map<String, String> _headers({
    String? token,
  }) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // ============================================================
  // RESPONSE HANDLER
  // ============================================================

  Map<String, dynamic> _handleResponse(
    http.Response response,
  ) {
    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        'Invalid server response (${response.statusCode}).',
      );
    }

    if (decoded is! Map) {
      throw Exception(
        'Unexpected server response (${response.statusCode}).',
      );
    }

    final data = Map<String, dynamic>.from(decoded);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return data;
    }

    throw Exception(
      data['message']?.toString() ??
          'Request failed (${response.statusCode}).',
    );
  }

  // ============================================================
  // AUTHENTICATION
  // ============================================================

  Future<Map<String, dynamic>> sendVerification(
    String email,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/send-verification'),
      headers: _headers(),
      body: jsonEncode({
        'email': email,
      }),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> verifyEmail(
    String email,
    String code,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-email'),
      headers: _headers(),
      body: jsonEncode({
        'email': email,
        'code': code,
      }),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> createPin(
    String email,
    String verificationToken,
    String pin,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/create-pin'),
      headers: _headers(),
      body: jsonEncode({
        'email': email,
        'verificationToken': verificationToken,
        'pin': pin,
      }),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> login(
    String email,
    String pin,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers(),
      body: jsonEncode({
        'email': email,
        'pin': pin,
      }),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> sendPinReset(
    String email,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-pin'),
      headers: _headers(),
      body: jsonEncode({
        'email': email,
      }),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> verifyPinReset(
    String email,
    String code,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-pin-reset'),
      headers: _headers(),
      body: jsonEncode({
        'email': email,
        'code': code,
      }),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> resetPin(
    String email,
    String resetToken,
    String pin,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-pin'),
      headers: _headers(),
      body: jsonEncode({
        'email': email,
        'resetToken': resetToken,
        'pin': pin,
      }),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getMe(
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: _headers(token: token),
    );

    return _handleResponse(response);
  }

  // ============================================================
  // SUBJECTS
  // ============================================================

  Future<List<Subject>> getSubjects(
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/subjects'),
      headers: _headers(token: token),
    );

    final data = _handleResponse(response);

    final raw = data['subjects'];

    final List<dynamic> items =
        raw is List ? raw : [];

    return items
        .whereType<Map>()
        .map(
          (item) => Subject.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<Subject> createSubject(
    String token, {
    required String name,
    String? code,
    String? description,
    int? assess1,
    int? assess2,
    int? endSem,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/subjects'),
      headers: _headers(token: token),
      body: jsonEncode({
        'name': name,
        'code': ?code,
'description': ?description,
        'exams': {
          'assess1': assess1,
          'assess2': assess2,
          'endSem': endSem,
        },
      }),
    );

    final data = _handleResponse(response);

    final subjectData =
        data['subject'] ?? data;

    return Subject.fromJson(
      Map<String, dynamic>.from(subjectData),
    );
  }

  Future<Subject> updateSubject(
    String token,
    String subjectId, {
    String? name,
    String? code,
    String? description,
    int? assess1,
    int? assess2,
    int? endSem,
  }) async {
    final body = <String, dynamic>{};

    if (name != null) {
      body['name'] = name;
    }

    if (code != null) {
      body['code'] = code;
    }

    if (description != null) {
      body['description'] = description;
    }

    if (assess1 != null ||
        assess2 != null ||
        endSem != null) {
      body['exams'] = {
        'assess1': assess1,
        'assess2': assess2,
        'endSem': endSem,
      };
    }

    final response = await http.put(
      Uri.parse(
        '$baseUrl/subjects/$subjectId',
      ),
      headers: _headers(token: token),
      body: jsonEncode(body),
    );

    final data = _handleResponse(response);

    final subjectData =
        data['subject'] ?? data;

    return Subject.fromJson(
      Map<String, dynamic>.from(subjectData),
    );
  }

  Future<void> deleteSubject(
    String token,
    String subjectId,
  ) async {
    final response = await http.delete(
      Uri.parse(
        '$baseUrl/subjects/$subjectId',
      ),
      headers: _headers(token: token),
    );

    _handleResponse(response);
  }

  // ============================================================
  // UNITS
  // ============================================================

  Future<List<Unit>> getUnitsBySubject(
    String token,
    String subjectId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/units/subject/$subjectId',
      ),
      headers: _headers(token: token),
    );

    final data = _handleResponse(response);

    final raw = data['units'];

    final List<dynamic> items =
        raw is List ? raw : [];

    return items
        .whereType<Map>()
        .map(
          (item) => Unit.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<Unit> createUnit(
    String token, {
    required String subjectId,
    required int unitNumber,
    required String name,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/units'),
      headers: _headers(token: token),
      body: jsonEncode({
        'subjectId': subjectId,
        'unitNumber': unitNumber,
        'name': name,
      }),
    );

    final data = _handleResponse(response);

    final unitData =
        data['unit'] ?? data;

    return Unit.fromJson(
      Map<String, dynamic>.from(unitData),
    );
  }

  Future<Unit> updateUnit(
    String token,
    String unitId, {
    int? unitNumber,
    String? name,
  }) async {
    final body = <String, dynamic>{};

    if (unitNumber != null) {
      body['unitNumber'] = unitNumber;
    }

    if (name != null) {
      body['name'] = name;
    }

    final response = await http.put(
      Uri.parse('$baseUrl/units/$unitId'),
      headers: _headers(token: token),
      body: jsonEncode(body),
    );

    final data = _handleResponse(response);

    final unitData =
        data['unit'] ?? data;

    return Unit.fromJson(
      Map<String, dynamic>.from(unitData),
    );
  }

  Future<void> deleteUnit(
    String token,
    String unitId,
  ) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/units/$unitId'),
      headers: _headers(token: token),
    );

    _handleResponse(response);
  }

  // ============================================================
  // TOPICS
  // ============================================================

  Future<List<Topic>> getTopicsBySubject(
    String token,
    String subjectId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/topics/subject/$subjectId',
      ),
      headers: _headers(token: token),
    );

    final data = _handleResponse(response);

    final raw = data['topics'];

    final List<dynamic> items =
        raw is List ? raw : [];

    return items
        .whereType<Map>()
        .map(
          (item) => Topic.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<List<Topic>> getTopicsByUnit(
    String token,
    String unitId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/topics/unit/$unitId',
      ),
      headers: _headers(token: token),
    );

    final data = _handleResponse(response);

    final raw = data['topics'];

    final List<dynamic> items =
        raw is List ? raw : [];

    return items
        .whereType<Map>()
        .map(
          (item) => Topic.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<Topic> createTopic(
    String token, {
    required String subjectId,
    String? unitId,
    required String name,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/topics'),
      headers: _headers(token: token),
      body: jsonEncode({
        'subjectId': subjectId,
        'unitId': ?unitId,
        'name': name,
      }),
    );

    final data = _handleResponse(response);

    final topicData =
        data['topic'] ?? data;

    return Topic.fromJson(
      Map<String, dynamic>.from(topicData),
    );
  }

  Future<Topic> updateTopic(
    String token,
    String topicId, {
    String? name,
    bool? completed,
  }) async {
    final body = <String, dynamic>{};

    if (name != null) {
      body['name'] = name;
    }

    if (completed != null) {
      body['completed'] = completed;
    }

    final response = await http.put(
      Uri.parse('$baseUrl/topics/$topicId'),
      headers: _headers(token: token),
      body: jsonEncode(body),
    );

    final data = _handleResponse(response);

    final topicData =
        data['topic'] ?? data;

    return Topic.fromJson(
      Map<String, dynamic>.from(topicData),
    );
  }

  Future<void> deleteTopic(
    String token,
    String topicId,
  ) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/topics/$topicId'),
      headers: _headers(token: token),
    );

    _handleResponse(response);
  }

  // ============================================================
  // PROGRESS
  // ============================================================

  Future<List<dynamic>> getProgress(
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/progress'),
      headers: _headers(token: token),
    );

    final data = _handleResponse(response);

    final progress = data['progress'];

    if (progress is List) {
      return List<dynamic>.from(progress);
    }

    return <dynamic>[];
  }

  // ============================================================
  // CURRENT / LEGACY SCHEDULE
  // ============================================================

  Future<Map<String, dynamic>?> getSchedule(
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/schedule'),
      headers: _headers(token: token),
    );

    final data = _handleResponse(response);

    if (data['schedule'] == null) {
      return null;
    }

    return Map<String, dynamic>.from(
      data['schedule'],
    );
  }

  /*
   * Kept for compatibility with the current
   * ScheduleScreen.
   *
   * The new planner uses generateStudyPlan().
   */
  Future<Map<String, dynamic>> generateSchedule(
    String token, {
    required String startDate,
    required String deadline,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/schedule/generate'),
      headers: _headers(token: token),
      body: jsonEncode({
        'startDate': startDate,
        'deadline': deadline,
      }),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> completeScheduledTopic(
    String token, {
    required String topicId,
    required String date,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/schedule/complete'),
      headers: _headers(token: token),
      body: jsonEncode({
        'topicId': topicId,
        'date': date,
      }),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> skipRemainingTopics(
    String token, {
    required String date,
    bool allowOverCapacity = false,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/schedule/skip-remaining'),
      headers: _headers(token: token),
      body: jsonEncode({
        'date': date,
        'allowOverCapacity': allowOverCapacity,
      }),
    );

    return _handleResponse(response);
  }

  // ============================================================
  // NEW MULTI-SUBJECT STUDY PLAN
  // ============================================================

  Future<Map<String, dynamic>> generateStudyPlan(
    String token, {
    required List<Map<String, dynamic>> subjects,
    bool allowOverCapacity = false,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/schedule/generate'),
      headers: _headers(token: token),
      body: jsonEncode({
        'subjects': subjects,
        'allowOverCapacity': allowOverCapacity,
      }),
    );

    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        'Invalid server response (${response.statusCode}).',
      );
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      throw Exception(
        'Unexpected study-plan response.',
      );
    }

    if (decoded is Map &&
        decoded['code'] == 'DEADLINE_PRESSURE') {
      throw SchedulePressureException(
        message:
            decoded['message']?.toString() ??
                'The deadline is approaching and the remaining topics require additional scheduling capacity.',
        pressure: decoded['pressure'] is List
            ? List<dynamic>.from(
                decoded['pressure'],
              )
            : const [],
      );
    }

    if (decoded is Map) {
      throw Exception(
        decoded['message']?.toString() ??
            'Failed to generate study plan.',
      );
    }

    throw Exception(
      'Failed to generate study plan.',
    );
  }

  // ============================================================
  // ACADEMIC COPILOT
  // ============================================================

  Future<Map<String, dynamic>> sendAcademicCopilot(
    String token,
    String question,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ai/copilot'),
      headers: _headers(token: token),
      body: jsonEncode({
        'question': question,
      }),
    );

    return _handleResponse(response);
  }
}

// ================================================================
// DEADLINE PRESSURE
// ================================================================

class SchedulePressureException
    implements Exception {
  final String message;
  final List<dynamic> pressure;

  const SchedulePressureException({
    required this.message,
    required this.pressure,
  });

  @override
  String toString() => message;
}