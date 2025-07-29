import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../models/usuario_model.dart';
import 'dart:math';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // Inicializa el servicio de notificaciones
  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestCriticalPermission: true,
      requestProvisionalPermission: true,
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Manejar cuando el usuario toca la notificación
    print('Notificación tocada: ${response.payload}');
  }

  // Solicita permisos para notificaciones
  static Future<bool> requestPermissions() async {
    await initialize();
    
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    bool? granted = await androidPlugin?.requestNotificationsPermission();
    return granted ?? false;
  }

  // Programa notificaciones diarias para usuarios inactivos
  static Future<void> scheduleInactivityReminder(UsuarioModel usuario) async {
    await initialize();

    final perfilCultural = _getPerfilCultural(usuario.perfilCultural);
    final frases = perfilCultural.frasesMotivacionales;
    final fraseAleatoria = frases[Random().nextInt(frases.length)];

    const androidDetails = AndroidNotificationDetails(
      'inactivity_channel',
      'Recordatorios de Actividad',
      channelDescription: 'Notificaciones para recordar registrar avances',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      usuario.id.hashCode,
      '¡Hola ${usuario.nombre}! 👋',
      fraseAleatoria,
      notificationDetails,
      payload: 'inactivity_reminder_${usuario.id}',
    );
  }

  // Envía notificación personalizada según el perfil cultural
  static Future<void> sendCustomNotification({
    required String userId,
    required String title,
    required String body,
    PerfilCultural? perfilCultural,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'custom_channel',
      'Notificaciones Personalizadas',
      channelDescription: 'Notificaciones adaptadas al perfil cultural',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      userId.hashCode,
      title,
      body,
      notificationDetails,
      payload: 'custom_$userId',
    );
  }

  // Notificación motivacional con último avance
  static Future<void> sendMotivationalNotification({
    required UsuarioModel usuario,
    String? ultimoAvance,
  }) async {
    await initialize();

    final perfilCultural = _getPerfilCultural(usuario.perfilCultural);
    final frases = perfilCultural.frasesMotivacionales;
    final fraseAleatoria = frases[Random().nextInt(frases.length)];

    String body = fraseAleatoria;
    if (ultimoAvance != null && ultimoAvance.isNotEmpty) {
      body += '\n\nÚltimo avance: "$ultimoAvance"';
    }

    const androidDetails = AndroidNotificationDetails(
      'motivational_channel',
      'Notificaciones Motivacionales',
      channelDescription: 'Mensajes motivacionales personalizados',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      usuario.id.hashCode + 1000,
      '${_getIconoMotivacional(perfilCultural)} ¡Continúa así, ${usuario.nombre}!',
      body,
      notificationDetails,
      payload: 'motivational_${usuario.id}',
    );
  }

  // Notificación de alerta grupal
  static Future<void> sendGroupAlert({
    required String title,
    required String message,
    required String inactiveUserId,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'group_alert_channel',
      'Alertas Grupales',
      channelDescription: 'Alertas sobre inactividad de miembros del equipo',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFFF6B6B),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      inactiveUserId.hashCode + 2000,
      title,
      message,
      notificationDetails,
      payload: 'group_alert_$inactiveUserId',
    );
  }

  // Cancela todas las notificaciones de un usuario
  static Future<void> cancelUserNotifications(String userId) async {
    await _notifications.cancel(userId.hashCode);
    await _notifications.cancel(userId.hashCode + 1000);
    await _notifications.cancel(userId.hashCode + 2000);
  }

  // Cancela todas las notificaciones
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Helpers
  static PerfilCultural _getPerfilCultural(String? perfil) {
    switch (perfil?.toLowerCase()) {
      case 'latino':
        return PerfilCultural.latino;
      case 'norteamericano':
        return PerfilCultural.norteamericano;
      case 'europeo':
        return PerfilCultural.europeo;
      case 'asiatico':
        return PerfilCultural.asiatico;
      case 'africano':
        return PerfilCultural.africano;
      default:
        return PerfilCultural.otro;
    }
  }

  static String _getIconoMotivacional(PerfilCultural perfil) {
    switch (perfil) {
      case PerfilCultural.latino:
        return '🔥';
      case PerfilCultural.norteamericano:
        return '🚀';
      case PerfilCultural.europeo:
        return '🎯';
      case PerfilCultural.asiatico:
        return '🌸';
      case PerfilCultural.africano:
        return '🦁';
      case PerfilCultural.otro:
        return '⭐';
    }
  }

  // Guarda la preferencia de notificaciones del usuario
  static Future<void> setNotificationPreference(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
  }

  // Obtiene la preferencia de notificaciones del usuario
  static Future<bool> getNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }
}
