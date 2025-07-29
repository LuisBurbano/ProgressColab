const { firestore, messaging } = require('../../config/firebase');
const dayjs = require('dayjs');

// Frases motivacionales por perfil cultural
const frasesPorPerfil = {
  latino: [
    "¡Vamos, que tú puedes! 💪",
    "Un pequeño paso cada día hace grandes diferencias 🌟",
    "El equipo te extraña, ¡regresa pronto! 👥",
    "Tu progreso inspira a todos 🚀"
  ],
  norteamericano: [
    "Stay focused and keep moving forward! 🎯",
    "Progress, not perfection! 📈",
    "Your team is counting on you! 💼",
    "Let's get back on track! ⚡"
  ],
  europeo: [
    "Steady progress leads to success 🎯",
    "Your consistency matters to the team 📊",
    "Small steps, big achievements 🏆",
    "Let's maintain our momentum! 💫"
  ],
  asiatico: [
    "Perseverance brings great rewards 🌸",
    "Harmony in team progress 🎋",
    "Step by step towards excellence 🗾",
    "Your dedication strengthens us all 💎"
  ],
  africano: [
    "Ubuntu: Together we are stronger! 🌍",
    "Every step forward lifts the whole community 🤝",
    "Your journey inspires the collective spirit 🌅",
    "In unity, we find our strength! 💪"
  ]
};

