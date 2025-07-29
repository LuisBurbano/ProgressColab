class AvanceModel {
  final String id;
  final String usuarioId;
  final String descripcion;
  final DateTime fechaHora;
  final String alerta;
  final bool activo;

  AvanceModel({
    required this.id,
    required this.usuarioId,
    required this.descripcion,
    required this.fechaHora,
    this.alerta = 'ninguna',
    this.activo = true,
  });

  factory AvanceModel.fromJson(Map<String, dynamic> json) {
    return AvanceModel(
      id: json['id'] ?? '',
      usuarioId: json['usuarioId'] ?? '',
      descripcion: json['descripcion'] ?? '',
      fechaHora: DateTime.parse(json['fechaHora']),
      alerta: json['alerta'] ?? 'ninguna',
      activo: json['activo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuarioId': usuarioId,
      'descripcion': descripcion,
      'fechaHora': fechaHora.toIso8601String(),
      'alerta': alerta,
      'activo': activo,
    };
  }

  // Calcula los días sin actividad desde la fecha de creación
  int getDiasSinActividad() {
    return DateTime.now().difference(fechaHora).inDays;
  }

  // Obtiene el estado del avance basado en los días sin actividad
  EstadoAvance getEstadoAvance() {
    final dias = getDiasSinActividad();
    if (dias == 0) return EstadoAvance.alDia;
    if (dias == 1) return EstadoAvance.alertaAmarilla;
    return EstadoAvance.alertaRoja;
  }
}

enum EstadoAvance {
  alDia,
  alertaAmarilla,
  alertaRoja,
}

extension EstadoAvanceExtension on EstadoAvance {
  String get icono {
    switch (this) {
      case EstadoAvance.alDia:
        return '✅';
      case EstadoAvance.alertaAmarilla:
        return '⚠️';
      case EstadoAvance.alertaRoja:
        return '🔴';
    }
  }

  String get descripcion {
    switch (this) {
      case EstadoAvance.alDia:
        return 'Al día';
      case EstadoAvance.alertaAmarilla:
        return '1 día sin actividad';
      case EstadoAvance.alertaRoja:
        return '+2 días sin actividad';
    }
  }
}
