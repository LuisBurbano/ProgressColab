import '../models/avance_model.dart';
import '../models/usuario_model.dart';
import 'avance_service.dart';
import 'user_service.dart';

class EstadisticasService {
  
  // Obtiene estadísticas completas del grupo
  static Future<EstadisticasGrupo> getEstadisticasGrupo() async {
    try {
      // Obtener todos los usuarios y avances
      final usuarios = await UserService.getUsers();
      final avances = await AvanceService.getAvances();

      // Convertir a modelos
      final usuariosModelo = usuarios.map((u) => UsuarioModel.fromJson(u)).toList();
      final avancesModelo = avances.map((a) => AvanceModel.fromJson(a)).toList();

      return _calcularEstadisticasGrupo(usuariosModelo, avancesModelo);
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  // Obtiene estadísticas de un usuario específico
  static Future<EstadisticasUsuario> getEstadisticasUsuario(String usuarioId) async {
    try {
      final avances = await AvanceService.getAvancesByUser(usuarioId);
      final avancesModelo = avances.map((a) => AvanceModel.fromJson(a)).toList();

      return _calcularEstadisticasUsuario(avancesModelo);
    } catch (e) {
      throw Exception('Error al obtener estadísticas del usuario: $e');
    }
  }

  // Genera reporte semanal
  static Future<ReporteSemanal> generateReporteSemanal() async {
    try {
      final now = DateTime.now();
      final inicioSemana = now.subtract(Duration(days: now.weekday - 1));
      final finSemana = inicioSemana.add(const Duration(days: 6));

      final usuarios = await UserService.getUsers();
      final avances = await AvanceService.getAvances();

      final usuariosModelo = usuarios.map((u) => UsuarioModel.fromJson(u)).toList();
      final avancesModelo = avances.map((a) => AvanceModel.fromJson(a)).toList();

      // Filtrar avances de la semana
      final avancesSemana = avancesModelo.where((avance) {
        return avance.fechaHora.isAfter(inicioSemana.subtract(const Duration(days: 1))) &&
               avance.fechaHora.isBefore(finSemana.add(const Duration(days: 1)));
      }).toList();

      return _generarReporteSemanal(usuariosModelo, avancesSemana, inicioSemana, finSemana);
    } catch (e) {
      throw Exception('Error al generar reporte semanal: $e');
    }
  }

  // Obtiene usuarios inactivos
  static Future<List<UsuarioInactivo>> getUsuariosInactivos() async {
    try {
      final usuarios = await UserService.getUsers();
      final usuariosModelo = usuarios.map((u) => UsuarioModel.fromJson(u)).toList();
      
      final usuariosInactivos = <UsuarioInactivo>[];
      
      for (final usuario in usuariosModelo) {
        final avances = await AvanceService.getAvancesByUser(usuario.id);
        if (avances.isEmpty) {
          usuariosInactivos.add(UsuarioInactivo(
            usuario: usuario,
            diasSinActividad: usuario.getDiasSinActividad(),
            ultimoAvance: null,
          ));
          continue;
        }

        final ultimoAvance = avances
            .map((a) => AvanceModel.fromJson(a))
            .reduce((a, b) => a.fechaHora.isAfter(b.fechaHora) ? a : b);

        final diasSinActividad = DateTime.now().difference(ultimoAvance.fechaHora).inDays;
        
        if (diasSinActividad > 1) {
          usuariosInactivos.add(UsuarioInactivo(
            usuario: usuario,
            diasSinActividad: diasSinActividad,
            ultimoAvance: ultimoAvance,
          ));
        }
      }

      return usuariosInactivos;
    } catch (e) {
      throw Exception('Error al obtener usuarios inactivos: $e');
    }
  }

  // Sugiere prácticas de colaboración
  static Future<List<SugerenciaColaboracion>> getSugerenciasColaboracion() async {
    try {
      final estadisticas = await getEstadisticasGrupo();
      final sugerencias = <SugerenciaColaboracion>[];

      // Sugerencias basadas en inactividad
      if (estadisticas.porcentajeInactivos > 30) {
        sugerencias.add(SugerenciaColaboracion(
          tipo: TipoSugerencia.comunicacion,
          titulo: 'Mejorar Comunicación del Equipo',
          descripcion: 'Alto porcentaje de miembros inactivos. Considera implementar reuniones diarias de seguimiento.',
          prioridad: Prioridad.alta,
        ));
      }

      // Sugerencias basadas en productividad
      if (estadisticas.promedioAvancesPorUsuario < 3) {
        sugerencias.add(SugerenciaColaboracion(
          tipo: TipoSugerencia.productividad,
          titulo: 'Establecer Metas Más Claras',
          descripcion: 'La productividad promedio es baja. Define objetivos específicos y medibles.',
          prioridad: Prioridad.media,
        ));
      }

      // Sugerencias basadas en tendencias
      if (estadisticas.tendenciaActividad == TendenciaActividad.decreciente) {
        sugerencias.add(SugerenciaColaboracion(
          tipo: TipoSugerencia.motivacion,
          titulo: 'Implementar Sistema de Reconocimiento',
          descripcion: 'La actividad del equipo está disminuyendo. Considera celebrar logros y reconocer esfuerzos.',
          prioridad: Prioridad.alta,
        ));
      }

      return sugerencias;
    } catch (e) {
      throw Exception('Error al obtener sugerencias: $e');
    }
  }

  // Métodos privados para cálculos
  static EstadisticasGrupo _calcularEstadisticasGrupo(
    List<UsuarioModel> usuarios, 
    List<AvanceModel> avances
  ) {
    final totalUsuarios = usuarios.length;
    final totalAvances = avances.length;
    
    // Calcular usuarios por estado
    final usuariosAlDia = usuarios.where((u) => u.getEstadoUsuario() == EstadoUsuario.alDia).length;
    final usuariosAlertaAmarilla = usuarios.where((u) => u.getEstadoUsuario() == EstadoUsuario.alertaAmarilla).length;
    final usuariosAlertaRoja = usuarios.where((u) => u.getEstadoUsuario() == EstadoUsuario.alertaRoja).length;

    // Calcular promedios
    final promedioAvancesPorUsuario = totalUsuarios > 0 ? totalAvances / totalUsuarios : 0.0;
    final promedioDiasSinActividad = usuarios.isEmpty ? 0.0 : 
        usuarios.map((u) => u.getDiasSinActividad()).reduce((a, b) => a + b) / usuarios.length;

    // Calcular tendencia
    final tendencia = _calcularTendenciaActividad(avances);

    return EstadisticasGrupo(
      totalUsuarios: totalUsuarios,
      usuariosAlDia: usuariosAlDia,
      usuariosAlertaAmarilla: usuariosAlertaAmarilla,
      usuariosAlertaRoja: usuariosAlertaRoja,
      totalAvances: totalAvances,
      promedioAvancesPorUsuario: promedioAvancesPorUsuario,
      promedioDiasSinActividad: promedioDiasSinActividad,
      porcentajeInactivos: totalUsuarios > 0 ? (usuariosAlertaRoja / totalUsuarios) * 100 : 0,
      tendenciaActividad: tendencia,
    );
  }

  static EstadisticasUsuario _calcularEstadisticasUsuario(List<AvanceModel> avances) {
    final totalAvances = avances.length;
    final diasActivos = avances.map((a) => DateTime(
      a.fechaHora.year,
      a.fechaHora.month,
      a.fechaHora.day,
    )).toSet().length;

    final ultimoAvance = avances.isNotEmpty ? 
        avances.reduce((a, b) => a.fechaHora.isAfter(b.fechaHora) ? a : b) : null;

    final diasSinActividad = ultimoAvance != null ? 
        DateTime.now().difference(ultimoAvance.fechaHora).inDays : 0;

    return EstadisticasUsuario(
      totalAvances: totalAvances,
      diasActivos: diasActivos,
      diasSinActividad: diasSinActividad,
      ultimoAvance: ultimoAvance,
      promedioAvancesPorDia: diasActivos > 0 ? totalAvances / diasActivos : 0,
    );
  }

  static ReporteSemanal _generarReporteSemanal(
    List<UsuarioModel> usuarios,
    List<AvanceModel> avancesSemana,
    DateTime inicio,
    DateTime fin,
  ) {
    final estadisticasGrupo = _calcularEstadisticasGrupo(usuarios, avancesSemana);
    
    // Top performers
    final Map<String, int> avancesPorUsuario = {};
    for (final avance in avancesSemana) {
      avancesPorUsuario[avance.usuarioId] = (avancesPorUsuario[avance.usuarioId] ?? 0) + 1;
    }

    final topPerformers = avancesPorUsuario.entries
        .map((entry) {
          final usuario = usuarios.firstWhere((u) => u.id == entry.key);
          return TopPerformer(usuario: usuario, avances: entry.value);
        })
        .toList()
      ..sort((a, b) => b.avances.compareTo(a.avances));

    return ReporteSemanal(
      fechaInicio: inicio,
      fechaFin: fin,
      estadisticas: estadisticasGrupo,
      topPerformers: topPerformers.take(3).toList(),
      totalAvancesSemana: avancesSemana.length,
      participacionUsuarios: avancesPorUsuario.length,
    );
  }

  static TendenciaActividad _calcularTendenciaActividad(List<AvanceModel> avances) {
    if (avances.length < 7) return TendenciaActividad.estable;

    final now = DateTime.now();
    final semanaActual = avances.where((a) => 
        now.difference(a.fechaHora).inDays <= 7).length;
    final semanaAnterior = avances.where((a) => 
        now.difference(a.fechaHora).inDays > 7 && 
        now.difference(a.fechaHora).inDays <= 14).length;

    if (semanaActual > semanaAnterior) return TendenciaActividad.creciente;
    if (semanaActual < semanaAnterior) return TendenciaActividad.decreciente;
    return TendenciaActividad.estable;
  }
}

// Clases de datos para estadísticas
class EstadisticasGrupo {
  final int totalUsuarios;
  final int usuariosAlDia;
  final int usuariosAlertaAmarilla;
  final int usuariosAlertaRoja;
  final int totalAvances;
  final double promedioAvancesPorUsuario;
  final double promedioDiasSinActividad;
  final double porcentajeInactivos;
  final TendenciaActividad tendenciaActividad;

  EstadisticasGrupo({
    required this.totalUsuarios,
    required this.usuariosAlDia,
    required this.usuariosAlertaAmarilla,
    required this.usuariosAlertaRoja,
    required this.totalAvances,
    required this.promedioAvancesPorUsuario,
    required this.promedioDiasSinActividad,
    required this.porcentajeInactivos,
    required this.tendenciaActividad,
  });
}

class EstadisticasUsuario {
  final int totalAvances;
  final int diasActivos;
  final int diasSinActividad;
  final AvanceModel? ultimoAvance;
  final double promedioAvancesPorDia;

  EstadisticasUsuario({
    required this.totalAvances,
    required this.diasActivos,
    required this.diasSinActividad,
    this.ultimoAvance,
    required this.promedioAvancesPorDia,
  });
}

class UsuarioInactivo {
  final UsuarioModel usuario;
  final int diasSinActividad;
  final AvanceModel? ultimoAvance;

  UsuarioInactivo({
    required this.usuario,
    required this.diasSinActividad,
    this.ultimoAvance,
  });
}

class ReporteSemanal {
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final EstadisticasGrupo estadisticas;
  final List<TopPerformer> topPerformers;
  final int totalAvancesSemana;
  final int participacionUsuarios;

  ReporteSemanal({
    required this.fechaInicio,
    required this.fechaFin,
    required this.estadisticas,
    required this.topPerformers,
    required this.totalAvancesSemana,
    required this.participacionUsuarios,
  });
}

class TopPerformer {
  final UsuarioModel usuario;
  final int avances;

  TopPerformer({
    required this.usuario,
    required this.avances,
  });
}

class SugerenciaColaboracion {
  final TipoSugerencia tipo;
  final String titulo;
  final String descripcion;
  final Prioridad prioridad;

  SugerenciaColaboracion({
    required this.tipo,
    required this.titulo,
    required this.descripcion,
    required this.prioridad,
  });
}

enum TendenciaActividad {
  creciente,
  estable,
  decreciente,
}

enum TipoSugerencia {
  comunicacion,
  productividad,
  motivacion,
  organizacion,
}

enum Prioridad {
  baja,
  media,
  alta,
}
