# API REST - Seguimiento de Avances Diarios

Este proyecto expone una API REST para gestionar usuarios y avances diarios de tareas. Incluye autenticación, creación de usuarios, avances, y asignación de alertas según la frecuencia de actualización.

## Base URL
```
http://localhost:3000/api/1.0/
```

## Endpoints Principales

---

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