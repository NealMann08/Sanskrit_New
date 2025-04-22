import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  static const String baseUrl =
      "http://127.0.0.1:5000"; // Your Flask backend URL
  static final http.Client client = http.Client();
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ---------- Authentication Helpers ----------

  static Future<String?> _getAuthToken() async {
    User? user = _auth.currentUser;
    if (user != null) {
      return await user.getIdToken();
    }
    return null;
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await _getAuthToken();
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  // ---------- Application Endpoints ----------

  // Fetch Fill-in-the-Blank Exercise
  static Future<Map<String, dynamic>> fetchFillInTheBlank() async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/fill-in-the-blank'),
        headers: await _authHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Add null checks
        return {
          'exercise': data['exercise'] ?? 'Could not generate exercise',
          'choices': data['choices'] ?? [],
          'correct_answer': data['correct_answer'] ?? '1',
          'error': data['error'],
        };
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      return {
        'exercise': 'Service unavailable',
        'choices': [],
        'correct_answer': '1',
        'error': e.toString(),
      };
    }
  }

  // Fetch Image Generation Exercise
  static Future<Map<String, dynamic>> fetchImageGeneration(
    String prompt,
  ) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/generate-image'),
        headers: await _authHeaders(),
        body: jsonEncode({"prompt": prompt}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      throw "Failed to generate image: ${e.toString()}";
    }
  }

  static Future<Map<String, dynamic>> analyzeSanskritText(String text) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/analyze-text'),
        headers: await _authHeaders(),
        body: jsonEncode({'text': text}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> analyzeSanskritImage(
    String base64Image,
  ) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/analyze-image'),
        headers: await _authHeaders(),
        body: jsonEncode({'image_base64': base64Image}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw "Server error: ${response.statusCode}";
    }
  }

  // Fetch Translation Exercise
  static Future<Map<String, dynamic>> fetchTranslationExercise() async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/translation-exercise'),
        headers: await _authHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw "Server error: ${response.statusCode}";
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ---------- Error Handling ----------
  static String _handleError(http.Response response) {
    switch (response.statusCode) {
      case 400:
        return "Bad request: ${response.body}";
      case 401:
        return "Unauthorized - Please login again";
      case 403:
        return "Forbidden: ${response.body}";
      case 404:
        return "Resource not found";
      case 500:
        return "Server error: ${response.body}";
      default:
        return "Request failed with status ${response.statusCode}";
    }
  }
}
