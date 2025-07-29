const express = require('express');
const router = express.Router();
const {
  crearAvance,
  listarAvances,
  listarAvancesPorUsuario,
  actualizarAvance,
  eliminarAvance,
  obtenerEstadoActividad
} = require('../controllers/avance');

router.post('/', crearAvance);                          // Crear avance
router.get('/', listarAvances);                        // Listar todos los avances
router.get('/usuario/:usuarioId', listarAvancesPorUsuario); // Avances de un usuario
router.get('/estado-actividad', obtenerEstadoActividad); // Estado de todos los usuarios
router.patch('/:id', actualizarAvance);                // Actualizar un avance
router.delete('/:id', eliminarAvance);                 // Eliminar un avance

module.exports = router;
