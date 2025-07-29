# ProgressColab

Una aplicación Flutter para el seguimiento colaborativo del progreso académico.

## Descripción

ProgressColab es una aplicación móvil desarrollada en Flutter que permite a los estudiantes y profesores realizar un seguimiento colaborativo del progreso académico. La aplicación incluye funcionalidades de autenticación, gestión de usuarios y seguimiento de avances.

## Características

- 🔐 Autenticación de usuarios con Firebase
- 👥 Gestión de perfiles de usuario
- 📊 Seguimiento de progreso académico
- 🤝 Funcionalidades colaborativas
- 📱 Interfaz moderna y responsive

## Tecnologías Utilizadas

- **Flutter**: Framework de desarrollo móvil
- **Firebase**: Backend y autenticación
  - Firebase Auth
  - Cloud Firestore
- **HTTP**: Comunicación con APIs
- **Provider**: Gestión de estado
- **Shared Preferences**: Almacenamiento local
- **Google Fonts**: Tipografías personalizadas

## Requisitos Previos

- Flutter SDK (versión 3.8.0 o superior)
- Dart SDK
- Android Studio / VS Code
- Cuenta de Firebase (para funcionalidades de backend)

## Instalación

1. Clona el repositorio:
```bash
git clone https://github.com/LuisBurbano/ProgressColab.git
cd ProgressColab
```

2. Instala las dependencias:
```bash
flutter pub get
```

3. Configura Firebase (opcional):
   - Crea un proyecto en Firebase Console
   - Descarga el archivo `google-services.json` para Android
   - Descarga el archivo `GoogleService-Info.plist` para iOS
   - Coloca los archivos en las carpetas correspondientes

4. Ejecuta la aplicación:
```bash
flutter run
```

## Estructura del Proyecto

```
lib/
├── main.dart              # Punto de entrada de la aplicación
├── screens/               # Pantallas de la aplicación
│   ├── home_screen.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   └── test_connection_screen.dart
└── services/              # Servicios y lógica de negocio
    ├── api_service.dart
    ├── auth_service.dart
    ├── avance_service.dart
    └── user_service.dart
```

## Contribución

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## Autor

**Luis Burbano** - [GitHub](https://github.com/LuisBurbano)
**Leonardo De la Cadena** - [GitHub](https://github.com/leodlc)
**Paola Moncayo** - [GitHub](https://github.com/PaolaMoncayo)

## Agradecimientos

- Flutter team por el excelente framework
- Firebase por las herramientas de backend
- Comunidad Flutter por el soporte continuo
