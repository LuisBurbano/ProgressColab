import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Para emulador Android (cambia a tu IP local)
  static const String baseUrl = 'http://192.168.18.14:3000/api/1.0';
  
  // Para iOS Simulator
  // static const String baseUrl = 'http://localhost:3000/api/1.0';
  
  // Para dispositivo físico (usa la IP de tu computadora)
  // static const String baseUrl = 'http://192.168.1.100:3000/api/1.0';
  
  // Headers comunes
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
  };
  
  // Headers con token de autenticación
  static Future<Map<String, String>> get authHeaders async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Test de conexión básica
  static Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/usuario/'),
        headers: headers,
      );
      print('Conexión exitosa: ${response.statusCode}');
      print('Respuesta: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error de conexión: $e');
      return false;
    }
  }
} 