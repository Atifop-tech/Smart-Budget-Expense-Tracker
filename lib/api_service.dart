import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:5000',
    );

  static Future<Map<String, dynamic>> predict(String sms) async {
    final url = Uri.parse('$_defaultBaseUrl/predict');
    Object? lastError;

    for (var attempt = 1; attempt <= 2; attempt++) {
      try {
        debugPrint('Prediction request attempt $attempt to $url');

        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'sms': sms}),
            )
            .timeout(const Duration(seconds: 10));

        debugPrint(
          'Prediction response: ${response.statusCode} ${response.body}',
        );

        if (response.statusCode != 200) {
          throw Exception(
            'Prediction API returned status ${response.statusCode}',
          );
        }

        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Prediction API returned invalid JSON.');
        }

        return decoded;
      } on TimeoutException catch (error) {
        lastError = error;
        debugPrint('Prediction request timed out on attempt $attempt.');
      } catch (error, stackTrace) {
        lastError = error;
        debugPrint('Prediction request failed on attempt $attempt: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    throw Exception(
      'Prediction API unavailable at $_defaultBaseUrl. Last error: $lastError',
    );
  }
}
