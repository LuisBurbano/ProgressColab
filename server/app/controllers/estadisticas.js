const { firestore } = require('../../config/firebase');
const dayjs = require('dayjs');

// Obtener estadísticas del panel colaborativo
const obtenerEstadisticasPanel = async (req, res) => {
  try {
    const ahora = new Date();
    const hace24h = new Date(ahora.getTime() - (24 * 60 * 60 * 1000));
    const hace48h = new Date(ahora.getTime() - (48 * 60 * 60 * 1000));
    
    // Obtener todos los usuarios
    const usuariosSnapshot = await firestore.collection('usuarios').get();
    const usuarios = usuariosSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    const estadisticas = {
      totalUsuarios: usuarios.length,
      usuariosAlDia: 0,
      usuariosAlertaAmarilla: 0,
      usuariosAlertaRoja: 0,
      promedioInactividad: 0,
      usuarios: []
    };

    let totalDiasInactividad = 0;

    for (const usuario of usuarios) {
      // Obtener último avance del usuario
      const avancesSnapshot = await firestore
        .collection('avances')
        .where('usuarioId', '==', usuario.id)
        .orderBy('fechaHora', 'desc')
        .limit(1)
        .get();

      let ultimoAvance = null;
      let estado = 'al_dia';
      let icono = '✅';
      let diasInactivo = 0;

      if (!avancesSnapshot.empty) {
        ultimoAvance = new Date(avancesSnapshot.docs[0].data().fechaHora);
        diasInactivo = Math.floor((ahora - ultimoAvance) / (1000 * 60 * 60 * 24));
      } else {
        diasInactivo = 999; // Usuario sin avances
      }

      totalDiasInactividad += diasInactivo;

      // Determinar estado según inactividad
      if (diasInactivo === 0) {
        estado = 'al_dia';
        icono = '✅';
        estadisticas.usuariosAlDia++;
      } else if (diasInactivo === 1) {
        estado = 'alerta_amarilla';
        icono = '⚠️';
        estadisticas.usuariosAlertaAmarilla++;
      } else {
        estado = 'alerta_roja';
        icono = '🔴';
        estadisticas.usuariosAlertaRoja++;
      }

      estadisticas.usuarios.push({
        id: usuario.id,
        nombre: usuario.nombre,
        apellido: usuario.apellido,
        estado,
        icono,
        diasInactivo,
        ultimoAvance: ultimoAvance ? dayjs(ultimoAvance).format('YYYY-MM-DD HH:mm') : 'Nunca'
      });
    }

    // Calcular promedio de inactividad
    estadisticas.promedioInactividad = usuarios.length > 0 
      ? Math.round((totalDiasInactividad / usuarios.length) * 100) / 100 
      : 0;

    res.json(estadisticas);

  } catch (error) {
    console.error('Error obteniendo estadísticas del panel:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
};

// Generar reporte semanal
const generarReporteSemanal = async (req, res) => {
  try {
    const ahora = new Date();
    const inicioDeSemana = new Date(ahora.getTime() - (7 * 24 * 60 * 60 * 1000));
    
    // Obtener todos los usuarios
    const usuariosSnapshot = await firestore.collection('usuarios').get();
    const usuarios = usuariosSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    // Obtener avances de la semana
    const avancesSnapshot = await firestore
      .collection('avances')
      .where('fechaHora', '>=', inicioDeSemana.toISOString())
      .get();

    const avancesSemana = avancesSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    const reporte = {
      fechaInicio: dayjs(inicioDeSemana).format('YYYY-MM-DD'),
      fechaFin: dayjs(ahora).format('YYYY-MM-DD'),
      totalUsuarios: usuarios.length,
      totalAvances: avancesSemana.length,
      usuariosActivos: 0,
      usuariosInactivos: 0,
      topPerformers: [],
      tendencias: {},
      sugerenciasColaboracion: []
    };

    // Análisis por usuario
    const datosUsuarios = {};
    
    usuarios.forEach(usuario => {
      datosUsuarios[usuario.id] = {
        id: usuario.id,
        nombre: usuario.nombre,
        apellido: usuario.apellido,
        perfilCultural: usuario.estiloComunicacion || 'latino',
        avancesEsaSemana: 0,
        ultimoAvance: null
      };
    });

    avancesSemana.forEach(avance => {
      if (datosUsuarios[avance.usuarioId]) {
        datosUsuarios[avance.usuarioId].avancesEsaSemana++;
        const fechaAvance = new Date(avance.fechaHora);
        if (!datosUsuarios[avance.usuarioId].ultimoAvance || 
            fechaAvance > new Date(datosUsuarios[avance.usuarioId].ultimoAvance)) {
          datosUsuarios[avance.usuarioId].ultimoAvance = avance.fechaHora;
        }
      }
    });

    // Clasificar usuarios
    Object.values(datosUsuarios).forEach(usuario => {
      if (usuario.avancesEsaSemana > 0) {
        reporte.usuariosActivos++;
      } else {
        reporte.usuariosInactivos++;
      }
    });

    // Top performers (ordenar por avances)
    reporte.topPerformers = Object.values(datosUsuarios)
      .sort((a, b) => b.avancesEsaSemana - a.avancesEsaSemana)
      .slice(0, 3)
      .map(usuario => ({
        nombre: `${usuario.nombre} ${usuario.apellido}`,
        avances: usuario.avancesEsaSemana
      }));

    // Tendencias por día de la semana
    const avancesPorDia = {};
    avancesSemana.forEach(avance => {
      const dia = dayjs(avance.fechaHora).format('dddd');
      avancesPorDia[dia] = (avancesPorDia[dia] || 0) + 1;
    });
    reporte.tendencias.avancesPorDia = avancesPorDia;

    // Sugerencias de colaboración basadas en perfiles culturales
    const perfilesCulturales = {};
    Object.values(datosUsuarios).forEach(usuario => {
      const perfil = usuario.perfilCultural;
      if (!perfilesCulturales[perfil]) {
        perfilesCulturales[perfil] = { activos: 0, inactivos: 0 };
      }
      if (usuario.avancesEsaSemana > 0) {
        perfilesCulturales[perfil].activos++;
      } else {
        perfilesCulturales[perfil].inactivos++;
      }
    });

    // Generar sugerencias
    Object.entries(perfilesCulturales).forEach(([perfil, datos]) => {
      if (datos.inactivos > 0) {
        let sugerencia = '';
        switch (perfil) {
          case 'latino':
            sugerencia = 'Considerar reuniones más frecuentes y recordatorios personalizados para mantener la motivación del equipo latino.';
            break;
          case 'norteamericano':
            sugerencia = 'Implementar métricas claras y objetivos semanales para el estilo directo norteamericano.';
            break;
          case 'europeo':
            sugerencia = 'Establecer procesos estructurados y cronogramas detallados para el equipo europeo.';
            break;
          case 'asiatico':
            sugerencia = 'Fomentar la comunicación grupal y el consenso para motivar al equipo asiático.';
            break;
          case 'africano':
            sugerencia = 'Enfatizar el impacto comunitario y la colaboración colectiva para el equipo africano.';
            break;
          default:
            sugerencia = 'Adaptar la comunicación según las preferencias culturales del equipo.';
        }
        reporte.sugerenciasColaboracion.push(sugerencia);
      }
    });

    res.json(reporte);

  } catch (error) {
    console.error('Error generando reporte semanal:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
};

// Obtener estadísticas generales
const obtenerEstadisticasGenerales = async (req, res) => {
  try {
    const ahora = new Date();
    const hace30dias = new Date(ahora.getTime() - (30 * 24 * 60 * 60 * 1000));
    
    // Contadores
    const totalUsuarios = (await firestore.collection('usuarios').get()).size;
    const totalAvances = (await firestore.collection('avances').get()).size;
    const avancesUltimos30dias = (await firestore
      .collection('avances')
      .where('fechaHora', '>=', hace30dias.toISOString())
      .get()).size;

    // Promedio de avances por usuario (últimos 30 días)
    const promedioAvancesPorUsuario = totalUsuarios > 0 
      ? Math.round((avancesUltimos30dias / totalUsuarios) * 100) / 100 
      : 0;

    const estadisticas = {
      totalUsuarios,
      totalAvances,
      avancesUltimos30dias,
      promedioAvancesPorUsuario,
      fechaConsulta: dayjs(ahora).format('YYYY-MM-DD HH:mm:ss')
    };

    res.json(estadisticas);

  } catch (error) {
    console.error('Error obteniendo estadísticas generales:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
};

module.exports = {
  obtenerEstadisticasPanel,
  generarReporteSemanal,
  obtenerEstadisticasGenerales
};
