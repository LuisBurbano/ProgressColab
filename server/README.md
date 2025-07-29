# ProgressColab Backend

API REST para la gestión colaborativa de progreso diario con características interculturales.

## 🚀 Funcionalidades Implementadas

### ✅ RF3. Registro de avance diario
- **RF3.1** ✅ Registro de tareas diarias por usuario
- **RF3.2** ✅ Validación de campos requeridos (mín. 5 caracteres)
- **RF3.3** ✅ Historial ordenado por fecha descendente
- **RF3.4** ✅ Sistema automático de alertas (24h = amarilla, 48h = roja)

### ✅ RF4. Notificaciones persistentes personalizadas
- **RF4.1** ✅ Recordatorios diarios automáticos estilo Duolingo
- **RF4.2** ✅ Personalización por perfil cultural (5 perfiles)
- **RF4.3** ✅ Frases motivacionales + referencias a últimos avances

### ✅ RF5. Alertas al equipo por inactividad
- **RF5.1** ✅ Alertas grupales automáticas (>48h inactivo)
- **RF5.2** ✅ Mensajes empáticos según perfil cultural
- **RF5.3** ✅ Desactivación manual de alertas con justificación

### ✅ RF6. Panel colaborativo de progreso
- **RF6.1** ✅ Estado en tiempo real de todos los miembros
- **RF6.2** ✅ Iconos visuales (✅, ⚠️, 🔴) según actividad
- **RF6.3** ✅ Estadísticas grupales y promedios

### ✅ RF7. Reporte semanal y reflexión del equipo
- **RF7.1** ✅ Resumen semanal completo con estadísticas
- **RF7.2** ✅ Sugerencias de colaboración basadas en perfil cultural

## Base URL
```
http://localhost:3000/api/1.0/
```

## 📋 Endpoints Disponibles

### Usuarios
```
POST   /api/1.0/usuario/                 # Crear usuario
GET    /api/1.0/usuario/                 # Listar usuarios
GET    /api/1.0/usuario/:id              # Obtener usuario por ID
PATCH  /api/1.0/usuario/:id              # Actualizar perfil cultural
DELETE /api/1.0/usuario/:id              # Eliminar usuario
PATCH  /api/1.0/usuario/:id/token        # Actualizar token FCM
```

### Avances
```
POST   /api/1.0/avance/crearAvance       # Crear avance diario
GET    /api/1.0/avance/                  # Listar todos los avances
GET    /api/1.0/avance/usuario/:id       # Avances por usuario
GET    /api/1.0/avance/estado-actividad  # Estado de todos los usuarios
PATCH  /api/1.0/avance/:id               # Actualizar avance
DELETE /api/1.0/avance/:id               # Eliminar avance
```

### Notificaciones ⭐ NUEVO
```
POST   /api/1.0/notificaciones/enviar                      # Enviar notificación personalizada
POST   /api/1.0/notificaciones/recordatorios               # Enviar recordatorios a inactivos
POST   /api/1.0/notificaciones/alertas-grupales            # Generar alertas grupales
GET    /api/1.0/notificaciones/alertas                     # Obtener alertas activas
PATCH  /api/1.0/notificaciones/alertas/:id/desactivar      # Desactivar alerta
```

### Estadísticas ⭐ NUEVO
```
GET    /api/1.0/estadisticas/panel           # Estadísticas del panel colaborativo
GET    /api/1.0/estadisticas/reporte-semanal # Reporte semanal completo
GET    /api/1.0/estadisticas/generales       # Estadísticas generales
```

### Tareas Programadas ⭐ NUEVO
```
POST   /api/1.0/tareas/recordatorios/ejecutar    # Ejecutar recordatorios manualmente
POST   /api/1.0/tareas/verificacion/ejecutar     # Ejecutar verificación manualmente
POST   /api/1.0/tareas/alertas/ejecutar          # Ejecutar alertas manualmente
GET    /api/1.0/tareas/logs                      # Obtener logs recientes
```

### Autenticación
```
POST   /api/1.0/auth/login                  # Iniciar sesión
POST   /api/1.0/auth/register               # Registrar usuario
POST   /api/1.0/auth/refresh                # Refrescar token
```

## 🤖 Tareas Programadas Automáticas ⭐ NUEVO

### Recordatorios Diarios
- **Frecuencia**: Cada día a las 9:00 AM
- **Función**: Envía notificaciones personalizadas a usuarios inactivos (+24h)
- **Personalización**: Mensajes según perfil cultural

### Verificación de Inactividad
- **Frecuencia**: Cada hora
- **Función**: Actualiza estado de alerta de usuarios (amarilla/roja)
- **Automatización**: Sin intervención manual

