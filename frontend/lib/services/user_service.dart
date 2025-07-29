import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart';

class UserService {
  static Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/usuario'),
        headers: await ApiService.authHeaders,
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al crear usuario: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/usuario'),
        headers: await ApiService.authHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Error al obtener usuarios: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<Map<String, dynamic>> getUserById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/usuario/$id'),
        headers: await ApiService.authHeaders,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al obtener usuario: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<Map<String, dynamic>> updateUser(String id, Map<String, dynamic> userData) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiService.baseUrl}/usuario/$id'),
        headers: await ApiService.authHeaders,
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al actualizar usuario: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<void> deleteUser(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/usuario/$id'),
        headers: await ApiService.authHeaders,
      );

      if (response.statusCode != 200) {
        throw Exception('Error al eliminar usuario: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<void> updateFCMToken(String userId, String tokenFCM) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiService.baseUrl}/usuario/tokenFCM/$userId'),
        headers: await ApiService.authHeaders,
        body: jsonEncode({'tokenFCM': tokenFCM}),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al actualizar token FCM: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
} 