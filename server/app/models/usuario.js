// models/usuario.js
const Joi = require('joi');

// Esquema para creación de usuario (campos obligatorios)
const crearUsuarioSchema = Joi.object({
  nombre: Joi.string().min(2).required(),
  apellido: Joi.string().min(2).required(),
  email: Joi.string().email().required(),
  contraseña: Joi.string().min(6).required(),

  // Opcionales
  tokenFCM: Joi.array().items(Joi.string()).default([]),
  activo: Joi.boolean().default(true),

  // Perfil cultural (opcionales)
  estiloComunicacion: Joi.string().valid('formal', 'informal'),
  horarioTrabajo: Joi.string().valid('mañana', 'tarde', 'noche'),
  tiempoRespuesta: Joi.string(), // Ej: "1 hora", "30 min"
  simbolosCulturales: Joi.array().items(Joi.string()) // paths o IDs
});

// Esquema para actualización del perfil cultural (PATCH)
const actualizarPerfilCulturalSchema = Joi.object({
  estiloComunicacion: Joi.string().valid('formal', 'informal'),
  horarioTrabajo: Joi.string().valid('mañana', 'tarde', 'noche'),
  tiempoRespuesta: Joi.string(),
  simbolosCulturales: Joi.array().items(Joi.string()),
  tokenFCM: Joi.array().items(Joi.string())
});

// Esquema para actualización exclusiva de tokenFCM (opcional)
const tokenFCMSchema = Joi.object({
  tokenFCM: Joi.array().items(Joi.string()).optional()
});

module.exports = {
  crearUsuarioSchema,
  actualizarPerfilCulturalSchema,
  tokenFCMSchema
};
