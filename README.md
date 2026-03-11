# Alarma Comunitaria 🚨

¡Bienvenido al repositorio oficial de **Alarma Comunitaria**! 

Este proyecto es una aplicación móvil desarrollada en **Flutter** diseñada para fortalecer la seguridad de los barrios y comunidades mediante un sistema de alertas rápidas y efectivas. 

**Objetivo**: Permitir a los vecinos solicitar ayuda de forma inmediata, enviando notificaciones críticas y acústicas en tiempo real al resto de la comunidad en caso de emergencia, garantizando que nadie pase desapercibido.

**Proceso**: Para lograr esto de manera robusta y escalable, la aplicación se apoya fundamentalmente en dos tecnologías clave:
1. **Supabase**: Actúa como el *Backend-as-a-Service* (BaaS) principal, manejando la base de datos (PostgreSQL), la autenticación segura de los usuarios y exponiendo la lógica del servidor a través de *Edge Functions*. Cuando un usuario activa la alarma, el registro se guarda en tiempo real en la base de datos.
2. **Firebase Cloud Messaging (FCM)**: Es el motor de distribución de notificaciones push. Una vez que la base de datos de Supabase recibe la alerta de pánico, una *Edge Function* se dispara automáticamente comunicándose con FCM.

**Resultados**: Un sistema altamente reactivo e instantáneo. Gracias a la combinación de Supabase (por su inmediatez en escritura y disparadores) y FCM (por su fiabilidad en la entrega push), se logra hacer sonar una alarma ruidosa y persistente en los teléfonos de todos los vecinos registrados en el barrio en cuestión de milisegundos, asegurando que la emergencia sea notificada y atendida incluso si los dispositivos están en reposo o la aplicación está cerrada.
---

## 🚀 Características Principales

*   **Autenticación Segura**: Sistema de registro e inicio de sesión para residentes, validado y gestionado a través de Supabase Auth.
*   **Activación de Alertas (Pánico)**: Botón principal de emergencia para notificar al instante a todos los vecinos registrados en el sector o barrio.
*   **Geolocalización en Tiempo Real**: Identificación y envío de la ubicación exacta del usuario que activa la alarma, para facilitar una respuesta rápida.
*   **Notificaciones Push (FCM)**: Integración con Firebase Cloud Messaging (FCM) mediante Supabase Edge Functions para asegurar que todos los vecinos reciban alertas ruidosas y visuales, incluso si la app está cerrada.
*   **Roles y Permisos**: 
    *   **Administradores / Supervisores / Presidentes de Barrio**: Tienen privilegios ampliados como gestionar miembros, visualizar la lista completa de vecinos, aprobar nuevos usuarios y desactivar alarmas activas.
    *   **Vecinos (Usuarios regulares)**: Pueden enviar alertas y recibir notificaciones del barrio.
*   **Gestión de Alertas Activas**: Panel de control donde los administradores pueden visualizar qué alertas están sonando y desactivarlas de forma controlada una vez resuelta la emergencia.
*   **Perfiles de Usuario**: Visualización y gestión de la información personal de cada vecino (nombre, cédula/DNI, dirección, teléfono).

---

## 🛠️ Stack Tecnológico

La aplicación está construida sobre tecnologías modernas, garantizando escalabilidad, rendimiento y facilidad de mantenimiento:

### Frontend (Aplicación Móvil)
*   **Framework**: [Flutter](https://flutter.dev/) (Dart)
*   **Gestor de Estados**: Provider
*   **Enrutamiento**: Go Router
*   **Mapas y Ubicación**: Geolocator / URL Launcher

### Backend y Base de Datos (BaaS)
*   **Plataforma**: [Supabase](https://supabase.com/) (PostgreSQL)
*   **Autenticación**: Supabase Auth
*   **Reglas de Seguridad**: Row Level Security (RLS) gestionadas en PostgreSQL
*   **Lógica Servidor (Serverless)**: Supabase Edge Functions (Deno) para conexiones a servicios externos.

### Notificaciones
*   **Servicio**: Firebase Cloud Messaging (FCM) para envíos push.
*   **Local UI**: Flutter Local Notifications para controlar sonidos persistentes e interfaces de alerta visual de alta prioridad.

---

## ⚙️ Configuración del Entorno de Desarrollo

Sigue estos pasos para levantar el proyecto en tu entorno local:

### 1. Pre-requisitos
*   Tener instalado [Flutter SDK](https://docs.flutter.dev/get-started/install) (versión >= 3.0.0).
*   Tener configurado un emulador de Android/iOS o un dispositivo físico conectado.
*   Crear un proyecto en [Supabase](https://supabase.com/).
*   Crear un proyecto en [Firebase Core](https://firebase.google.com/) (para habilitar FCM).

### 2. Clonar el repositorio
```bash
git clone https://github.com/TU-USUARIO/Alarma-Comunitaria.git
cd Alarma-Comunitaria/app
```

### 3. Instalar dependencias
```bash
flutter pub get
```

### 4. Configurar Variables de Entorno (`.env`)
Debes crear un archivo `.env` en la raíz del proyecto (carpeta `app`) basándote en un archivo de plantilla (si existe) y agregar las credenciales de tu propio proyecto Supabase:

```env
SUPABASE_URL="https://tu-id-de-proyecto.supabase.co"
SUPABASE_ANON_KEY="tu-clave-anon-publica-de-supabase"
```

*Nota: Asegúrate de que tu `.env` esté agregado al `.gitignore` para no subir claves al repositorio.*

### 5. Configurar Firebase Configurations (Opcional, pero recomendado para notificaciones)
*   Asegúrate de agregar tus archivos generados por Firebase (`google-services.json` para Android y `GoogleService-Info.plist` para iOS) en sus rutas correspondientes (`android/app/` e `ios/Runner/`).

### 6. Ejecutar la aplicación
```bash
flutter run
```

---

## 🤝 Contribuciones

Este proyecto busca empoderar a las comunidades para cuidarse mutuamente. Si tienes ideas de mejora, detectas algún error (bug) o quieres proponer nuevas funcionalidades (feature), ¡eres bienvenido a contribuir!

1.  Haz un **Fork** del repositorio.
2.  Crea una nueva rama (`git checkout -b feature/NuevaFuncionalidad`).
3.  Haz tus cambios y confirmalos (`git commit -m 'Añadida Nueva Funcionalidad'`).
4.  Sube la rama (`git push origin feature/NuevaFuncionalidad`).
5.  Abre un **Pull Request**.

---

## 📄 Licencia

Este proyecto está bajo la Licencia **MIT** - mira el archivo [LICENSE](LICENSE) para más detalles. (Opcional, en caso de agregar un archivo de licencia).

---
*Para construir comunidades más seguras, unidas y protegidas.* 🛡️🤝
