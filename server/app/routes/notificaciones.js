const express = require('express');
const router = express.Router();
const {
  enviarNotificacionPersonalizada,
  enviarRecordatoriosInactivos,
  generarAlertasGrupales,
  desactivarAlerta,
  obtenerAlertasActivas
} = require('../controllers/notificaciones');

// Enviar notificación personalizada a un usuario
router.post('/enviar', enviarNotificacionPersonalizada);

// Enviar recordatorios automáticos a usuarios inactivos
router.post('/recordatorios', enviarRecordatoriosInactivos);

// Generar alertas grupales por inactividad
router.post('/alertas-grupales', generarAlertasGrupales);

// Obtener alertas activas
router.get('/alertas', obtenerAlertasActivas);

// Desactivar alerta específica
router.patch('/alertas/:alertaId/desactivar', desactivarAlerta);

module.exports = router;
