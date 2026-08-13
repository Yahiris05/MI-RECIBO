# Guión de Presentación Final - MI RECIBO RD

Este guión está estructurado para servir de apoyo durante la exposición del proyecto final. Sigue el orden de diapositivas sugerido y detalla lo que se debe explicar sobre la página web, sus funcionalidades y cada pantalla de diseño del prototipo Figma.

---

## Diapositiva 1: Introducción y Propósito
* **Título**: MI RECIBO RD - Gestión inteligente de comprobantes para MIPYMES.
* **Guión para el Expositor**:
  > *"Buenas tardes a todos. Hoy les presentaré **MI RECIBO RD**, una solución tecnológica diseñada específicamente para las micro, pequeñas y medianas empresas de la República Dominicana. El propósito de este proyecto es simplificar la gestión fiscal diaria. Las MIPYMES a menudo se enfrentan a dos grandes problemas: el desorden de facturas físicas que dificulta el reporte de impuestos y el riesgo de multas debido al olvido de fechas límites de la DGII. Con MI RECIBO RD, automatizamos la digitalización y organizamos las alertas en un solo lugar seguro."*

---

## Diapositiva 2: Estructura del Prototipo en Figma (Lienzo Simulador)
* **Título**: Lienzo de Diseño de Alta Fidelidad.
* **Guión para el Expositor**:
  > *"Como entregable clave del diseño de experiencia de usuario (UX/UI), creamos un simulador de lienzos de Figma que permite inspeccionar los 7 artboards esenciales del flujo de la aplicación. Cada pantalla ha sido diseñada siguiendo un sistema estético premium moderno con tipografías claras, iconografía consistente y un esquema de color adaptado a la identidad corporativa dominicana. A continuación, recorreremos cada una de estas 7 pantallas clave:"*
  
1. **Artboard 1: Splash / Onboarding**:
   > *"Esta es la pantalla de bienvenida. Su función es educar al usuario nuevo en 3 puntos clave: el escaneo de facturas, los recordatorios fiscales y el respaldo seguro en la nube. Cuenta con ilustraciones animadas de fondo y un botón destacado para comenzar."*
2. **Artboard 2: Iniciar Sesión (Login)**:
   > *"Un formulario limpio y seguro diseñado para que la empresa acceda con sus credenciales de correo empresarial. Cuenta con controles visuales interactivos como la visibilidad de contraseña."*
3. **Artboard 3: Dashboard / Inicio**:
   > *"El centro neurálgico de la aplicación. Aquí el usuario ve de un vistazo: estadísticas clave del mes (cantidad de facturas, recordatorios urgentes, categorías activas), un widget interactivo que muestra la **tasa de cambio oficial de USD a DOP en tiempo real** consumida mediante API, y un banner dinámico del próximo recordatorio impositivo importante."*
4. **Artboard 4: Mis Documentos**:
   > *"Aquí se listan cronológicamente todas las facturas y comprobantes. Incluye filtros rápidos por tipo (Facturas, Recibos o Comprobantes) y una barra de búsqueda inteligente que busca en caliente por proveedor o descripción."*
5. **Artboard 5: Escáner de Recibos**:
   > *"Simula la cámara del dispositivo móvil. Incorpora guías visuales de encuadre, efecto de flash al capturar y una línea láser animada para simular el reconocimiento óptico de caracteres (OCR) que extrae los datos del papel de forma automática."*
6. **Artboard 6: Formulario de Registro (Crear / Editar)**:
   > *"Aparece tras tomar la foto del recibo o al editar uno existente. Permite validar los campos extraídos: proveedor, tipo de comprobante, fecha, monto en pesos dominicanos, categoría y notas explicativas."*
7. **Artboard 7: Recordatorios (Alertas)**:
   > *"Una agenda fiscal interactiva con tres pestañas: Próximos, Calendario y Completados. Permite visualizar las alertas de impuestos prioritarias por urgencia y tiempo restante."*
8. **Artboard 8: Perfil de la Empresa**:
   > *"Pantalla de configuración corporativa donde se visualiza el RNC de la empresa, teléfono de contacto y controles de sesión, junto con la opción de restablecer la base de datos de demostración."*

---

## Diapositiva 3: Funcionamiento de los Servicios y CRUD en el Simulador Web
* **Título**: Demostración Práctica del Simulador e Integración CRUD.
* **Guión para el Expositor**:
  > *"Para demostrar el funcionamiento cohesivo de todas estas partes, desarrollamos un simulador web interactivo en HTML, CSS y Javascript. En este simulador hemos integrado de manera funcional todas las operaciones CRUD (Crear, Leer, Actualizar y Eliminar) sobre la información de la base de datos local (sincronizada en LocalStorage):"*
  
* **Operación de Creación (Create)**:
  > *"Podemos simular la captura de un recibo en la sección de escáner. El sistema procesa la imagen e inicia el formulario prellenado para guardar el documento. De igual manera, en la pantalla de alertas podemos hacer clic en el botón '+' para crear recordatorios personalizados de manera dinámica."*
* **Operación de Lectura (Read)**:
  > *"Tanto el listado de comprobantes como de alertas se cargan en tiempo real. El buscador permite filtrar los registros instantáneamente sin recargar la página."*
* **Operación de Actualización (Update)**:
  > *"Al hacer clic en cualquier factura o alerta, abrimos un modal de detalles. Desde allí podemos cambiar el estado de un recordatorio (de pendiente a completado) o hacer clic en 'Editar' para modificar cualquier campo del documento, actualizando los registros en el almacenamiento local de forma inmediata."*
* **Operación de Eliminación (Delete)**:
  > *"Los modales de detalles incorporan un botón rojo de eliminación. Al pulsarlo, el registro es removido de la base de datos local, lo que recalcula al instante las estadísticas del Dashboard (como la cantidad de facturas mensuales y el conteo de recordatorios pendientes)."*

---

## Diapositiva 4: Estructura y Funcionamiento de la Base de Datos Real (Flutter / Supabase)
* **Título**: Arquitectura de Datos Sincronizada.
* **Guión para el Expositor**:
  > *"Finalmente, a nivel de producción móvil en Flutter, la aplicación está conectada a una arquitectura de base de datos robusta de dos niveles:"*
  
1. **Base de Datos Local (Hive)**:
   > *"Utilizamos Hive para almacenar en caché las variables de sesión del usuario y las configuraciones del dispositivo (como el modo oscuro). Esto garantiza que la app inicie instantáneamente y guarde configuraciones offline."*
2. **Base de Datos Relacional (Supabase PostgreSQL)**:
   > *"Toda la información transaccional reside en tablas normalizadas en la nube. La tabla de perfiles empresariales se crea automáticamente gracias a un trigger de automatización en PostgreSQL llamado `on_auth_user_created` cuando un usuario se registra. Asimismo, protegemos el acceso a los datos utilizando Row Level Security (RLS) para que cada empresa sólo pueda consultar y modificar sus propios documentos y recordatorios."*

---

## Diapositiva 5: Conclusiones
* **Título**: Conclusiones del Proyecto.
* **Guión para el Expositor**:
  > *"En conclusión, MI RECIBO RD demuestra cómo la integración de un diseño centrado en el usuario, una base de datos local y remota sincronizada y servicios CRUD ágiles pueden transformar la gestión fiscal de pequeños negocios en la República Dominicana. El prototipo está completamente operativo y listo para su despliegue y uso. Quedo atento a sus preguntas. Muchas gracias."*
