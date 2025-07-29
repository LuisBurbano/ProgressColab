import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/usuario_model.dart';
import '../models/avance_model.dart';
import '../services/estadisticas_service.dart';
import '../services/avance_service.dart';

class PanelColaborativoScreen extends StatefulWidget {
  const PanelColaborativoScreen({super.key});

  @override
  State<PanelColaborativoScreen> createState() => _PanelColaborativoScreenState();
}

class _PanelColaborativoScreenState extends State<PanelColaborativoScreen> {
  List<UsuarioEstado> _usuariosEstado = [];
  EstadisticasGrupo? _estadisticas;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Actualizar cada 30 segundos para mostrar tiempo real
    _startPeriodicUpdate();
  }

  void _startPeriodicUpdate() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _loadData();
        _startPeriodicUpdate();
      }
    });
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Usar el endpoint de estado de actividad del backend
      final estadoActividad = await AvanceService.getEstadoActividad();
      final usuarios = estadoActividad['usuarios'] as List<dynamic>;
      final estadisticas = await EstadisticasService.getEstadisticasGrupo();

      final usuariosEstado = <UsuarioEstado>[];

      for (final userData in usuarios) {
        // Los datos ya vienen procesados del backend
        final usuario = UsuarioModel(
          id: userData['id'] ?? '',
          nombre: userData['nombre'] ?? '',
          apellido: userData['apellido'] ?? '',
          email: userData['email'] ?? '',
          perfilCultural: userData['perfilCultural'] ?? 'latino',
          fechaCreacion: DateTime.now(), // Valor por defecto
        );
        
        AvanceModel? ultimoAvance;
        if (userData['ultimoAvance'] != null) {
          ultimoAvance = AvanceModel(
            id: '', // No necesario para mostrar
            usuarioId: userData['id'],
            descripcion: '', // No necesario para mostrar
            fechaHora: DateTime.parse(userData['ultimoAvance']),
            alerta: userData['alerta'] ?? 'ninguna',
          );
        }

        // Convertir estado del backend a nuestro enum
        EstadoMiembro estado;
        switch (userData['estado']) {
          case 'al_dia':
            estado = EstadoMiembro.alDia;
            break;
          case 'alerta_amarilla':
            estado = EstadoMiembro.unDiaRetraso;
            break;
          case 'alerta_roja':
          default:
            estado = EstadoMiembro.inactivoMasDe2Dias;
            break;
        }

        usuariosEstado.add(UsuarioEstado(
          usuario: usuario,
          ultimoAvance: ultimoAvance,
          estado: estado,
        ));
      }

      setState(() {
        _usuariosEstado = usuariosEstado;
        _estadisticas = estadisticas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Error al cargar datos: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.dashboard,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              'Panel Colaborativo',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: _isLoading ? _buildLoadingState() : _buildContent(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: Colors.white),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResumenEstadisticas(),
            const SizedBox(height: 20),
            _buildEstadoTiempoReal(),
            const SizedBox(height: 20),
            _buildListaMiembros(),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenEstadisticas() {
    if (_estadisticas == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen del Equipo',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2c3e50),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Miembros',
                  '${_estadisticas!.totalUsuarios}',
                  Icons.people,
                  const Color(0xFF3498db),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Promedio Días sin Actividad',
                  '${_estadisticas!.promedioDiasSinActividad.toStringAsFixed(1)}',
                  Icons.calendar_today,
                  const Color(0xFFe74c3c),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Avances',
                  '${_estadisticas!.totalAvances}',
                  Icons.trending_up,
                  const Color(0xFF27ae60),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Promedio por Usuario',
                  '${_estadisticas!.promedioAvancesPorUsuario.toStringAsFixed(1)}',
                  Icons.person,
                  const Color(0xFF9b59b6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoTiempoReal() {
    final alDia = _usuariosEstado.where((u) => u.estado == EstadoMiembro.alDia).length;
    final unDia = _usuariosEstado.where((u) => u.estado == EstadoMiembro.unDiaRetraso).length;
    final masDeDos = _usuariosEstado.where((u) => u.estado == EstadoMiembro.inactivoMasDe2Dias).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: const Color(0xFF667eea),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Estado en Tiempo Real',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2c3e50),
                ),
              ),
              const Spacer(),
              Text(
                'Actualizado: ${DateFormat('HH:mm').format(DateTime.now())}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildEstadoIndicador('✅', 'Al día', alDia, Colors.green),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildEstadoIndicador('⚠️', '1 día', unDia, Colors.orange),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildEstadoIndicador('🔴', '+2 días', masDeDos, Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoIndicador(String icono, String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            icono,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildListaMiembros() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Miembros del Equipo',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2c3e50),
            ),
          ),
          const SizedBox(height: 16),
          ..._usuariosEstado.map((usuarioEstado) => _buildMiembroCard(usuarioEstado)),
        ],
      ),
    );
  }

  Widget _buildMiembroCard(UsuarioEstado usuarioEstado) {
    final usuario = usuarioEstado.usuario;
    final estado = usuarioEstado.estado;
    final ultimoAvance = usuarioEstado.ultimoAvance;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: estado.color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: estado.color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Avatar del usuario
          CircleAvatar(
            backgroundColor: estado.color,
            child: Text(
              usuario.nombre.substring(0, 1).toUpperCase(),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Información del usuario
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      usuario.nombreCompleto,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2c3e50),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      estado.icono,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  estado.descripcion,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: estado.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (ultimoAvance != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Último avance: ${DateFormat('dd/MM/yyyy').format(ultimoAvance.fechaHora)}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Clases auxiliares
class UsuarioEstado {
  final UsuarioModel usuario;
  final AvanceModel? ultimoAvance;
  final EstadoMiembro estado;

  UsuarioEstado({
    required this.usuario,
    this.ultimoAvance,
    required this.estado,
  });
}

enum EstadoMiembro {
  alDia,
  unDiaRetraso,
  inactivoMasDe2Dias,
}

extension EstadoMiembroExtension on EstadoMiembro {
  String get icono {
    switch (this) {
      case EstadoMiembro.alDia:
        return '✅';
      case EstadoMiembro.unDiaRetraso:
        return '⚠️';
      case EstadoMiembro.inactivoMasDe2Dias:
        return '🔴';
    }
  }

  String get descripcion {
    switch (this) {
      case EstadoMiembro.alDia:
        return 'Al día con sus avances';
      case EstadoMiembro.unDiaRetraso:
        return '1 día sin registrar avances';
      case EstadoMiembro.inactivoMasDe2Dias:
        return 'Más de 2 días sin actividad';
    }
  }

  Color get color {
    switch (this) {
      case EstadoMiembro.alDia:
        return Colors.green;
      case EstadoMiembro.unDiaRetraso:
        return Colors.orange;
      case EstadoMiembro.inactivoMasDe2Dias:
        return Colors.red;
    }
  }
}
