const { firestore } = require('../../config/firebase');
const { crearAvanceSchema, procesarAvance } = require('../models/avance');


// Crear avance
const crearAvance = async (req, res) => {
  try {
    const { error, value } = crearAvanceSchema.validate(req.body);
    if (error) return res.status(400).json({ error: error.details[0].message });

    const nuevoAvance = {
      usuarioId: value.usuarioId,
      descripcion: value.descripcion,
      fechaHora: new Date().toISOString(), // <-- Se registra la fecha actual
      alerta: 'ninguna',
    };

    const docRef = await firestore.collection('avances').add(nuevoAvance);
    res.status(201).json({ id: docRef.id, ...nuevoAvance });
  } catch (err) {
    console.error('Error al crear avance:', err);
    res.status(500).json({ error: 'Error interno del servidor' });
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
    const snapshot = await firestore
      .collection('avances')
      .where('usuarioId', '==', usuarioId)
      .orderBy('fechaHora', 'desc')
      .get();

    const avances = snapshot.docs.map(doc => procesarAvance(doc));
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

module.exports = {
  crearAvance,
  listarAvances,
  listarAvancesPorUsuario,
  actualizarAvance,
  eliminarAvance,
};
