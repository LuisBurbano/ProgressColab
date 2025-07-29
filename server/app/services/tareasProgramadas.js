const cron = require('node-cron');
const { firestore, messaging } = require('../../config/firebase');
const dayjs = require('dayjs');

// Frases motivacionales por perfil cultural
const frasesPorPerfil = {
  latino: [
    "¡Vamos, que tú puedes! 💪",
    "Un pequeño paso cada día hace grandes diferencias 🌟",
    "El equipo te extraña, ¡regresa pronto! 👥",
    "Tu progreso inspira a todos 🚀",
    "¡Dale que se puede! 🎉"
  ],
  norteamericano: [
    "Stay focused and keep moving forward! 🎯",
    "Progress, not perfection! 📈",
    "Your team is counting on you! 💼",
    "Let's get back on track! ⚡",
    "Time to level up! 🚀"
  ],
  europeo: [
    "Steady progress leads to success 🎯",
    "Your consistency matters to the team 📊",
    "Small steps, big achievements 🏆",
    "Let's maintain our momentum! 💫",
    "Excellence through persistence 💎"
  ],
  asiatico: [
    "Perseverance brings great rewards 🌸",
    "Harmony in team progress 🎋",
    "Step by step towards excellence 🗾",
    "Your dedication strengthens us all 💎",
    "Balance brings success 🌺"
  ],
  africano: [
    "Ubuntu: Together we are stronger! 🌍",
    "Every step forward lifts the whole community 🤝",
    "Your journey inspires the collective spirit 🌅",
    "In unity, we find our strength! 💪",
    "Ubuntu spirit drives us forward! 🦁"
  ]
};

class TareasProgramadasService {
  
  static inicializar() {
    console.log('🚀 Iniciando tareas programadas...');
    
    // Enviar recordatorios diarios a las 9:00 AM
    cron.schedule('0 9 * * *', () => {
      console.log('⏰ Ejecutando recordatorios diarios...');
      this.enviarRecordatoriosDiarios();
    });

    // Verificar inactividad cada hora
    cron.schedule('0 * * * *', () => {
      console.log('⏰ Verificando usuarios inactivos...');
      this.verificarInactividad();
    });

    // Generar alertas grupales cada 6 horas
    cron.schedule('0 */6 * * *', () => {
      console.log('⏰ Generando alertas grupales...');
      this.generarAlertasGrupales();
    });

    // Limpiar alertas antiguas semanalmente (domingos a medianoche)
    cron.schedule('0 0 * * 0', () => {
      console.log('⏰ Limpiando alertas antiguas...');
      this.limpiarAlertasAntiguas();
    });

    console.log('✅ Tareas programadas iniciadas correctamente');
  }

