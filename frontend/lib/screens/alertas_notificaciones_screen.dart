import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/usuario_model.dart';
import '../services/estadisticas_service.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';

class AlertasNotificacionesScreen extends StatefulWidget {
  const AlertasNotificacionesScreen({super.key});

  @override
  State<AlertasNotificacionesScreen> createState() => _AlertasNotificacionesScreenState();
}

class _AlertasNotificacionesScreenState extends State<AlertasNotificacionesScreen> {
  List<UsuarioInactivo> _usuariosInactivos = [];
  bool _notificacionesHabilitadas = true;
  bool _isLoading = true;
  UsuarioModel? _usuarioActual;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Cargar usuario actual
      final user = await AuthService.getCurrentUser();
      if (user != null) {
        _usuarioActual = UsuarioModel.fromJson(user);
      }

      // Cargar preferencias de notificaciones
      final notifEnabled = await NotificationService.getNotificationPreference();

      // Cargar usuarios inactivos
      final usuariosInactivos = await EstadisticasService.getUsuariosInactivos();

      setState(() {
        _usuariosInactivos = usuariosInactivos;
        _notificacionesHabilitadas = notifEnabled;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Error al cargar datos: $e');
    }
  }

  Future<void> _toggleNotificaciones(bool value) async {
    try {
      await NotificationService.setNotificationPreference(value);
      
      if (value) {
        final hasPermission = await NotificationService.requestPermissions();
        if (!hasPermission) {
          _showError('No se pudieron obtener permisos para notificaciones');
          return;
        }
      }

      setState(() {
        _notificacionesHabilitadas = value;
      });

      _showSuccess(value 
          ? 'Notificaciones habilitadas' 
          : 'Notificaciones deshabilitadas');
    } catch (e) {
      _showError('Error al cambiar configuración: $e');
    }
  }

  Future<void> _enviarRecordatorio(UsuarioInactivo usuarioInactivo) async {
    try {
      // Enviar notificación motivacional personalizada
      await NotificationService.sendMotivationalNotification(
        usuario: usuarioInactivo.usuario,
        ultimoAvance: usuarioInactivo.ultimoAvance?.descripcion,
      );

      _showSuccess('Recordatorio enviado a ${usuarioInactivo.usuario.nombre}');
    } catch (e) {
      _showError('Error al enviar recordatorio: $e');
    }
  }

  Future<void> _enviarAlertaGrupal(UsuarioInactivo usuarioInactivo) async {
    try {
      final diasSinActividad = usuarioInactivo.diasSinActividad;
      final perfilCultural = usuarioInactivo.usuario.perfilCultural ?? 'otro';
      
      // Mensaje adaptado al perfil cultural
      String mensaje = _generarMensajeEmpaticoGrupal(
        usuarioInactivo.usuario.nombre,
        diasSinActividad,
        perfilCultural,
      );

      await NotificationService.sendGroupAlert(
        title: 'Apoyo al Compañero de Equipo',
        message: mensaje,
        inactiveUserId: usuarioInactivo.usuario.id,
      );

      _showSuccess('Alerta grupal enviada al equipo');
    } catch (e) {
      _showError('Error al enviar alerta grupal: $e');
    }
  }

  String _generarMensajeEmpaticoGrupal(String nombre, int dias, String perfil) {
    Map<String, List<String>> mensajesPorCultura = {
      'latino': [
        '$nombre lleva $dias días sin registrar avances. Como familia que somos, apoyémosle con comprensión.',
        'Nuestro compañero $nombre necesita nuestro apoyo. Recordemos que todos pasamos por momentos difíciles.',
      ],
      'norteamericano': [
        '$nombre has been inactive for $dias days. Let\'s reach out and offer support as a team.',
        'Our teammate $nombre might need assistance. Let\'s check in and see how we can help.',
      ],
      'europeo': [
        '$nombre hasn\'t been active for $dias days. Perhaps we should offer our collaboration and understanding.',
        'Our colleague $nombre might be facing challenges. Let\'s approach with empathy and support.',
      ],
      'asiatico': [
        '$nombre no ha registrado actividad en $dias días. Como equipo, debemos ofrecer nuestro apoyo con respeto.',
        'Nuestro compañero $nombre puede necesitar ayuda. Acerquémonos con comprensión y paciencia.',
      ],
      'africano': [
        '$nombre lleva $dias días sin actividad. En Ubuntu, crecemos juntos - ofrezcamos nuestro apoyo.',
        'Como comunidad, debemos apoyar a $nombre que no ha estado activo por $dias días.',
      ],
    };

    final mensajes = mensajesPorCultura[perfil.toLowerCase()] ?? mensajesPorCultura['otro']!;
    return mensajes[dias % mensajes.length];
  }

