const express = require('express');
const router = express.Router();
const TareasProgramadasService = require('../services/tareasProgramadas');

// Ejecutar recordatorios diarios manualmente
router.post('/recordatorios/ejecutar', async (req, res) => {
  try {
    await TareasProgramadasService.ejecutarRecordatoriosManual();
    res.json({ mensaje: 'Recordatorios ejecutados exitosamente' });
  } catch (error) {
    console.error('Error ejecutando recordatorios:', error);
    res.status(500).json({ error: 'Error ejecutando recordatorios' });
  }
});

// Ejecutar verificación de inactividad manualmente
router.post('/verificacion/ejecutar', async (req, res) => {
  try {
    await TareasProgramadasService.ejecutarVerificacionManual();
    res.json({ mensaje: 'Verificación de inactividad ejecutada exitosamente' });
  } catch (error) {
    console.error('Error ejecutando verificación:', error);
    res.status(500).json({ error: 'Error ejecutando verificación' });
  }
});

// Ejecutar alertas grupales manualmente
router.post('/alertas/ejecutar', async (req, res) => {
  try {
    await TareasProgramadasService.ejecutarAlertasManual();
    res.json({ mensaje: 'Alertas grupales ejecutadas exitosamente' });
  } catch (error) {
    console.error('Error ejecutando alertas:', error);
    res.status(500).json({ error: 'Error ejecutando alertas' });
  }
});

// Obtener logs de notificaciones recientes
router.get('/logs', async (req, res) => {
  try {
    const { firestore } = require('../../config/firebase');
    const hace24h = new Date(Date.now() - (24 * 60 * 60 * 1000));
    
    const logsSnapshot = await firestore
      .collection('logs_notificaciones')
      .where('fecha', '>=', hace24h.toISOString())
      .orderBy('fecha', 'desc')
      .limit(50)
      .get();

    const logs = logsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    res.json(logs);
  } catch (error) {
    console.error('Error obteniendo logs:', error);
    res.status(500).json({ error: 'Error obteniendo logs' });
  }
});

module.exports = router;
