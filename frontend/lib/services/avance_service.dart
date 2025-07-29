import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart';

class AvanceService {
  static Future<Map<String, dynamic>> createAvance(String usuarioId, String descripcion) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/avance/crearAvance'),
        headers: await ApiService.authHeaders,
        body: jsonEncode({
          'usuarioId': usuarioId,
          'descripcion': descripcion,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al crear avance: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getAvances() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/avance/'),
        headers: await ApiService.authHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Error al obtener avances: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getAvancesByUser(String usuarioId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/avance/usuario/$usuarioId'),
        headers: await ApiService.authHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Error al obtener avances del usuario: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<Map<String, dynamic>> updateAvance(String id, Map<String, dynamic> avanceData) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiService.baseUrl}/avance/$id'),
        headers: await ApiService.authHeaders,
        body: jsonEncode(avanceData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al actualizar avance: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<void> deleteAvance(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/avance/$id'),
        headers: await ApiService.authHeaders,
      );

      if (response.statusCode != 200) {
        throw Exception('Error al eliminar avance: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
} 