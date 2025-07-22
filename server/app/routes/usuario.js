const express = require('express');
const router = express.Router();
const {
  crearUsuario,
  listarUsuarios,
  obtenerUsuarioPorId,
  actualizarUsuario,
  eliminarUsuario,
  actualizarTokenFCM
} = require('../controllers/usuario');

router.post('/crearUsuario', crearUsuario);          // Crear usuario
router.get('/', listarUsuarios);         // Listar todos
router.get('/id/:id', obtenerUsuarioPorId); // Obtener uno por ID
router.patch('/:id', actualizarUsuario); // Actualizar parcialmente (perfil cultural)
router.delete('/:id', eliminarUsuario);  // Eliminar usuario
router.patch('/tokenFCM/:id', actualizarTokenFCM); // Actualizar token FCM

module.exports = router;