// Enviar notificación push personalizada
const enviarNotificacionPersonalizada = async (req, res) => {
  try {
    const { usuarioId, mensaje, titulo } = req.body;

    // Obtener usuario
    const usuarioDoc = await firestore.collection('usuarios').doc(usuarioId).get();
    if (!usuarioDoc.exists) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }

    const usuario = usuarioDoc.data();
    const tokens = usuario.tokenFCM || [];

    if (tokens.length === 0) {
      return res.status(400).json({ error: 'Usuario no tiene tokens FCM registrados' });
    }

    const message = {
      notification: {
        title: titulo || '¡Es hora de registrar tu progreso!',
        body: mensaje
      },
      data: {
        type: 'reminder',
        usuarioId: usuarioId
      },
      tokens: tokens
    };

    const response = await messaging.sendEachForMulticast(message);
    
    res.json({
      mensaje: 'Notificación enviada',
      exitosos: response.successCount,
      fallidos: response.failureCount
    });

  } catch (error) {
    console.error('Error enviando notificación:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
};

// Enviar recordatorios a usuarios inactivos
const enviarRecordatoriosInactivos = async (req, res) => {
  try {
    const ahora = new Date();
    const hace24h = new Date(ahora.getTime() - (24 * 60 * 60 * 1000));
    
    // Obtener todos los usuarios
    const usuariosSnapshot = await firestore.collection('usuarios').get();
    const usuarios = usuariosSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    const notificacionesEnviadas = [];

    for (const usuario of usuarios) {
      // Obtener último avance del usuario
      const avancesSnapshot = await firestore
        .collection('avances')
        .where('usuarioId', '==', usuario.id)
        .orderBy('fechaHora', 'desc')
        .limit(1)
        .get();

      let ultimoAvance = null;
      if (!avancesSnapshot.empty) {
        const avanceDoc = avancesSnapshot.docs[0];
        ultimoAvance = new Date(avanceDoc.data().fechaHora);
      }

      // Si no tiene avances o el último es hace más de 24h
      const debeRecordar = !ultimoAvance || ultimoAvance < hace24h;

      if (debeRecordar && usuario.tokenFCM && usuario.tokenFCM.length > 0) {
        const perfil = usuario.estiloComunicacion || 'latino';
        const frases = frasesPorPerfil[perfil] || frasesPorPerfil.latino;
        const fraseAleatoria = frases[Math.floor(Math.random() * frases.length)];

        const message = {
          notification: {
            title: '¡Te extrañamos! 🌟',
            body: fraseAleatoria
          },
          data: {
            type: 'inactivity_reminder',
            usuarioId: usuario.id
          },
          tokens: usuario.tokenFCM
        };

        try {
          const response = await messaging.sendEachForMulticast(message);
          notificacionesEnviadas.push({
            usuarioId: usuario.id,
            nombre: usuario.nombre,
            exitosos: response.successCount,
            fallidos: response.failureCount
          });
        } catch (error) {
          console.error(`Error enviando notificación a ${usuario.id}:`, error);
        }
      }
    }

    res.json({
      mensaje: 'Recordatorios enviados',
      total: notificacionesEnviadas.length,
      detalle: notificacionesEnviadas
    });

  } catch (error) {
    console.error('Error enviando recordatorios:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
};

// Generar alertas grupales por inactividad
const generarAlertasGrupales = async (req, res) => {
  try {
    const ahora = new Date();
    const hace48h = new Date(ahora.getTime() - (48 * 60 * 60 * 1000));
    
    // Obtener usuarios inactivos por más de 48 horas
    const usuariosSnapshot = await firestore.collection('usuarios').get();
    const usuarios = usuariosSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    
    const usuariosInactivos = [];

    for (const usuario of usuarios) {
      const avancesSnapshot = await firestore
        .collection('avances')
        .where('usuarioId', '==', usuario.id)
        .orderBy('fechaHora', 'desc')
        .limit(1)
        .get();

      let ultimoAvance = null;
      if (!avancesSnapshot.empty) {
        ultimoAvance = new Date(avancesSnapshot.docs[0].data().fechaHora);
      }

      const esInactivo = !ultimoAvance || ultimoAvance < hace48h;
      if (esInactivo) {
        usuariosInactivos.push({
          id: usuario.id,
          nombre: usuario.nombre,
          apellido: usuario.apellido,
          ultimoAvance: ultimoAvance ? dayjs(ultimoAvance).format('YYYY-MM-DD HH:mm') : 'Nunca',
          diasInactivo: ultimoAvance ? Math.floor((ahora - ultimoAvance) / (1000 * 60 * 60 * 24)) : '∞'
        });
      }
    }

    // Crear alerta grupal si hay usuarios inactivos
    if (usuariosInactivos.length > 0) {
      const alerta = {
        tipo: 'inactividad_grupal',
        usuariosInactivos,
        fechaCreacion: ahora.toISOString(),
        activa: true,
        mensaje: `${usuariosInactivos.length} miembro(s) del equipo necesita(n) apoyo`
      };

      const alertaRef = await firestore.collection('alertas').add(alerta);
      
      res.json({
        mensaje: 'Alerta grupal generada',
        alertaId: alertaRef.id,
        usuariosInactivos: usuariosInactivos.length,
        detalle: usuariosInactivos
      });
    } else {
      res.json({
        mensaje: 'No hay usuarios inactivos',
        usuariosInactivos: 0
      });
    }

  } catch (error) {
    console.error('Error generando alertas grupales:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
};

// Desactivar alerta específica
const desactivarAlerta = async (req, res) => {
  try {
    const { alertaId } = req.params;
    const { motivo } = req.body;

    await firestore.collection('alertas').doc(alertaId).update({
      activa: false,
      fechaDesactivacion: new Date().toISOString(),
      motivo: motivo || 'Sin motivo especificado'
    });

    res.json({ mensaje: 'Alerta desactivada exitosamente' });

  } catch (error) {
    console.error('Error desactivando alerta:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
};

// Obtener alertas activas
const obtenerAlertasActivas = async (req, res) => {
  try {
    const snapshot = await firestore
      .collection('alertas')
      .where('activa', '==', true)
      .orderBy('fechaCreacion', 'desc')
      .get();

    const alertas = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    res.json(alertas);

  } catch (error) {
    console.error('Error obteniendo alertas:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
};

module.exports = {
  enviarNotificacionPersonalizada,
  enviarRecordatoriosInactivos,
  generarAlertasGrupales,
  desactivarAlerta,
  obtenerAlertasActivas
};
