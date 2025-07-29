const express = require('express');
const router = express.Router();
const {
  obtenerEstadisticasPanel,
  generarReporteSemanal,
  obtenerEstadisticasGenerales
} = require('../controllers/estadisticas');

// Obtener estadísticas para el panel colaborativo
router.get('/panel', obtenerEstadisticasPanel);

// Generar reporte semanal del equipo
router.get('/reporte-semanal', generarReporteSemanal);

// Obtener estadísticas generales
router.get('/generales', obtenerEstadisticasGenerales);

module.exports = router;
