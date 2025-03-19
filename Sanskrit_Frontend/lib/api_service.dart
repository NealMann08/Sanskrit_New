import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "http://127.0.0.1:5000"; // Your Flask backend URL
  static final http.Client client = http.Client();

  // ---------- Authentication Endpoints ----------

  // Signup
  static Future<Map<String, dynamic>> signup(String username, String password) async {
    final response = await client.post(
      Uri.parse('$baseUrl/signup'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Signup failed: ${response.body}");
    }
  }

  // Login with Cookie Storage
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await client.post(
      Uri.parse('$baseUrl/login'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );

    if (response.statusCode == 200) {
      // Save session cookies and username in SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final cookies = response.headers['set-cookie'];
      if (cookies != null) {
        await prefs.setString('session_cookie', cookies);
      }
      await prefs.setString('username', username);
      return jsonDecode(response.body);
    } else {
      throw Exception("Login failed: ${response.body}");
    }
  }

  // Logout
  static Future<void> logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionCookie = prefs.getString('session_cookie');

    final response = await client.post(
      Uri.parse('$baseUrl/logout'),
      headers: {
        "Content-Type": "application/json",
        if (sessionCookie != null) "Cookie": sessionCookie,
      },
    );

    if (response.statusCode == 200) {
      await prefs.remove('session_cookie'); // Clear session cookie
      await prefs.remove('username');
    } else {
      throw Exception("Logout failed: ${response.body}");
    }
  }

  // Check if User is Logged In
  static Future<bool> isLoggedIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionCookie = prefs.getString('session_cookie');

    final response = await client.get(
      Uri.parse('$baseUrl/status'),
      headers: {
        "Content-Type": "application/json",
        if (sessionCookie != null) "Cookie": sessionCookie,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['logged_in'] ?? false;
    }
    return false;
  }

  // Helper: Get logged-in username
  static Future<String?> getLoggedInUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  // ---------- Application Endpoints ----------

  // Fetch Fill-in-the-Blank Exercise
  static Future<Map<String, dynamic>> fetchFillInTheBlank() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionCookie = prefs.getString('session_cookie');

    final response = await client.get(
      Uri.parse('$baseUrl/fill-in-the-blank'),
      headers: {
        "Content-Type": "application/json",
        if (sessionCookie != null) "Cookie": sessionCookie,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load exercise");
    }
  }

  // Fetch Image Generation Exercise
  static Future<Map<String, dynamic>> fetchImageGeneration(String prompt) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionCookie = prefs.getString('session_cookie');

    final response = await client.post(
      Uri.parse('$baseUrl/generate-image'),
      headers: {
        "Content-Type": "application/json",
        if (sessionCookie != null) "Cookie": sessionCookie,
      },
      body: jsonEncode({"prompt": prompt}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to generate image");
    }
  }

  // Fetch Writing Analysis
  static Future<Map<String, dynamic>> fetchWritingAnalysis(String text) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionCookie = prefs.getString('session_cookie');

    final response = await client.post(
      Uri.parse('$baseUrl/writing-analysis'),
      headers: {
        "Content-Type": "application/json",
        if (sessionCookie != null) "Cookie": sessionCookie,
      },
      body: jsonEncode({"text": text}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to analyze writing");
    }
  }

  // Fetch Translation Exercise
  static Future<Map<String, dynamic>> fetchTranslationExercise() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionCookie = prefs.getString('session_cookie');

    final response = await client.get(
      Uri.parse('$baseUrl/translate'),
      headers: {
        "Content-Type": "application/json",
        if (sessionCookie != null) "Cookie": sessionCookie,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load translation exercise");
    }
  }
}