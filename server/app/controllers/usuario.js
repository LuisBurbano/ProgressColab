const { firestore } = require('../../config/firebase');
const bcrypt = require('bcrypt');
const { crearUsuarioSchema, actualizarPerfilCulturalSchema, tokenFCMSchema } = require('../models/usuario');

// Crear usuario con hash de contraseña
const crearUsuario = async (req, res) => {
  try {
    const { error, value } = crearUsuarioSchema.validate(req.body);
    if (error) return res.status(400).json({ error: error.details[0].message });

    // Hashear contraseña
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(value.contraseña, saltRounds);

    // Reemplazar contraseña plain por hashed
    const nuevoUsuario = {
      ...value,
      contraseña: hashedPassword,
    };

    const docRef = await firestore.collection('usuarios').add(nuevoUsuario);

    res.status(201).json({ id: docRef.id, ...nuevoUsuario, contraseña: undefined }); // No devolver contraseña
  } catch (err) {
    console.error('Error al crear usuario:', err);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
};

// Listar usuarios
const listarUsuarios = async (req, res) => {
  try {
    const snapshot = await firestore.collection('usuarios').get();
    const usuarios = snapshot.docs.map(doc => {
      const data = doc.data();
      delete data.contraseña; // No enviar contraseña
      return { id: doc.id, ...data };
    });
    res.json(usuarios);
  } catch (err) {
    console.error('Error al listar usuarios:', err);
    res.status(500).json({ error: 'Error al obtener usuarios' });
  }
};

// Obtener usuario por ID
const obtenerUsuarioPorId = async (req, res) => {
  const { id } = req.params;
  try {
    const doc = await firestore.collection('usuarios').doc(id).get();
    if (!doc.exists) return res.status(404).json({ error: 'Usuario no encontrado' });

    const data = doc.data();
    delete data.contraseña; // No enviar contraseña
    res.json({ id: doc.id, ...data });
  } catch (err) {
    console.error('Error al obtener usuario:', err);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
};

// Actualizar usuario (perfil cultural o cualquier campo permitido)
const actualizarUsuario = async (req, res) => {
  const { id } = req.params;
  try {
    const { error, value } = actualizarPerfilCulturalSchema.validate(req.body);
    if (error) return res.status(400).json({ error: error.details[0].message });

    await firestore.collection('usuarios').doc(id).update(value);
    res.json({ mensaje: 'Usuario actualizado exitosamente' });
  } catch (err) {
    console.error('Error al actualizar usuario:', err);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
};

// Eliminar usuario
const eliminarUsuario = async (req, res) => {
  const { id } = req.params;
  try {
    await firestore.collection('usuarios').doc(id).delete();
    res.json({ mensaje: 'Usuario eliminado exitosamente' });
  } catch (err) {
    console.error('Error al eliminar usuario:', err);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
};

// Actualizar token FCM (opcional)
const actualizarTokenFCM = async (req, res) => {
  const { id } = req.params;

  const { error, value } = tokenFCMSchema.validate(req.body);
  if (error) return res.status(400).json({ error: error.details[0].message });

  if (!value.tokenFCM) {
    return res.status(400).json({ error: 'tokenFCM es requerido para la actualización' });
  }

  try {
    const usuarioDoc = firestore.collection('usuarios').doc(id);
    const docSnapshot = await usuarioDoc.get();
    if (!docSnapshot.exists) return res.status(404).json({ error: 'Usuario no encontrado' });

    await usuarioDoc.update({ tokenFCM: value.tokenFCM });

    res.json({ mensaje: 'tokenFCM actualizado correctamente' });
  } catch (err) {
    console.error('Error al actualizar tokenFCM:', err);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
};

module.exports = {
  crearUsuario,
  listarUsuarios,
  obtenerUsuarioPorId,
  actualizarUsuario,
  eliminarUsuario,
  actualizarTokenFCM
};
