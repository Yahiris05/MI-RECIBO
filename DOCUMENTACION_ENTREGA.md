# Reporte de Entrega Final - MI RECIBO RD

Este documento consolida la arquitectura técnica, el diseño de base de datos y la guía de servicios de **MI RECIBO RD**, un sistema diseñado para la gestión digitalizada de comprobantes fiscales, facturas y alertas de vencimientos de compromisos fiscales.

---

## 1. Descripción General del Proyecto

### Propósito y Objetivos
**MI RECIBO RD** nace con el objetivo de dotar a las micro y pequeñas empresas (MIPYMES) en la República Dominicana de una herramienta ágil y moderna para:
* **Digitalizar e indexar comprobantes**: Capturar facturas físicas por medio de la cámara del dispositivo móvil mediante simulación de escaneo inteligente (OCR).
* **Control de alertas y recordatorios**: Reducir el riesgo de penalidades fiscales mediante recordatorios inteligentes de fechas límites clave (tales como la declaración mensual del ITBIS o la renovación de licencias).
* **Tasa de cambio en tiempo real**: Proporcionar información financiera actualizada (tasas de cambio de divisas del dólar USD a DOP) consultada en tiempo real.
* **Seguridad y sincronización en la nube**: Almacenamiento seguro, autenticación robusta y sincronización automática.

---

## 2. Base de Datos Local y Remota

El proyecto implementa una arquitectura híbrida de base de datos para garantizar una operación eficiente y almacenamiento seguro:

* **Base de Datos Local**:
  - **Hive (Flutter App)**: Motor NoSQL rápido que almacena localmente el estado de sesión del usuario y las preferencias estéticas (`isLoggedIn`, `email`, `name`, `rememberMe` y `isDarkMode`).
  - **LocalStorage (Web Simulator)**: En el simulador interactivo web, el almacenamiento local se emula directamente con el API de `localStorage` del navegador, sincronizando las listas de documentos, recordatorios, estadísticas e información del perfil empresarial entre recargas.
* **Base de Datos Relacional: Supabase (PostgreSQL)**:
  La base de datos remota está diseñada sobre PostgreSQL en Supabase, implementando normalización en tercera forma normal (3FN) y políticas de seguridad a nivel de fila (Row Level Security - RLS).

#### Estructura del Esquema (`supabase_schema.sql`):
1. **Tabla de Perfiles (`profiles`)**:
   - `id` (uuid, clave primaria, referenciada a `auth.users` con cascada al borrar).
   - `name` (text, nombre de la empresa).
   - `rnc` (text, Registro Nacional de Contribuyente).
   - `phone` (text, teléfono de contacto).
2. **Tabla de Documentos (`documents`)**:
   - `id` (text, clave primaria).
   - `supplier` (text, proveedor).
   - `type` (text, tipo de comprobante: Factura, Recibo, Comprobante).
   - `date` (text, fecha del documento).
   - `category` (text, categoría).
   - `amount` (numeric, monto total).
   - `notes` (text, comentarios).
   - `format` (text, formato físico/digital).
   - `user_id` (uuid, clave foránea de `auth.users`).
3. **Tabla de Recordatorios (`reminders`)**:
   - `id` (text, clave primaria).
   - `title` (text, título de la alerta).
   - `date` (text, fecha límite).
   - `days_left` (integer, días restantes).
   - `urgency` (text, nivel de urgencia: Importante, Normal).
   - `status` (text, estado: pending, completed).
   - `user_id` (uuid, clave foránea de `auth.users`).

#### Trigger de Automatización:
Cuando se registra un nuevo usuario en la base de datos de autenticación de Supabase (`auth.users`), se ejecuta automáticamente la función `handle_new_user()` que crea el perfil correspondiente en la tabla `public.profiles` con valores predeterminados seguros.

---

## 3. Servicios y Funciones Básicas

### A. Autenticación de Usuarios
* **Flutter**: Se utiliza el cliente de Supabase Auth mediante llamadas a `supabase.auth.signInWithPassword()` para inicio de sesión y `supabase.auth.signUp()` para registro.
* **Web Simulator**: Se valida la sesión con el email empresarial introducido y se almacena el estado `isLoggedIn` en el almacenamiento local.

### B. Funciones CRUD (Base de Datos)
El servicio de datos de Flutter (`DbService`) y la lógica de simulación web ejecutan las siguientes acciones esenciales:
* **Crear**: Inserción de documentos escaneados e ingreso manual de recordatorios.
* **Leer**: Consulta filtrada de facturas por buscador de texto libre o categorías, y listado de alertas pendientes organizadas por urgencia y fecha límite.
* **Actualizar**:
  - Modificación completa de campos de un comprobante (proveedor, fecha, monto, notas).
  - Modificación de título, fecha de vencimiento y prioridad en alertas.
  - Sincronización de cambio de estado de recordatorios (Pendiente / Completado).
* **Eliminar**: Remoción física de registros desde el panel detallado del modal.

### C. Consumo de API Externa (`ApiService`)
El módulo de integración API externa consulta tasas de cambio en tiempo real:
* **EndPoint de Tasa de Cambio**: Utiliza `https://open.er-api.com/v6/latest/USD` para capturar la cotización actual del dólar estadounidense (USD) a pesos dominicanos (DOP). Esto se despliega de manera dinámica en la cabecera del Dashboard.

---

## 4. Prototipo Figma y Simulador Web

El prototipo del proyecto está representado a través de dos interfaces web de alta fidelidad:
1. **Lienzo de Figma (`figma_design_prototype.html`)**: Mapea en alta definición el flujo visual completo (7 artboards organizados secuencialmente).
2. **Aplicación Simulador (`index.html`)**: Emulación web interactiva del móvil que permite operar las pantallas y realizar todas las funciones de base de datos en tiempo real.

### Flujo de Pantallas:
1. **Splash Onboarding**: Bienvenida al usuario, presentación de características del producto y acceso rápido a la aplicación.
2. **Inicio de Sesión**: Autenticación empresarial simple.
3. **Dashboard de Inicio**: Resumen de estadísticas clave, indicador dinámico de tasa de cambio y panel de acceso directo al siguiente recordatorio prioritario.
4. **Listado de Documentos**: Visualización tipo lista de facturas registradas con filtrado dinámico en caliente (Facturas, Recibos, Comprobantes) y barra de búsqueda predictiva.
5. **Cámara / Escáner inteligente**: Simulación de visor de cámara con láser y flash animado que realiza lectura automática (OCR) de datos de factura.
6. **Formulario de Registro (Create/Edit)**: Pantalla dedicada para verificar datos escaneados o ingresados manualmente, con soporte para edición en caliente.
7. **Recordatorios / Alertas**: Lista interactiva organizada por pestañas que permite crear, editar y eliminar tareas y alertas impositivas.
8. **Perfil Empresarial**: Acceso a datos del RNC, teléfono corporativo y botones para reiniciar la base de datos de demostración o cerrar sesión.
