class UsuarioModel {
  final String id;
  final String nombre;
  final String apellido;
  final String email;
  final String? perfilCultural;
  final String? tokenFCM;
  final DateTime? ultimaActividad;
  final bool activo;
  final DateTime fechaCreacion;

  UsuarioModel({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    this.perfilCultural,
    this.tokenFCM,
    this.ultimaActividad,
    this.activo = true,
    required this.fechaCreacion,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['id'] ?? json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      apellido: json['apellido'] ?? '',
      email: json['email'] ?? '',
      perfilCultural: json['perfilCultural'] ?? json['estiloComunicacion'],
      tokenFCM: _parseTokenFCM(json['tokenFCM']), // Parsear correctamente el tokenFCM
      ultimaActividad: json['ultimaActividad'] != null 
          ? DateTime.parse(json['ultimaActividad'])
          : null,
      activo: json['activo'] ?? true,
      fechaCreacion: json['fechaCreacion'] != null 
          ? DateTime.parse(json['fechaCreacion'])
          : DateTime.now(),
    );
  }

  // Helper method para parsear tokenFCM que puede ser String, List o null
  static String? _parseTokenFCM(dynamic tokenFCM) {
    if (tokenFCM == null) return null;
    if (tokenFCM is String) return tokenFCM.isEmpty ? null : tokenFCM;
    if (tokenFCM is List) {
      return tokenFCM.isNotEmpty ? tokenFCM.first?.toString() : null;
    }
    return tokenFCM.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'perfilCultural': perfilCultural,
      'tokenFCM': tokenFCM,
      'ultimaActividad': ultimaActividad?.toIso8601String(),
      'activo': activo,
      'fechaCreacion': fechaCreacion.toIso8601String(),
    };
  }

  String get nombreCompleto => '$nombre $apellido';

  // Calcula los días sin actividad
  int getDiasSinActividad() {
    if (ultimaActividad == null) return 0;
    return DateTime.now().difference(ultimaActividad!).inDays;
  }

  // Obtiene el estado del usuario basado en los días sin actividad
  EstadoUsuario getEstadoUsuario() {
    final dias = getDiasSinActividad();
    if (dias <= 1) return EstadoUsuario.alDia;
    if (dias <= 2) return EstadoUsuario.alertaAmarilla;
    return EstadoUsuario.alertaRoja;
  }
}

enum EstadoUsuario {
  alDia,
  alertaAmarilla,
  alertaRoja,
}

extension EstadoUsuarioExtension on EstadoUsuario {
  String get icono {
    switch (this) {
      case EstadoUsuario.alDia:
        return '✅';
      case EstadoUsuario.alertaAmarilla:
        return '⚠️';
      case EstadoUsuario.alertaRoja:
        return '🔴';
    }
  }

  String get descripcion {
    switch (this) {
      case EstadoUsuario.alDia:
        return 'Al día';
      case EstadoUsuario.alertaAmarilla:
        return '1-2 días sin actividad';
      case EstadoUsuario.alertaRoja:
        return '+2 días sin actividad';
    }
  }
}

// Perfiles culturales disponibles
enum PerfilCultural {
  latino,
  norteamericano,
  europeo,
  asiatico,
  africano,
  otro,
}

extension PerfilCulturalExtension on PerfilCultural {
  String get nombre {
    switch (this) {
      case PerfilCultural.latino:
        return 'Latino';
      case PerfilCultural.norteamericano:
        return 'Norteamericano';
      case PerfilCultural.europeo:
        return 'Europeo';
      case PerfilCultural.asiatico:
        return 'Asiático';
      case PerfilCultural.africano:
        return 'Africano';
      case PerfilCultural.otro:
        return 'Otro';
    }
  }

  List<String> get frasesMotivacionales {
    switch (this) {
      case PerfilCultural.latino:
        return [
          '¡Vamos! Tú puedes lograrlo 🔥',
          'El esfuerzo de hoy es el éxito de mañana 💪',
          '¡Dale que vas bien! ⭐',
          'Paso a paso se llega lejos 🚶‍♂️',
        ];
      case PerfilCultural.norteamericano:
        return [
          'You\'ve got this! Keep pushing 🚀',
          'Success is built one day at a time 📈',
          'Stay focused and keep moving forward ⚡',
          'Great progress! Keep it up! 🌟',
        ];
      case PerfilCultural.europeo:
        return [
          'Excellent progress! Continue like this 🎯',
          'Consistency is the key to success 🔑',
          'Well done! Keep up the good work 👏',
          'Step by step towards excellence 🏆',
        ];
      case PerfilCultural.asiatico:
        return [
          'Perseverance leads to achievement 🌸',
          'Small steps, great journey 🛤️',
          'Discipline brings success 📚',
          'Honor your commitment ⛩️',
        ];
      case PerfilCultural.africano:
        return [
          'Ubuntu: We grow together 🤝',
          'Strong roots, tall trees 🌳',
          'Community strength, individual growth 💫',
          'Together we achieve more 🦁',
        ];
      case PerfilCultural.otro:
        return [
          'Keep going, you\'re doing great! 🌟',
          'Progress is progress, no matter how small 📊',
          'Believe in yourself! 💪',
          'Every step counts! 👣',
        ];
    }
  }
}
