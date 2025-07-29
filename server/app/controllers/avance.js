const { firestore } = require('../../config/firebase');
const { crearAvanceSchema, procesarAvance } = require('../models/avance');


// Crear avance
const crearAvance = async (req, res) => {
  try {
    console.log('📝 Datos recibidos para crear avance:', req.body);
    
    const { error, value } = crearAvanceSchema.validate(req.body);
    if (error) {
      console.log('❌ Error de validación:', error.details[0].message);
      return res.status(400).json({ 
        error: error.details[0].message,
        campo: error.details[0].path[0],
        valorRecibido: req.body
      });
    }

    // Verificar que el usuario existe
    const usuarioDoc = await firestore.collection('usuarios').doc(value.usuarioId).get();
    if (!usuarioDoc.exists) {
      console.log('❌ Usuario no encontrado:', value.usuarioId);
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }

    const nuevoAvance = {
      usuarioId: value.usuarioId,
      descripcion: value.descripcion,
      fechaHora: new Date().toISOString(), // <-- Se registra la fecha actual
      alerta: 'ninguna',
    };

    console.log('💾 Guardando avance:', nuevoAvance);
    const docRef = await firestore.collection('avances').add(nuevoAvance);
    
    // Actualizar estado de alerta del usuario a 'ninguna' ya que registró actividad
    try {
      await firestore.collection('usuarios').doc(value.usuarioId).update({
        estadoAlerta: 'ninguna',
        ultimaActividad: new Date().toISOString()
      });
      console.log('✅ Estado del usuario actualizado');
    } catch (updateError) {
      console.error('⚠️ Error actualizando estado del usuario:', updateError);
    }
    
    console.log('✅ Avance creado exitosamente:', docRef.id);
    res.status(201).json({ id: docRef.id, ...nuevoAvance });
  } catch (err) {
    console.error('❌ Error al crear avance:', err);
    res.status(500).json({ error: 'Error interno del servidor', detalle: err.message });
  }
};


// Listar todos los avances
const listarAvances = async (req, res) => {
  try {
    const snapshot = await firestore.collection('avances').orderBy('fechaHora', 'desc').get();
    const avances = snapshot.docs.map(doc => procesarAvance(doc));
    res.json(avances);
  } catch (err) {
    console.error('Error al listar avances:', err);
    res.status(500).json({ error: 'Error al obtener avances' });
  }
};