  void _mostrarDialogoDesactivarAlerta(UsuarioInactivo usuarioInactivo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Desactivar Alerta',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Text(
            '¿Deseas desactivar temporalmente las alertas para ${usuarioInactivo.usuario.nombre}? Esto puede ser útil en casos especiales justificados.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _desactivarAlerta(usuarioInactivo);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: Text(
                'Desactivar',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _desactivarAlerta(UsuarioInactivo usuarioInactivo) {
    // En una implementación real, esto se guardaría en el backend
    setState(() {
      _usuariosInactivos.removeWhere((u) => u.usuario.id == usuarioInactivo.usuario.id);
    });
    _showSuccess('Alerta desactivada temporalmente para ${usuarioInactivo.usuario.nombre}');
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

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
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
              Icons.notifications_active,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              'Alertas y Notificaciones',
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
            _buildConfiguracionNotificaciones(),
            const SizedBox(height: 20),
            _buildUsuariosInactivos(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfiguracionNotificaciones() {
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
                Icons.settings,
                color: const Color(0xFF667eea),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Configuración de Notificaciones',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2c3e50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(
              'Recordatorios Diarios',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Recibir notificaciones personalizadas según tu perfil cultural',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            value: _notificacionesHabilitadas,
            onChanged: _toggleNotificaciones,
            activeColor: const Color(0xFF667eea),
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.person,
              color: const Color(0xFF667eea),
            ),
            title: Text(
              'Perfil Cultural: ${_usuarioActual?.perfilCultural ?? 'No definido'}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Las notificaciones se adaptan a tu perfil cultural',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            trailing: const Icon(Icons.edit),
            onTap: () {
              // TODO: Navegar a edición de perfil
              _showError('Funcionalidad en desarrollo');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUsuariosInactivos() {
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
                Icons.people_alt,
                color: const Color(0xFFe74c3c),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Usuarios Inactivos',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2c3e50),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _usuariosInactivos.isEmpty ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_usuariosInactivos.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_usuariosInactivos.isEmpty)
            _buildEmptyInactiveUsers()
          else
            ..._usuariosInactivos.map((usuarioInactivo) => 
              _buildUsuarioInactivoCard(usuarioInactivo)),
        ],
      ),
    );
  }

  Widget _buildEmptyInactiveUsers() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle,
            size: 48,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          Text(
            '¡Excelente!',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Todos los miembros del equipo están activos',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsuarioInactivoCard(UsuarioInactivo usuarioInactivo) {
    final usuario = usuarioInactivo.usuario;
    final diasSinActividad = usuarioInactivo.diasSinActividad;
    final ultimoAvance = usuarioInactivo.ultimoAvance;

    Color alertColor = diasSinActividad > 2 ? Colors.red : Colors.orange;
    String alertIcon = diasSinActividad > 2 ? '🔴' : '⚠️';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: alertColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: alertColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: alertColor,
                child: Text(
                  usuario.nombre.substring(0, 1).toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
                        Text(alertIcon, style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                    Text(
                      '$diasSinActividad días sin actividad',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: alertColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (ultimoAvance != null)
                      Text(
                        'Último avance: ${DateFormat('dd/MM/yyyy').format(ultimoAvance.fechaHora)}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (ultimoAvance != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '"${ultimoAvance.descripcion}"',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[700],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _enviarRecordatorio(usuarioInactivo),
                  icon: const Icon(Icons.send, size: 16),
                  label: Text(
                    'Recordatorio',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667eea),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: diasSinActividad > 2 
                      ? () => _enviarAlertaGrupal(usuarioInactivo)
                      : null,
                  icon: const Icon(Icons.group, size: 16),
                  label: Text(
                    'Alerta Grupal',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _mostrarDialogoDesactivarAlerta(usuarioInactivo),
                icon: Icon(
                  Icons.notifications_off,
                  color: Colors.grey[600],
                  size: 20,
                ),
                tooltip: 'Desactivar alerta',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