  static async enviarRecordatoriosDiarios() {
    try {
      const ahora = new Date();
      const hace24h = new Date(ahora.getTime() - (24 * 60 * 60 * 1000));
      
      // Obtener todos los usuarios activos
      const usuariosSnapshot = await firestore
        .collection('usuarios')
        .where('activo', '==', true)
        .get();
      
      const usuarios = usuariosSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      let notificacionesEnviadas = 0;

      for (const usuario of usuarios) {
        try {
          // Verificar si tiene tokens FCM
          if (!usuario.tokenFCM || usuario.tokenFCM.length === 0) {
            continue;
          }

          // Obtener avances del usuario SIN orderBy
          const avancesSnapshot = await firestore
            .collection('avances')
            .where('usuarioId', '==', usuario.id)
            .get();

          let ultimoAvance = null;
          
          if (!avancesSnapshot.empty) {
            // Encontrar el último avance manualmente
            const avances = avancesSnapshot.docs.map(doc => ({
              ...doc.data(),
              fechaHora: new Date(doc.data().fechaHora)
            }));
            
            // Ordenar por fecha manualmente
            avances.sort((a, b) => b.fechaHora - a.fechaHora);
            ultimoAvance = avances[0].fechaHora;
          }

          // Si no tiene avances o el último es hace más de 24h
          const debeRecordar = !ultimoAvance || ultimoAvance < hace24h;

          if (debeRecordar) {
            const perfil = usuario.estiloComunicacion || 'latino';
            const frases = frasesPorPerfil[perfil] || frasesPorPerfil.latino;
            const fraseAleatoria = frases[Math.floor(Math.random() * frases.length)];

            // Personalizar mensaje con último avance
            let mensaje = fraseAleatoria;
            if (ultimoAvance) {
              const diasInactivo = Math.floor((ahora - ultimoAvance) / (1000 * 60 * 60 * 24));
              mensaje += ` Has estado ${diasInactivo} día(s) sin registrar avances.`;
            }

            const notificationMessage = {
              notification: {
                title: '¡Es hora de brillar! ✨',
                body: mensaje
              },
              data: {
                type: 'daily_reminder',
                usuarioId: usuario.id,
                timestamp: ahora.toISOString()
              },
              tokens: usuario.tokenFCM
            };

            await messaging.sendEachForMulticast(notificationMessage);
            notificacionesEnviadas++;
            
            console.log(`📱 Recordatorio enviado a ${usuario.nombre} ${usuario.apellido}`);
          }

        } catch (error) {
          console.error(`❌ Error enviando recordatorio a ${usuario.id}:`, error.message);
        }
      }

      console.log(`✅ Recordatorios enviados: ${notificacionesEnviadas}`);
      
      // Registrar en base de datos
      await firestore.collection('logs_notificaciones').add({
        tipo: 'recordatorios_diarios',
        fecha: ahora.toISOString(),
        notificacionesEnviadas,
        totalUsuarios: usuarios.length
      });

    } catch (error) {
      console.error('❌ Error en recordatorios diarios:', error.message);
    }
  }

  static async verificarInactividad() {
    try {
      const ahora = new Date();
      const hace24h = new Date(ahora.getTime() - (24 * 60 * 60 * 1000));
      const hace48h = new Date(ahora.getTime() - (48 * 60 * 60 * 1000));
      
      // Obtener todos los usuarios
      const usuariosSnapshot = await firestore.collection('usuarios').get();
      const usuarios = usuariosSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

      let usuariosActualizados = 0;

      for (const usuario of usuarios) {
        try {
          // Obtener último avance - SIN orderBy para evitar problemas de índice
          const avancesSnapshot = await firestore
            .collection('avances')
            .where('usuarioId', '==', usuario.id)
            .get();

          let estadoAlerta = 'ninguna';
          
          if (avancesSnapshot.empty) {
            estadoAlerta = 'roja'; // Usuario sin avances
          } else {
            // Encontrar el último avance manualmente
            const avances = avancesSnapshot.docs.map(doc => ({
              ...doc.data(),
              fechaHora: new Date(doc.data().fechaHora)
            }));
            
            // Ordenar por fecha manualmente
            avances.sort((a, b) => b.fechaHora - a.fechaHora);
            const ultimoAvance = avances[0].fechaHora;
            
            if (ultimoAvance < hace48h) {
              estadoAlerta = 'roja';
            } else if (ultimoAvance < hace24h) {
              estadoAlerta = 'amarilla';
            }
          }

          // Actualizar estado de alerta del usuario si ha cambiado
          if (usuario.estadoAlerta !== estadoAlerta) {
            await firestore.collection('usuarios').doc(usuario.id).update({
              estadoAlerta,
              ultimaVerificacion: ahora.toISOString()
            });
            usuariosActualizados++;
          }

        } catch (error) {
          console.error(`❌ Error verificando usuario ${usuario.id}:`, error.message);
        }
      }

      console.log(`✅ Estados de alerta verificados. Usuarios actualizados: ${usuariosActualizados}`);

    } catch (error) {
      console.error('❌ Error verificando inactividad:', error.message);
    }
  }

