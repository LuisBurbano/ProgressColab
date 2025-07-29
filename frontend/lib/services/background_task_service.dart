import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';
import '../services/estadisticas_service.dart' as stats;

class BackgroundTaskService {
  static const String _taskName = 'check_inactive_users';
  static const String _dailyReminderTask = 'daily_reminder';

  // Inicializar el servicio de tareas en segundo plano
  static Future<void> initialize() async {
    // Solo inicializar en plataformas móviles (Android/iOS)
    if (kIsWeb) {
      print('Background tasks no disponibles en web');
      return;
    }
    
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false, // Cambiar a false en producción
      );
    } catch (e) {
      print('Error inicializando background tasks: $e');
    }
  }

  // Programar verificación de usuarios inactivos cada hora
  static Future<void> scheduleInactivityCheck() async {
    if (kIsWeb) return; // No disponible en web
    
    try {
      await Workmanager().registerPeriodicTask(
        _taskName,
        _taskName,
        frequency: const Duration(hours: 1),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
    } catch (e) {
      print('Error programando verificación de inactividad: $e');
    }
  }

  // Programar recordatorios diarios
  static Future<void> scheduleDailyReminders() async {
    if (kIsWeb) return; // No disponible en web
    
    try {
      await Workmanager().registerPeriodicTask(
        _dailyReminderTask,
        _dailyReminderTask,
        frequency: const Duration(hours: 24),
        initialDelay: _getTimeUntilNextReminder(),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
    } catch (e) {
      print('Error programando recordatorios diarios: $e');
    }
  }

  // Calcular tiempo hasta el próximo recordatorio (ej: 9:00 AM)
  static Duration _getTimeUntilNextReminder() {
    final now = DateTime.now();
    var nextReminder = DateTime(now.year, now.month, now.day, 9, 0); // 9:00 AM
    
    if (nextReminder.isBefore(now)) {
      nextReminder = nextReminder.add(const Duration(days: 1));
    }
    
    return nextReminder.difference(now);
  }

  // Cancelar todas las tareas
  static Future<void> cancelAllTasks() async {
    if (kIsWeb) return; // No disponible en web
    
    try {
      await Workmanager().cancelAll();
    } catch (e) {
      print('Error cancelando tareas: $e');
    }
  }

  // Cancelar una tarea específica
  static Future<void> cancelTask(String taskName) async {
    if (kIsWeb) return; // No disponible en web
    
    try {
      await Workmanager().cancelByUniqueName(taskName);
    } catch (e) {
      print('Error cancelando tarea $taskName: $e');
    }
  }
}

// Dispatcher para manejar las tareas en segundo plano
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      switch (task) {
        case BackgroundTaskService._taskName:
          await _checkInactiveUsers();
          break;
        case BackgroundTaskService._dailyReminderTask:
          await _sendDailyReminders();
          break;
        default:
          break;
      }
      return Future.value(true);
    } catch (e) {
      print('Error en tarea en segundo plano: $e');
      return Future.value(false);
    }
  });
}

// Verificar usuarios inactivos y enviar alertas
Future<void> _checkInactiveUsers() async {
  try {
    // Verificar si las notificaciones están habilitadas
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    
    if (!notificationsEnabled) return;

    // Obtener usuarios inactivos
    final usuariosInactivos = await stats.EstadisticasService.getUsuariosInactivos();
    
    for (final usuarioInactivo in usuariosInactivos) {
      // Enviar alerta grupal solo para usuarios con más de 2 días de inactividad
      if (usuarioInactivo.diasSinActividad >= 2) {
        await _sendGroupAlert(usuarioInactivo);
      }
      // Enviar recordatorio personal para usuarios con 1+ día de inactividad
      else if (usuarioInactivo.diasSinActividad >= 1) {
        await NotificationService.scheduleInactivityReminder(usuarioInactivo.usuario);
      }
    }
  } catch (e) {
    print('Error al verificar usuarios inactivos: $e');
  }
}

// Enviar recordatorios diarios a usuarios
Future<void> _sendDailyReminders() async {
  try {
    // Verificar si las notificaciones están habilitadas
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    
    if (!notificationsEnabled) return;

    // Obtener usuarios inactivos para enviar recordatorios
    final usuariosInactivos = await stats.EstadisticasService.getUsuariosInactivos();
    
    for (final usuarioInactivo in usuariosInactivos) {
      if (usuarioInactivo.diasSinActividad >= 1) {
        await NotificationService.sendMotivationalNotification(
          usuario: usuarioInactivo.usuario,
          ultimoAvance: usuarioInactivo.ultimoAvance?.descripcion,
        );
      }
    }
  } catch (e) {
    print('Error al enviar recordatorios diarios: $e');
  }
}

// Enviar alerta grupal para usuario inactivo
Future<void> _sendGroupAlert(stats.UsuarioInactivo usuarioInactivo) async {
  try {
    final usuario = usuarioInactivo.usuario;
    final dias = usuarioInactivo.diasSinActividad;
    final perfil = usuario.perfilCultural ?? 'otro';
    
    String mensaje = _generateGroupMessage(usuario.nombre, dias, perfil);
    
    await NotificationService.sendGroupAlert(
      title: '📢 Atención del Equipo',
      message: mensaje,
      inactiveUserId: usuario.id,
    );
  } catch (e) {
    print('Error al enviar alerta grupal: $e');
  }
}

// Generar mensaje grupal según el contexto cultural
String _generateGroupMessage(String nombre, int dias, String perfil) {
  final Map<String, List<String>> messagesByProfile = {
    'latino': [
      '$nombre necesita nuestro apoyo como familia. Lleva $dias días sin registrar avances.',
      'Como equipo unido, extendamos la mano a $nombre que no ha estado activo por $dias días.',
    ],
    'norteamericano': [
      '$nombre has been inactive for $dias days. Team support is needed.',
      'Let\'s reach out to $nombre who hasn\'t logged progress in $dias days.',
    ],
    'europeo': [
      '$nombre requires team assistance after $dias days of inactivity.',
      'Collaborative support needed for $nombre ($dias days inactive).',
    ],
    'asiatico': [
      'Equipo: $nombre necesita apoyo respetuoso tras $dias días sin actividad.',
      'Con paciencia y comprensión, apoyemos a $nombre ($dias días).',
    ],
    'africano': [
      'Ubuntu: $nombre necesita apoyo comunitario ($dias días sin actividad).',
      'Como comunidad, cuidemos a $nombre que lleva $dias días inactivo.',
    ],
  };
  
  final messages = messagesByProfile[perfil.toLowerCase()] ?? 
                  messagesByProfile['otro'] ?? 
                  ['$nombre needs team support after $dias days of inactivity.'];
  
  return messages[dias % messages.length];
}