// Listar avances por usuario
const listarAvancesPorUsuario = async (req, res) => {
  const { usuarioId } = req.params;
  try {
    console.log('📋 Listando avances para usuario:', usuarioId);
    const snapshot = await firestore
      .collection('avances')
      .where('usuarioId', '==', usuarioId)
      .get();

    const avances = snapshot.docs
      .map(doc => procesarAvance(doc))
      .sort((a, b) => new Date(b.fechaHora) - new Date(a.fechaHora)); // Ordenar en JavaScript en lugar de Firestore
    
    console.log(`✅ Encontrados ${avances.length} avances para el usuario`);
    res.json(avances);
  } catch (err) {
    console.error('Error al listar avances del usuario:', err);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
};

// Actualizar un avance
const actualizarAvance = async (req, res) => {
  const { id } = req.params;
  try {
    await firestore.collection('avances').doc(id).update(req.body);
    res.json({ mensaje: 'Avance actualizado exitosamente' });
  } catch (err) {
    console.error('Error al actualizar avance:', err);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
};

// Eliminar un avance
const eliminarAvance = async (req, res) => {
  const { id } = req.params;
  try {
    await firestore.collection('avances').doc(id).delete();
    res.json({ mensaje: 'Avance eliminado exitosamente' });
  } catch (err) {
    console.error('Error al eliminar avance:', err);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
};

// Obtener estado de actividad de todos los usuarios
const obtenerEstadoActividad = async (req, res) => {
  try {
    const ahora = new Date();
    const hace24h = new Date(ahora.getTime() - (24 * 60 * 60 * 1000));
    const hace48h = new Date(ahora.getTime() - (48 * 60 * 60 * 1000));
    
    console.log('📊 Obteniendo estado de actividad de usuarios...');
    
    // Obtener todos los usuarios
    const usuariosSnapshot = await firestore.collection('usuarios').get();
    const usuarios = usuariosSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    const estadoUsuarios = [];

    for (const usuario of usuarios) {
      try {
        // Obtener avances del usuario SIN orderBy
        const avancesSnapshot = await firestore
          .collection('avances')
          .where('usuarioId', '==', usuario.id)
          .get();

        let ultimoAvance = null;
        let estado = 'al_dia';
        let icono = '✅';
        let diasInactivo = 0;
        let alerta = 'ninguna';

        if (!avancesSnapshot.empty) {
          // Encontrar el último avance manualmente
          const avances = avancesSnapshot.docs.map(doc => ({
            ...doc.data(),
            fechaHora: new Date(doc.data().fechaHora)
          }));
          
          // Ordenar por fecha manualmente
          avances.sort((a, b) => b.fechaHora - a.fechaHora);
          ultimoAvance = avances[0].fechaHora;
          diasInactivo = Math.floor((ahora - ultimoAvance) / (1000 * 60 * 60 * 24));
        } else {
          diasInactivo = 999; // Usuario sin avances
        }

        // Determinar estado según inactividad
        if (diasInactivo === 0) {
          estado = 'al_dia';
          icono = '✅';
          alerta = 'ninguna';
        } else if (diasInactivo === 1) {
          estado = 'alerta_amarilla';
          icono = '⚠️';
          alerta = 'amarilla';
        } else {
          estado = 'alerta_roja';
          icono = '🔴';
          alerta = 'roja';
        }

        estadoUsuarios.push({
          id: usuario.id,
          nombre: usuario.nombre,
          apellido: usuario.apellido,
          email: usuario.email,
          estado,
          icono,
          alerta,
          diasInactivo,
          ultimoAvance: ultimoAvance ? ultimoAvance.toISOString() : null,
          perfilCultural: usuario.perfilCultural || usuario.estiloComunicacion || 'latino',
          totalAvances: avancesSnapshot.size
        });

      } catch (userError) {
        console.error(`❌ Error procesando usuario ${usuario.id}:`, userError.message);
        // Incluir usuario con error para debugging
        estadoUsuarios.push({
          id: usuario.id,
          nombre: usuario.nombre,
          apellido: usuario.apellido,
          email: usuario.email,
          estado: 'error',
          icono: '❌',
          alerta: 'error',
          diasInactivo: 999,
          ultimoAvance: null,
          perfilCultural: 'latino',
          totalAvances: 0,
          error: userError.message
        });
      }
    }

    const resumen = {
      total: estadoUsuarios.length,
      alDia: estadoUsuarios.filter(u => u.estado === 'al_dia').length,
      alertaAmarilla: estadoUsuarios.filter(u => u.estado === 'alerta_amarilla').length,
      alertaRoja: estadoUsuarios.filter(u => u.estado === 'alerta_roja').length,
      promedioInactividad: estadoUsuarios.length > 0 
        ? Math.round((estadoUsuarios.reduce((sum, u) => sum + u.diasInactivo, 0) / estadoUsuarios.length) * 100) / 100 
        : 0
    };

    console.log(`✅ Estado de actividad obtenido: ${resumen.total} usuarios procesados`);

    res.json({
      usuarios: estadoUsuarios,
      resumen,
      timestamp: ahora.toISOString()
    });

  } catch (err) {
    console.error('❌ Error obteniendo estado de actividad:', err);
    res.status(500).json({ error: 'Error interno del servidor', detalle: err.message });
  }
};

module.exports = {
  crearAvance,
  listarAvances,
  listarAvancesPorUsuario,
  actualizarAvance,
  eliminarAvance,
  obtenerEstadoActividad,
};
