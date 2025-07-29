import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/avance_model.dart';
import '../models/usuario_model.dart';
import '../services/avance_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class RegistroAvanceScreen extends StatefulWidget {
  const RegistroAvanceScreen({super.key});

  @override
  State<RegistroAvanceScreen> createState() => _RegistroAvanceScreenState();
}

class _RegistroAvanceScreenState extends State<RegistroAvanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  bool _isLoading = false;
  List<AvanceModel> _historialAvances = [];
  UsuarioModel? _usuario;

  @override
  void initState() {
    super.initState();
    _loadUserAndHistory();
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndHistory() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user != null) {
        setState(() {
          _usuario = UsuarioModel.fromJson(user);
        });
        await _loadHistorial();
      }
    } catch (e) {
      _showError('Error al cargar datos del usuario');
    }
  }

  Future<void> _loadHistorial() async {
    if (_usuario == null) return;

    try {
      // Usar email en lugar de ID para evitar problemas de ID vacío
      final avances = await AvanceService.getAvancesByUserEmail(_usuario!.email);
      setState(() {
        _historialAvances = avances
            .map((a) => AvanceModel.fromJson(a))
            .toList()
          ..sort((a, b) => b.fechaHora.compareTo(a.fechaHora));
      });
    } catch (e) {
      _showError('Error al cargar historial de avances: $e');
    }
  }

  Future<void> _registrarAvance() async {
    if (!_formKey.currentState!.validate() || _usuario == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Usar email en lugar de ID para evitar problemas de ID vacío
      await AvanceService.createAvanceByEmail(_usuario!.email, _descripcionController.text.trim());
      
      // Enviar notificación motivacional
      await NotificationService.sendMotivationalNotification(
        usuario: _usuario!,
        ultimoAvance: _descripcionController.text.trim(),
      );

      _descripcionController.clear();
      await _loadHistorial();
      
      _showSuccess('¡Avance registrado exitosamente! 🎉');
    } catch (e) {
      _showError('Error al registrar avance: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
        title: Text(
          'Registro de Avance Diario',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: Column(
          children: [
            // Formulario de registro
            Container(
              margin: const EdgeInsets.all(16),
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Qué lograste hoy?',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2c3e50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descripcionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Describe tu avance del día...',
                        hintStyle: GoogleFonts.poppins(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF667eea)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFf8f9fa),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El campo de avance no puede estar vacío';
                        }
                        if (value.trim().length < 10) {
                          return 'Describe tu avance con más detalle (mín. 10 caracteres)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _registrarAvance,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF667eea),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Registrar Avance',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Historial de avances
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Historial de Avances',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _historialAvances.isEmpty
                          ? _buildEmptyState()
                          : _buildHistorialList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Colors.white.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'Aún no tienes avances registrados',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '¡Registra tu primer avance hoy!',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistorialList() {
    return ListView.builder(
      itemCount: _historialAvances.length,
      itemBuilder: (context, index) {
        final avance = _historialAvances[index];
        final isToday = _isToday(avance.fechaHora);
        final diasAtras = DateTime.now().difference(avance.fechaHora).inDays;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
            border: isToday
                ? Border.all(color: const Color(0xFF667eea), width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isToday 
                          ? const Color(0xFF667eea) 
                          : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isToday 
                          ? 'HOY' 
                          : diasAtras == 1 
                              ? 'AYER' 
                              : 'HACE ${diasAtras} DÍAS',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isToday ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(avance.fechaHora),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                avance.descripcion,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF2c3e50),
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }
}