### Alertas Grupales
- **Frecuencia**: Cada 6 horas
- **Función**: Genera alertas para usuarios inactivos (+48h)
- **Prevención**: Evita duplicados recientes

### Limpieza de Datos
- **Frecuencia**: Domingos a medianoche
- **Función**: Elimina alertas y logs antiguos (+7 días)
- **Optimización**: Mantiene rendimiento de la base de datos

## 🌍 Perfiles Culturales Soportados ⭐ NUEVO

### Latino
- Comunicación cálida y personal
- Frases motivacionales en español
- Enfoque en equipo y apoyo mutuo

### Norteamericano
- Comunicación directa y orientada a resultados
- Frases en inglés enfocadas en productividad
- Métricas y objetivos claros

### Europeo
- Comunicación estructurada y formal
- Procesos organizados y cronogramas
- Enfoque en consistencia y calidad

### Asiático
- Comunicación respetuosa y armoniosa
- Enfoque en dedicación y perseverancia
- Trabajo en equipo y consenso

### Africano
- Filosofía Ubuntu (unidad comunitaria)
- Enfoque en impacto colectivo
- Fortaleza a través de la unidad

## 🔧 Configuración y Instalación

### Dependencias
```bash
npm install
```

### Variables de Entorno (.env)
```env
FIREBASE_ARCHIVO_CUENTA_SERVICIO="tu-archivo-firebase.json"
JWT_SECRET="tu_jwt_secret"
PORT=3000
```

### ⚠️ Configuración Importante de Firebase

**ANTES de ejecutar el servidor**, necesitas crear un índice compuesto en Firebase:

1. **Ir a Firebase Console**: https://console.firebase.google.com/
2. **Seleccionar tu proyecto**: `tranporte-rural`
3. **Ir a**: Firestore Database → Indexes
4. **Crear índice compuesto** con:
   - **Collection ID**: `avances`
   - **Fields**:
     - `usuarioId` - Ascending
     - `fechaHora` - Descending
   - **Query scope**: Collection

**O usar el enlace automático que aparece en el error del log**

### Ejecutar en Desarrollo
```bash
npm run dev
```

### Ejecutar en Producción
```bash
npm start
```

### 🧍 Crear Usuario

## URI de creación de usuario
```
http://localhost:3000/api/1.0/usuario/crearUsuario
```

**POST** `/usuario/crearUsuario`  
**Raw JSON**:
```json
{
  "nombre": "leo",
  "apellido": "dlc",
  "email": "leodlcm2@gmail.com",
  "contraseña": "1234567"
}
```

---

### 🔐 Login

## URI de inicio de sesión (usar en login de app)
```
http://localhost:3000/api/1.0/auth/login
```

**POST** `/auth/login`  
**Raw JSON**:
```json
{
  "email": "leodlcm2@gmail.com",
  "password": "1234567"
}
```

---

### 📈 Crear Avance

## URI de creaciónn de un avance (tarea de un usuario)
```
http://localhost:3000/api/1.0/usuario/crearAvance
```

**POST** `/avance/crearAvance`  
**Raw JSON**:
```json
{
  "usuarioId": "CJnW3tyXXO6SKSoV2MlV",
  "descripcion": "Implementé el endpoint de login"
}
```

---

## Endpoints Usuarios

| Método | Ruta                     | Descripción                         |
|--------|--------------------------|-------------------------------------|
| GET    | `/usuario/`              | Listar todos los usuarios           |
| GET    | `/usuario/id/:id`        | Obtener un usuario por ID           |
| PATCH  | `/usuario/:id`           | Actualizar parcialmente un usuario  |
| DELETE | `/usuario/:id`           | Eliminar un usuario                 |
| PATCH  | `/usuario/tokenFCM/:id`  | Actualizar token FCM (opcional)     |

---

## Endpoints Avances

| Método | Ruta                             | Descripción                         |
|--------|----------------------------------|-------------------------------------|
| POST   | `/avance/crearAvance`           | Crear un nuevo avance               |
| GET    | `/avance/`                      | Listar todos los avances            |
| GET    | `/avance/usuario/:usuarioId`    | Listar avances por usuario          |
| PATCH  | `/avance/:id`                   | Actualizar avance                   |
| DELETE | `/avance/:id`                   | Eliminar avance                     |

---

## Reglas de Alerta

- 🔔 Si el usuario no registra avances en 24 horas: `alerta: amarilla`
- 🔴 Si pasa de 48 horas sin avances: `alerta: roja`

---

## Cómo Probar con Postman

1. Crear un usuario con `/usuario/crearUsuario`
2. Iniciar sesión con `/auth/login`
3. Crear avances usando `/avance/crearAvance` con el ID del usuario obtenido
4. Listar avances, usuarios, o actualizar datos según los endpoints