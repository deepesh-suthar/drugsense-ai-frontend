import 'dart:convert';
import 'dart:typed_data'; // ✅ IMPORTANT
import 'package:http/http.dart' as http;
import 'config/app_config.dart';
import 'user_manager.dart';

class ApiService {
  static final String _baseUrl = AppConfig.baseUrl;

  // ✅ REGISTER
  Future<bool> registerUser(String username, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Register Error: $e');
      return false;
    }
  }

  // ✅ LOGIN
  Future<String?> loginUser(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userId = data['id'].toString();
        UserManager().currentUserId = userId;
        return userId;
      }
      return null;
    } catch (e) {
      print('Login Error: $e');
      return null;
    }
  }

  // ✅ FIXED CHAT METHOD (supports WEB + MOBILE)
  Future<Map<String, dynamic>?> sendChatMessage(
      String message, {
        Uint8List? imageBytes, // ✅ CHANGED
      }) async {
    final userId = UserManager().currentUserId;

    if (userId == null) {
      print("Error: No user is logged in.");
      return null;
    }

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/chat/send'),
      );

      request.fields['userId'] = userId;
      request.fields['message'] = message;

      // ✅ HANDLE IMAGE (WEB SAFE)
      if (imageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            imageBytes,
            filename: 'image.jpg',
          ),
        );
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        return jsonDecode(responseBody);
      }

      print('Chat Error: ${response.statusCode}');
      return null;
    } catch (e) {
      print('Chat Send Error: $e');
      return null;
    }
  }

  // ✅ GET HISTORY
  Future<List<dynamic>?> getChatHistory() async {
    final userId = UserManager().currentUserId;

    if (userId == null) {
      print("Error: No user is logged in.");
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/history/$userId'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (e) {
      print('History Error: $e');
      return null;
    }
  }
}