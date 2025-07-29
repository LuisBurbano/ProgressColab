const Joi = require('joi');
const dayjs = require('dayjs');

// Modelo para crear un avance diario
const crearAvanceSchema = Joi.object({
  usuarioId: Joi.string().required(), // ID del usuario que registra el avance
  descripcion: Joi.string().min(5).required(), // Descripción del avance
  fechaHora: Joi.date().default(() => new Date()), // Sin segundo argumento
  alerta: Joi.string().valid('ninguna', 'amarilla', 'roja').default('ninguna')
});

// Utilidad para formatear fecha y determinar alerta
function procesarAvance(doc) {
  const data = doc.data();
  const fechaHora = data.fechaHora.toDate ? data.fechaHora.toDate() : new Date(data.fechaHora);
  const ahora = new Date();
  const horasPasadas = (ahora - fechaHora) / (1000 * 60 * 60);

  let alerta = 'ninguna';
  if (horasPasadas > 48) {
    alerta = 'roja';
  } else if (horasPasadas > 24) {
    alerta = 'amarilla';
  }

  return {
    id: doc.id,
    usuarioId: data.usuarioId,
    descripcion: data.descripcion,
    fechaHora: dayjs(fechaHora).format('YYYY-MM-DD HH:mm:ss'),
    alerta
  };
}

module.exports = {
  crearAvanceSchema,
  procesarAvance
};
