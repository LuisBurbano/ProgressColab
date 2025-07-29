const express = require('express');
const router = express.Router();
const { firestore } = require('../../config/firebase');

// Test de conectividad básica
router.get('/ping', (req, res) => {
  res.json({ 
    mensaje: 'Servidor funcionando correctamente',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// Test de conexión con Firebase
router.get('/firebase', async (req, res) => {
  try {
    // Intentar leer una colección
    const testSnapshot = await firestore.collection('usuarios').limit(1).get();
    
    res.json({
      mensaje: 'Conexión con Firebase exitosa',
      timestamp: new Date().toISOString(),
      firebase: 'conectado',
      documentosEncontrados: testSnapshot.size
    });
  } catch (error) {
    res.status(500).json({
      mensaje: 'Error conectando con Firebase',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Test de validación de avance
router.post('/validar-avance', (req, res) => {
  const { crearAvanceSchema } = require('../models/avance');
  
  const { error, value } = crearAvanceSchema.validate(req.body);
  
  if (error) {
    return res.status(400).json({
      valido: false,
      error: error.details[0].message,
      campo: error.details[0].path[0],
      valorRecibido: req.body,
      valorProcesado: value
    });
  }
  
  res.json({
    valido: true,
    mensaje: 'Datos válidos para crear avance',
    valorProcesado: value
  });
});

// Listar usuarios para debug
router.get('/usuarios', async (req, res) => {
  try {
    const snapshot = await firestore.collection('usuarios').limit(5).get();
    const usuarios = snapshot.docs.map(doc => ({
      id: doc.id,
      nombre: doc.data().nombre,
      apellido: doc.data().apellido,
      email: doc.data().email
    }));
    
    res.json({
      usuarios,
      total: usuarios.length,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      error: 'Error obteniendo usuarios',
      detalle: error.message
    });
  }
});

// Obtener usuario por email (para Flutter)
router.post('/usuario-por-email', async (req, res) => {
  try {
    const { email } = req.body;
    
    if (!email) {
      return res.status(400).json({
        error: 'Email requerido',
        ejemplo: { email: 'usuario@example.com' }
      });
    }

    const snapshot = await firestore
      .collection('usuarios')
      .where('email', '==', email)
      .limit(1)
      .get();

    if (snapshot.empty) {
      return res.status(404).json({
        error: 'Usuario no encontrado',
        email: email
      });
    }

    const userDoc = snapshot.docs[0];
    const userData = userDoc.data();
    delete userData.contraseña; // No enviar contraseña

    res.json({
      id: userDoc.id,
      ...userData,
      mensaje: 'Usuario encontrado correctamente'
    });

  } catch (error) {
    res.status(500).json({
      error: 'Error buscando usuario',
      detalle: error.message
    });
  }
});

// Información del servidor
router.get('/info', (req, res) => {
  res.json({
    servidor: 'ProgressColab Backend',
    version: '1.0.0',
    node: process.version,
    uptime: process.uptime(),
    memoria: process.memoryUsage(),
    endpoints: {
      ping: '/api/1.0/test/ping',
      firebase: '/api/1.0/test/firebase',
      validarAvance: '/api/1.0/test/validar-avance',
      usuarios: '/api/1.0/test/usuarios',
      usuarioPorEmail: '/api/1.0/test/usuario-por-email',
      panelColaborativo: '/api/1.0/test/panel-colaborativo',
      info: '/api/1.0/test/info'
    }
  });
});

// Test del panel colaborativo
router.get('/panel-colaborativo', async (req, res) => {
  try {
    console.log('🔍 Testing panel colaborativo...');
    
    // Llamar al endpoint real de estado de actividad
    const { obtenerEstadoActividad } = require('../controllers/avance');
    
    // Crear objeto mock de respuesta
    const mockRes = {
      json: (data) => {
        res.json({
          testing: true,
          mensaje: 'Datos del panel colaborativo',
          ...data
        });
      },
      status: (code) => ({
        json: (data) => {
          res.status(code).json({
            testing: true,
            error: true,
            ...data
          });
        }
      })
    };
    
    // Llamar a la función
    await obtenerEstadoActividad(req, mockRes);
    
  } catch (error) {
    res.status(500).json({
      testing: true,
      error: 'Error en test del panel colaborativo',
      detalle: error.message
    });
  }
});

module.exports = router;