  static async generarAlertasGrupales() {
    try {
      const ahora = new Date();
      const hace48h = new Date(ahora.getTime() - (48 * 60 * 60 * 1000));
      
      // Obtener usuarios inactivos por más de 48 horas
      const usuariosSnapshot = await firestore.collection('usuarios').get();
      const usuarios = usuariosSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      
      const usuariosInactivos = [];

      for (const usuario of usuarios) {
        try {
          // Obtener avances SIN orderBy
          const avancesSnapshot = await firestore
            .collection('avances')
            .where('usuarioId', '==', usuario.id)
            .get();

          let ultimoAvance = null;
          if (!avancesSnapshot.empty) {
            // Encontrar el último avance manualmente
            const avances = avancesSnapshot.docs.map(doc => ({
              ...doc.data(),
              fechaHora: new Date(doc.data().fechaHora)
            }));
            
            // Ordenar por fecha manualmente
            avances.sort((a, b) => b.fechaHora - a.fechaHora);
            ultimoAvance = avances[0].fechaHora;
          }

          const esInactivo = !ultimoAvance || ultimoAvance < hace48h;
          if (esInactivo) {
            usuariosInactivos.push({
              id: usuario.id,
              nombre: usuario.nombre,
              apellido: usuario.apellido,
              perfilCultural: usuario.estiloComunicacion || 'latino',
              ultimoAvance: ultimoAvance ? ultimoAvance.toISOString() : null,
              diasInactivo: ultimoAvance ? Math.floor((ahora - ultimoAvance) / (1000 * 60 * 60 * 24)) : 999
            });
          }
        } catch (error) {
          console.error(`❌ Error procesando usuario ${usuario.id}:`, error.message);
        }
      }

      // Solo crear alerta si hay usuarios inactivos
      if (usuariosInactivos.length > 0) {
        // Verificar si ya existe una alerta grupal activa reciente (últimas 6 horas)
        const hace6h = new Date(ahora.getTime() - (6 * 60 * 60 * 1000));
        const alertasRecientes = await firestore
          .collection('alertas')
          .where('tipo', '==', 'inactividad_grupal')
          .where('activa', '==', true)
          .where('fechaCreacion', '>=', hace6h.toISOString())
          .get();

        if (alertasRecientes.empty) {
          const alerta = {
            tipo: 'inactividad_grupal',
            usuariosInactivos,
            fechaCreacion: ahora.toISOString(),
            activa: true,
            mensaje: `${usuariosInactivos.length} miembro(s) del equipo necesita(n) apoyo`,
            nivelUrgencia: usuariosInactivos.length > 2 ? 'alta' : 'media'
          };

          await firestore.collection('alertas').add(alerta);
          console.log(`🚨 Alerta grupal creada: ${usuariosInactivos.length} usuarios inactivos`);
        } else {
          console.log('ℹ️ Alerta grupal ya existe, no se crea duplicada');
        }
      } else {
        console.log('✅ No hay usuarios inactivos para alertas grupales');
      }

    } catch (error) {
      console.error('❌ Error generando alertas grupales:', error.message);
    }
  }

  static async limpiarAlertasAntiguas() {
    try {
      const hace7dias = new Date(Date.now() - (7 * 24 * 60 * 60 * 1000));
      
      const alertasAntiguas = await firestore
        .collection('alertas')
        .where('fechaCreacion', '<', hace7dias.toISOString())
        .get();

      let alertasEliminadas = 0;
      
      for (const doc of alertasAntiguas.docs) {
        await doc.ref.delete();
        alertasEliminadas++;
      }

      // También limpiar logs antiguos de notificaciones
      const logsAntiguos = await firestore
        .collection('logs_notificaciones')
        .where('fecha', '<', hace7dias.toISOString())
        .get();

      let logsEliminados = 0;
      
      for (const doc of logsAntiguos.docs) {
        await doc.ref.delete();
        logsEliminados++;
      }

      console.log(`🧹 Limpieza completada: ${alertasEliminadas} alertas y ${logsEliminados} logs eliminados`);

    } catch (error) {
      console.error('❌ Error limpiando datos antiguos:', error);
    }
  }

  // Métodos para control manual de tareas
  static async ejecutarRecordatoriosManual() {
    console.log('🔧 Ejecutando recordatorios manualmente...');
    await this.enviarRecordatoriosDiarios();
  }

  static async ejecutarVerificacionManual() {
    console.log('🔧 Ejecutando verificación manual...');
    await this.verificarInactividad();
  }

  static async ejecutarAlertasManual() {
    console.log('🔧 Ejecutando alertas grupales manualmente...');
    await this.generarAlertasGrupales();
  }
}

module.exports = TareasProgramadasService;
