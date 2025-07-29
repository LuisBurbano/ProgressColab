import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart';

class AvanceService {
  // Obtener usuarioId por email - Para resolver el problema de usuarioId vacío
  static Future<String?> getUsuarioIdByEmail(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/test/usuario-por-email'),
        headers: await ApiService.authHeaders,
        body: jsonEncode({
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['id']; // El ID está directamente en la respuesta, no en data['usuario']['id']
      } else {
        print('Error obteniendo usuario por email: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error de conexión obteniendo usuario: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> createAvance(String usuarioId, String descripcion) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/avance'),
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

  // Obtener estado de actividad de todos los usuarios - Endpoint del backend
  static Future<Map<String, dynamic>> getEstadoActividad() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/avance/estado-actividad'),
        headers: await ApiService.authHeaders,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al obtener estado de actividad: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión obteniendo estado: $e');
    }
  }

  // Método helper para crear avance usando email en lugar de usuarioId
  static Future<Map<String, dynamic>> createAvanceByEmail(String email, String descripcion) async {
    try {
      // Primero obtener el usuarioId usando el email
      String? usuarioId = await getUsuarioIdByEmail(email);
      
      if (usuarioId == null || usuarioId.isEmpty) {
        throw Exception('No se pudo obtener el ID del usuario con email: $email');
      }
      
      // Ahora crear el avance con el usuarioId correcto
      return await createAvance(usuarioId, descripcion);
    } catch (e) {
      throw Exception('Error creando avance por email: $e');
    }
  }

  // Método helper para obtener avances por email en lugar de usuarioId
  static Future<List<Map<String, dynamic>>> getAvancesByUserEmail(String email) async {
    try {
      // Primero obtener el usuarioId usando el email
      String? usuarioId = await getUsuarioIdByEmail(email);
      
      if (usuarioId == null || usuarioId.isEmpty) {
        throw Exception('No se pudo obtener el ID del usuario con email: $email');
      }
      
      // Ahora obtener los avances con el usuarioId correcto
      return await getAvancesByUser(usuarioId);
    } catch (e) {
      throw Exception('Error obteniendo avances por email: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getAvances() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/avance'),
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

  // Obtiene avances por rango de fechas
  static Future<List<Map<String, dynamic>>> getAvancesByDateRange(
    DateTime startDate, 
    DateTime endDate,
    {String? usuarioId}
  ) async {
    try {
      String url = '${ApiService.baseUrl}/avance/dateRange?start=${startDate.toIso8601String()}&end=${endDate.toIso8601String()}';
      if (usuarioId != null) {
        url += '&userId=$usuarioId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: await ApiService.authHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Error al obtener avances por fecha: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtiene el último avance de un usuario
  static Future<Map<String, dynamic>?> getUltimoAvanceByUser(String usuarioId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/avance/usuario/$usuarioId/ultimo'),
        headers: await ApiService.authHeaders,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        return null; // Usuario sin avances
      } else {
        throw Exception('Error al obtener último avance: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtiene estadísticas de avances por usuario
  static Future<Map<String, dynamic>> getEstadisticasAvancesByUser(String usuarioId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/avance/usuario/$usuarioId/estadisticas'),
        headers: await ApiService.authHeaders,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al obtener estadísticas: ${response.body}');
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

  // Marca a un usuario como activo (actualiza su última actividad)
  static Future<void> marcarUsuarioActivo(String usuarioId) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiService.baseUrl}/usuario/$usuarioId/ultimaActividad'),
        headers: await ApiService.authHeaders,
        body: jsonEncode({
          'ultimaActividad': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al marcar usuario activo: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
} 