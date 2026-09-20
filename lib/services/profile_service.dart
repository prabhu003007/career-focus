import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ProfileService {
  static const String baseUrl =
      'http://10.146.105.100:5000/api';

  Future<Map<String, dynamic>> getProfile(
    String token,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/profile',
            ),
            headers: {
              'Authorization':
                  'Bearer $token',
            },
          )
          .timeout(
            const Duration(
              seconds: 10,
            ),
          );

      return _handleResponse(response);
    } on TimeoutException {
      throw Exception(
        'Profile server connection timed out.',
      );
    } on SocketException {
      throw Exception(
        'Cannot connect to Career Focus server.',
      );
    }
  }

  Future<Map<String, dynamic>>
      updateProfile(
    String token, {
    required String name,
    required String collegeName,
    required String degree,
    required String course,
    required int academicYear,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse(
              '$baseUrl/profile',
            ),
            headers: {
              'Authorization':
                  'Bearer $token',
              'Content-Type':
                  'application/json',
            },
            body: jsonEncode({
              'name': name,
              'collegeName':
                  collegeName,
              'degree': degree,
              'course': course,
              'academicYear':
                  academicYear,
            }),
          )
          .timeout(
            const Duration(
              seconds: 10,
            ),
          );

      return _handleResponse(response);
    } on TimeoutException {
      throw Exception(
        'Profile update timed out.',
      );
    } on SocketException {
      throw Exception(
        'Cannot connect to Career Focus server.',
      );
    }
  }

  Map<String, dynamic> _handleResponse(
    http.Response response,
  ) {
    dynamic decoded;

    try {
      decoded =
          jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        'Invalid server response.',
      );
    }

    if (decoded
        is! Map<String, dynamic>) {
      throw Exception(
        'Unexpected server response.',
      );
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return decoded;
    }

    throw Exception(
      decoded['message']
              ?.toString() ??
          'Profile request failed.',
    );
  }
}