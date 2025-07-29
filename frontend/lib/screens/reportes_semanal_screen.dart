import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/estadisticas_service.dart';

class ReportesSemanalScreen extends StatefulWidget {
  const ReportesSemanalScreen({super.key});

  @override
  State<ReportesSemanalScreen> createState() => _ReportesSemanalScreenState();
}

class _ReportesSemanalScreenState extends State<ReportesSemanalScreen> {
  ReporteSemanal? _reporteActual;
  List<SugerenciaColaboracion> _sugerencias = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReporte();
  }

  Future<void> _loadReporte() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final reporte = await EstadisticasService.generateReporteSemanal();
      final sugerencias = await EstadisticasService.getSugerenciasColaboracion();

      setState(() {
        _reporteActual = reporte;
        _sugerencias = sugerencias;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Error al generar reporte: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.assessment,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              'Reporte Semanal',
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
            onPressed: _loadReporte,
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
    if (_reporteActual == null) {
      return Center(
        child: Text(
          'No se pudo generar el reporte',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReporte,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderReporte(),
            const SizedBox(height: 20),
            _buildEstadisticasGenerales(),
            const SizedBox(height: 20),
            _buildTopPerformers(),
            const SizedBox(height: 20),
            _buildTendenciasActividad(),
            const SizedBox(height: 20),
            _buildSugerenciasColaboracion(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderReporte() {
    final reporte = _reporteActual!;
    final rangoFechas = '${DateFormat('dd/MM').format(reporte.fechaInicio)} - ${DateFormat('dd/MM/yyyy').format(reporte.fechaFin)}';

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
                Icons.calendar_view_week,
                color: const Color(0xFF667eea),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Resumen Semanal',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2c3e50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            rangoFechas,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Avances Totales',
                  '${reporte.totalAvancesSemana}',
                  Icons.trending_up,
                  const Color(0xFF27ae60),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Participación',
                  '${reporte.participacionUsuarios}/${reporte.estadisticas.totalUsuarios}',
                  Icons.people,
                  const Color(0xFF3498db),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticasGenerales() {
    final estadisticas = _reporteActual!.estadisticas;

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
            'Estadísticas del Equipo',
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
                child: _buildStatItem(
                  'Miembros Al Día',
                  '${estadisticas.usuariosAlDia}',
                  '✅',
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Alerta Amarilla',
                  '${estadisticas.usuariosAlertaAmarilla}',
                  '⚠️',
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Alerta Roja',
                  '${estadisticas.usuariosAlertaRoja}',
                  '🔴',
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProgressBar(),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
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

  Widget _buildProgressBar() {
    final estadisticas = _reporteActual!.estadisticas;
    final total = estadisticas.totalUsuarios;
    
    if (total == 0) return const SizedBox();

    final porcentajeAlDia = (estadisticas.usuariosAlDia / total);
    final porcentajeAmarilla = (estadisticas.usuariosAlertaAmarilla / total);
    final porcentajeRoja = (estadisticas.usuariosAlertaRoja / total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distribución del Estado del Equipo',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF2c3e50),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey[200],
          ),
          child: Row(
            children: [
              if (porcentajeAlDia > 0)
                Expanded(
                  flex: (porcentajeAlDia * 100).round(),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        bottomLeft: Radius.circular(10),
                      ),
                    ),
                  ),
                ),
              if (porcentajeAmarilla > 0)
                Expanded(
                  flex: (porcentajeAmarilla * 100).round(),
                  child: Container(
                    color: Colors.orange,
                  ),
                ),
              if (porcentajeRoja > 0)
                Expanded(
                  flex: (porcentajeRoja * 100).round(),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopPerformers() {
    final topPerformers = _reporteActual!.topPerformers;

    if (topPerformers.isEmpty) {
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
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'No hay datos suficientes para mostrar top performers',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      );
    }

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
                Icons.emoji_events,
                color: const Color(0xFFf39c12),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Top Performers de la Semana',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2c3e50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...topPerformers.asMap().entries.map((entry) {
            final index = entry.key;
            final performer = entry.value;
            return _buildPerformerCard(performer, index + 1);
          }),
        ],
      ),
    );
  }

  Widget _buildPerformerCard(TopPerformer performer, int position) {
    final icons = ['🥇', '🥈', '🥉'];
    final colors = [
      const Color(0xFFf39c12),
      const Color(0xFF95a5a6),
      const Color(0xFFe67e22),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors[position - 1].withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors[position - 1].withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(
            position <= 3 ? icons[position - 1] : '🏆',
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  performer.usuario.nombreCompleto,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2c3e50),
                  ),
                ),
                Text(
                  '${performer.avances} avances registrados',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors[position - 1],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '#$position',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTendenciasActividad() {
    final tendencia = _reporteActual!.estadisticas.tendenciaActividad;
    
    Color colorTendencia;
    IconData iconoTendencia;
    String textoTendencia;

    switch (tendencia) {
      case TendenciaActividad.creciente:
        colorTendencia = Colors.green;
        iconoTendencia = Icons.trending_up;
        textoTendencia = 'La actividad del equipo está en aumento';
        break;
      case TendenciaActividad.estable:
        colorTendencia = Colors.blue;
        iconoTendencia = Icons.trending_flat;
        textoTendencia = 'La actividad del equipo se mantiene estable';
        break;
      case TendenciaActividad.decreciente:
        colorTendencia = Colors.red;
        iconoTendencia = Icons.trending_down;
        textoTendencia = 'La actividad del equipo está disminuyendo';
        break;
    }

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
                iconoTendencia,
                color: colorTendencia,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Tendencias de Actividad',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2c3e50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorTendencia.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorTendencia.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  iconoTendencia,
                  color: colorTendencia,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    textoTendencia,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF2c3e50),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSugerenciasColaboracion() {
    if (_sugerencias.isEmpty) {
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
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 48,
              color: Colors.green[400],
            ),
            const SizedBox(height: 8),
            Text(
              '¡Excelente trabajo!',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2c3e50),
              ),
            ),
            Text(
              'No hay sugerencias de mejora en este momento',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

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
                Icons.lightbulb,
                color: const Color(0xFFf39c12),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Sugerencias de Colaboración',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2c3e50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._sugerencias.map((sugerencia) => _buildSugerenciaCard(sugerencia)),
        ],
      ),
    );
  }

  Widget _buildSugerenciaCard(SugerenciaColaboracion sugerencia) {
    Color color = _getPrioridadColor(sugerencia.prioridad);
    IconData icono = _getTipoIcon(sugerencia.tipo);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sugerencia.titulo,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2c3e50),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  sugerencia.prioridad.name.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            sugerencia.descripcion,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPrioridadColor(Prioridad prioridad) {
    switch (prioridad) {
      case Prioridad.alta:
        return Colors.red;
      case Prioridad.media:
        return Colors.orange;
      case Prioridad.baja:
        return Colors.blue;
    }
  }

  IconData _getTipoIcon(TipoSugerencia tipo) {
    switch (tipo) {
      case TipoSugerencia.comunicacion:
        return Icons.chat;
      case TipoSugerencia.productividad:
        return Icons.trending_up;
      case TipoSugerencia.motivacion:
        return Icons.emoji_emotions;
      case TipoSugerencia.organizacion:
        return Icons.business;
    }
  }
}
