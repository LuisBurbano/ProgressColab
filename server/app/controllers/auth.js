const { firestore } = require('../../config/firebase');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { httpError } = require('../helpers/handleError');

const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password)
      return res.status(400).json({ error: 'Email y contraseña son requeridos' });

    // Buscar usuario por email en Firestore
    const usuariosRef = firestore.collection('usuarios');
    const querySnapshot = await usuariosRef.where('email', '==', email).get();

    if (querySnapshot.empty)
      return res.status(404).json({ error: 'Usuario no encontrado' });

    // Tomar el primer documento (deberías asegurar emails únicos)
    const usuarioDoc = querySnapshot.docs[0];
    const usuarioData = usuarioDoc.data();

    // Comparar password hasheada (debe estar guardada al crear usuario)
    const isMatch = await bcrypt.compare(password, usuarioData.contraseña);
    if (!isMatch) return res.status(400).json({ error: 'Contraseña incorrecta' });

    const activo = usuarioData.activo ?? true;
    const emailVerificado = usuarioData.emailVerificado ?? false;

    // Generar token JWT (puedes incluir id, email, etc)
    const token = jwt.sign(
      { id: usuarioDoc.id, email: usuarioData.email },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      message: 'Inicio de sesión exitoso',
      token,
      usuario: {
        id: usuarioDoc.id,
        email: usuarioData.email,
        nombre: usuarioData.nombre,
        apellido: usuarioData.apellido,
        activo,
        emailVerificado
      }
    });

  } catch (e) {
    console.error('Error en login:', e);
    httpError(res, e);
  }
};

module.exports = { login };
