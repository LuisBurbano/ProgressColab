# ProgressColab - Ejemplos de Testing

## 🧪 Endpoints de Prueba

### 1. Test de Conectividad
```bash
GET http://192.168.18.14:3000/api/1.0/test/ping
```

### 2. Test de Firebase
```bash
GET http://192.168.18.14:3000/api/1.0/test/firebase
```

### 3. Listar Usuarios (Debug)
```bash
GET http://192.168.18.14:3000/api/1.0/test/usuarios
```

### 4. Obtener Usuario por Email (NUEVO) 🔥
```bash
POST http://192.168.18.14:3000/api/1.0/test/usuario-por-email
Content-Type: application/json

{
  "email": "leodlcm2@gmail.com"
}
```

### 5. Test Panel Colaborativo (NUEVO) 🔥
```bash
GET http://192.168.18.14:3000/api/1.0/test/panel-colaborativo
```

### 6. Información del Servidor
```bash
GET http://192.168.18.14:3000/api/1.0/test/info
```

## 🔧 Testing de Avances

### 1. Validar Datos de Avance (SIN guardar)
```bash
POST http://192.168.18.14:3000/api/1.0/test/validar-avance
Content-Type: application/json

{
  "usuarioId": "CJnW3tyXXO6SKSoV2MlV",
  "descripcion": "Esta es una prueba de validación"
}
```

### 2. Crear Avance Real
```bash
POST http://192.168.18.14:3000/api/1.0/avance/crearAvance
Content-Type: application/json

{
  "usuarioId": "CJnW3tyXXO6SKSoV2MlV",
  "descripcion": "Implementé nuevas funcionalidades"
}
```

## � SOLUCIÓN para el Error "usuarioId is not allowed to be empty"

### Problema Identificado:
Flutter está enviando `usuarioId: ""` (vacío) en lugar del ID real del usuario.

### Pasos para Solucionarlo:

#### 1. Obtener el ID correcto del usuario
```bash
# Usar el nuevo endpoint para obtener el usuario por email
curl -X POST http://192.168.18.14:3000/api/1.0/test/usuario-por-email \
  -H "Content-Type: application/json" \
  -d '{"email":"leodlcm2@gmail.com"}'
```

**Respuesta esperada:**
```json
{
  "id": "CJnW3tyXXO6SKSoV2MlV",
  "nombre": "leo",
  "apellido": "dlc",
  "email": "leodlcm2@gmail.com",
  "mensaje": "Usuario encontrado correctamente"
}
```

#### 2. Usar ese ID en Flutter
En tu código Flutter, asegúrate de:

```dart
// ❌ INCORRECTO - esto causa el error
final usuarioId = ""; // String vacío

// ✅ CORRECTO - obtener del usuario autenticado
final usuarioId = "CJnW3tyXXO6SKSoV2MlV"; // ID real del usuario
```

#### 3. Verificar datos antes de enviar
```bash
curl -X POST http://192.168.18.14:3000/api/1.0/test/validar-avance \
  -H "Content-Type: application/json" \
  -d '{"usuarioId":"CJnW3tyXXO6SKSoV2MlV","descripcion":"Test con ID correcto"}'
```

## 🔍 Debug del Panel Colaborativo

### Problema Identificado:
El endpoint `/avance/` devuelve avances individuales, pero el panel necesita el estado de usuarios.

### Solución:
```bash
# ❌ INCORRECTO - devuelve avances individuales
GET http://192.168.18.14:3000/api/1.0/avance/

# ✅ CORRECTO - devuelve estado de usuarios
GET http://192.168.18.14:3000/api/1.0/avance/estado-actividad
```

**Respuesta esperada del panel:**
```json
{
  "usuarios": [
    {
      "id": "CJnW3tyXXO6SKSoV2MlV",
      "nombre": "leo",
      "apellido": "dlc",
      "estado": "alerta_roja",
      "icono": "🔴",
      "alerta": "roja",
      "diasInactivo": 7,
      "ultimoAvance": "2025-07-21T22:44:34.000Z"
    }
  ],
  "resumen": {
    "total": 1,
    "alDia": 0,
    "alertaAmarilla": 0,
    "alertaRoja": 1
  }
}
```

## � Solución para Flutter

### En tu servicio de avances:
```dart
// Obtener ID del usuario autenticado
Future<String> obtenerUsuarioId() async {
  // Implementar lógica para obtener el ID del usuario autenticado
  // Por ejemplo, desde SharedPreferences o del sistema de auth
  return await getUserIdFromAuth(); // Tu implementación
}

// Crear avance con ID correcto
Future<bool> crearAvance(String descripcion) async {
  final usuarioId = await obtenerUsuarioId();
  
  if (usuarioId.isEmpty) {
    throw Exception('Usuario no autenticado');
  }
  
  final response = await http.post(
    Uri.parse('$baseUrl/avance/crearAvance'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'usuarioId': usuarioId, // ✅ ID real, no vacío
      'descripcion': descripcion,
    }),
  );
  
  return response.statusCode == 201;
}
```

## 🎯 Endpoints Actualizados

### Panel Colaborativo
```bash
GET /api/1.0/avance/estado-actividad  # Estado de usuarios con alertas
```

### Debug y Testing
```bash
GET  /api/1.0/test/ping               # Servidor funcionando
GET  /api/1.0/test/firebase           # Conexión Firebase
GET  /api/1.0/test/usuarios           # Listar usuarios
POST /api/1.0/test/usuario-por-email  # Buscar usuario por email
GET  /api/1.0/test/panel-colaborativo # Test del panel
POST /api/1.0/test/validar-avance     # Validar datos
GET  /api/1.0/test/info              # Info del servidor
```
