# MI RECIBO 

Este documento consolida la arquitectura técnica, el diseño de base de datos y la guía de servicios de **MI RECIBO RD**, un sistema diseñado para la gestión digitalizada de comprobantes fiscales, facturas y alertas de vencimientos de compromisos fiscales.

---

## 1. Descripción General
**MI RECIBO** nace con el objetivo de dotar a las micro y pequeñas empresas (MIPYMES) en la República Dominicana de una herramienta ágil y moderna para:

*   **Digitalizar e indexar comprobantes:** Captura de facturas físicas mediante simulación de escaneo inteligente (OCR).
*   **Control de alertas y recordatorios:** Mitigación de riesgos de penalidades fiscales mediante recordatorios inteligentes de fechas límites (ITBIS, renovaciones, etc.).
*   **Tasa de cambio en tiempo real:** Información financiera actualizada (USD a DOP) integrada en el panel principal.
*   **Seguridad y sincronización:** Autenticación robusta y almacenamiento sincronizado en la nube.

---

## 2. Base de Datos y Arquitectura
El proyecto implementa una arquitectura híbrida para garantizar eficiencia y disponibilidad:

### Base de Datos Local
*   **Flutter (Hive):** Motor NoSQL para persistencia de sesión y preferencias de usuario (isLoggedIn, email, name, darkMode, etc.).
*   **Web Simulator (LocalStorage):** Emulación de persistencia en navegador para sincronizar estados entre sesiones.

### Base de Datos Remota (Supabase - PostgreSQL)
Diseñada en tercera forma normal (3FN) con políticas de **Row Level Security (RLS)**.

#### Esquema de Tablas
| Tabla | Descripción |
| :--- | :--- |
| **profiles** | Datos empresariales (id, name, rnc, phone). |
| **documents** | Registro de facturas y comprobantes. |
| **reminders** | Gestión de alertas fiscales y estados. |

> **Automatización:** Se utiliza un trigger `handle_new_user()` que crea automáticamente el registro en `public.profiles` al registrarse un usuario en `auth.users`.

---

## 3. Servicios Principales

### A. Autenticación
*   **Flutter:** Integración con `Supabase Auth` (signIn/signUp).
*   **Web:** Validación de sesión mediante email empresarial y persistencia local.

### B. Funciones CRUD
*   **Crear:** Inserción de documentos y recordatorios.
*   **Leer:** Consultas filtradas por texto libre, categorías y niveles de urgencia.
*   **Actualizar:** Edición en caliente de campos (facturas y alertas) y cambios de estado (Pendiente/Completado).
*   **Eliminar:** Gestión de registros desde el panel detallado.

### C. API Externa
*   **Tasa de Cambio:** Consumo de [Exchange Rate API](https://open.er-api.com/v6/latest/USD) para obtener el valor del dólar (USD) frente al peso dominicano (DOP) en tiempo real.

---

## 4. Prototipado y Simulador
El proyecto cuenta con dos entornos visuales:

1.  **Lienzo de Figma:** Mapeo de alta fidelidad con 7 artboards para el flujo de usuario.
2.  **Aplicación Simulador (`index.html`):** Emulación interactiva que permite probar la lógica de la aplicación y la persistencia de datos en el navegador.

### Flujo de la Aplicación
1.  **Splash Onboarding:** Presentación de valor y acceso.
2.  **Login:** Autenticación empresarial.
3.  **Dashboard:** Resumen financiero, tasa de cambio y alertas prioritarias.
4.  **Listado de Documentos:** Búsqueda predictiva y filtrado inteligente.
5.  **Cámara / OCR:** Simulación de escaneo.
6.  **Formulario de Registro:** Edición de datos escaneados.
7.  **Gestión de Alertas:** Control de vencimientos.
8.  **Perfil:** Gestión de cuenta y configuración.
