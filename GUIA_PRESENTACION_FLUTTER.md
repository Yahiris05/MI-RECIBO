# Guión de Presentación: Código y Arquitectura del Prototipo en Flutter

Este guión te servirá para defender y explicar tu proyecto móvil desarrollado en **Flutter**, justificando el funcionamiento de los **servicios CRUD**, la estructura de la **base de datos local (Hive)**, la **remota (Supabase)** y el consumo de **APIs externas**.

Se divide en 5 secciones clave, estructuradas de manera técnica a partir del código fuente.

---

## 1. Inicialización y Conexión de Bases de Datos (`lib/main.dart`)
* **Código de referencia**: `lib/main.dart`
* **Qué mostrar en pantalla**: Las primeras 25 líneas del archivo `main.dart`.
* **Guión para el Expositor**:
  > *"Comenzamos el recorrido técnico por el punto de entrada de la aplicación: el archivo **`main.dart`**. Aquí inicializamos los dos motores de bases de datos que soportan la aplicación. Primero, configuramos la conexión remota con **Supabase** pasando el URL del proyecto y la Anon Key de forma asíncrona. Segundo, inicializamos el almacenamiento local **Hive** mediante `Hive.initFlutter()` y abrimos una caja física de almacenamiento llamada `'userBox'` para gestionar el estado de sesión local y la preferencia del tema visual."*

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Inicializar base de datos remota en la nube (Supabase)
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  
  // 2. Inicializar base de datos local embebida (Hive)
  await Hive.initFlutter();
  await Hive.openBox('userBox');
  
  runApp(const MyApp());
}
```

---

## 2. Mapeo de Tablas a Modelos Dart (`lib/models/`)
* **Código de referencia**: `lib/models/document.dart` y `lib/models/reminder.dart`
* **Qué mostrar en pantalla**: Métodos serializadores `toJson()` y constructores `fromJson()`.
* **Guión para el Expositor**:
  > *"Para interactuar con la base de datos relacional de Supabase, definimos clases modelo en Dart que replican de forma estricta la estructura de las tablas de PostgreSQL. Cada modelo, como **`Document`** o **`Reminder`**, incluye un constructor de fábrica `fromJson` para deserializar las respuestas de las consultas SQL, y un método `toJson` que convierte los objetos Dart en mapas clave-valor para ser insertados o actualizados en la base de datos."*

```dart
// Mapeo en lib/models/document.dart
class Document {
  final String id;
  final String supplier;
  final String type; // Factura, Comprobante, Recibo
  final String date;
  final String category;
  final double amount;
  final String notes;
  final String format;

  // Convierte un registro JSON de la Base de Datos a un Objeto Dart (Lectura)
  factory Document.fromJson(Map<String, dynamic> json) => Document(
        id: json['id'] as String,
        supplier: json['supplier'] as String,
        type: json['type'] as String,
        date: json['date'] as String,
        category: json['category'] as String,
        amount: (json['amount'] as num).toDouble(),
        notes: json['notes'] as String,
        format: json['format'] as String,
      );

  // Convierte un Objeto Dart a JSON para inserciones de Base de Datos (Creación / Edición)
  Map<String, dynamic> toJson() => {
        'id': id,
        'supplier': supplier,
        'type': type,
        'date': date,
        'category': category,
        'amount': amount,
        'notes': notes,
        'format': format,
      };
}
```

---

## 3. Servicios CRUD e Integración de Datos (`lib/services/db_service.dart`)
* **Código de referencia**: `lib/services/db_service.dart`
* **Qué mostrar en pantalla**: `fetchAll()`, `addDocument()`, `toggleReminderStatus()`, `deleteDocument()`.
* **Guión para el Expositor**:
  > *"La gestión transaccional se realiza en la clase **`DbService`**, implementada bajo el patrón Singleton para asegurar una única instancia activa en toda la app. Esta clase actúa como proveedor de estado (`ChangeNotifier`), permitiendo que la UI reaccione a los cambios del modelo. A continuación detallaremos cómo se ejecuta cada una de las operaciones CRUD hacia Supabase:"*

### A. Operación de Lectura (Read) y Sincronización:
  > *"El método **`fetchAll()`** descarga de forma asíncrona la lista de documentos y recordatorios asociados al usuario logueado en la sesión. Limpiamos la caché en memoria y la re-poblamos con objetos Dart deserializados mediante el método `fromJson` analizado previamente. Si detectamos un usuario nuevo sin datos, invocamos la función de precarga `_seedDefaultData`."*

```dart
Future<void> fetchAll() async {
  final user = _supabase.auth.currentUser;
  if (user == null) return;

  try {
    // Lectura remota filtrada de la tabla 'documents' ordenada por fecha
    final docsResponse = await _supabase
        .from('documents')
        .select()
        .order('date', ascending: false);
    
    final fetchedDocs = (docsResponse as List)
        .map((data) => Document.fromJson(data as Map<String, dynamic>))
        .toList();

    documents.clear();
    documents.addAll(fetchedDocs);
    notifyListeners(); // Avisa a la interfaz de usuario para redibujar
  } catch (e) {
    print('Error al sincronizar datos con Supabase: $e');
  }
}
```

### B. Operación de Creación (Create):
  > *"Cuando un usuario agrega un documento (manualmente o mediante OCR), llamamos a **`addDocument()`**. Este método realiza primero una **actualización optimista local** (inserta el documento en memoria para que la interfaz responda instantáneamente sin esperas) y luego ejecuta una instrucción SQL `insert` a través de la API de Supabase, vinculando el registro al `id` único del usuario autenticado."*

```dart
Future<void> addDocument(Document doc) async {
  // Inserción optimista en la lista local para no bloquear la experiencia de usuario
  documents.insert(0, doc);
  notifyListeners();

  final user = _supabase.auth.currentUser;
  if (user != null) {
    final json = doc.toJson();
    json['user_id'] = user.id; // Vinculación relacional obligatoria
    
    // Inserción remota en Supabase
    await _supabase.from('documents').insert(json);
  }
}
```

### C. Operación de Actualización (Update):
  > *"Para la actualización, mostramos el ejemplo de **`toggleReminderStatus()`**. Cuando el usuario marca un recordatorio impositivo como completado, calculamos el nuevo estado, actualizamos la caché local en memoria e invocamos una llamada de tipo `update` en Supabase filtrando por la clave primaria `id` de la alerta."*

```dart
Future<void> toggleReminderStatus(String id) async {
  final index = reminders.indexWhere((r) => r.id == id);
  if (index != -1) {
    final r = reminders[index];
    final newStatus = r.status == 'pending' ? 'completed' : 'pending';
    
    // Modificación de estado local en memoria
    reminders[index] = r.copyWith(status: newStatus);
    notifyListeners();

    // Actualización remota mediante sentencia UPDATE... WHERE id = id
    await _supabase
        .from('reminders')
        .update({'status': newStatus})
        .eq('id', id);
  }
}
```

### D. Operación de Eliminación (Delete):
  > *"Finalmente, para la eliminación, el método **`deleteDocument()`** elimina el comprobante fiscal localmente mediante un filtro en memoria y envía la petición de borrado físico `delete().eq('id', id)` al backend de Supabase. El motor de base de datos remoto de PostgreSQL procesa la eliminación."*

```dart
Future<void> deleteDocument(String id) async {
  documents.removeWhere((d) => d.id == id);
  notifyListeners();

  final user = _supabase.auth.currentUser;
  if (user != null) {
    // Borrado físico en el servidor remitiendo la clave primaria id
    await _supabase.from('documents').delete().eq('id', id);
  }
}
```

---

## 4. Consumo de API Externa (`lib/services/api_service.dart`)
* **Código de referencia**: `lib/services/api_service.dart`
* **Qué mostrar en pantalla**: El método `fetchDopExchangeRate()`.
* **Guión para el Expositor**:
  > *"Además de la base de datos, implementamos servicios para consultar datos del mercado financiero. En la clase **`ApiService`**, consumimos un Endpoint externo que provee tasas de cambio de divisas globales. El método `fetchDopExchangeRate` realiza una llamada HTTP GET, parsea el JSON resultante y extrae la tasa de conversión del dólar estadounidense (USD) a pesos dominicanos (DOP), proveyendo al Dashboard de un indicador financiero en vivo."*

```dart
Future<double> fetchDopExchangeRate() async {
  try {
    final response = await http.get(Uri.parse('https://open.er-api.com/v6/latest/USD'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final rates = data['rates'] as Map<String, dynamic>;
      final dopRate = rates['DOP'] as num; // Extrae el valor DOP
      return dopRate.toDouble();
    }
  } catch (e) {
    return 59.20; // Tasa por defecto de contingencia si no hay internet
  }
  return 59.20;
}
```

---

## 5. Autenticación y Seguridad de la Base de Datos (`lib/screens/login_screen.dart`)
* **Código de referencia**: `lib/screens/login_screen.dart` y `supabase_schema.sql`
* **Qué mostrar en pantalla**: El método `_handleAuth` y la relación relacional en SQL.
* **Guión para el Expositor**:
  > *"La autenticación de usuarios y la seguridad de la base de datos están fuertemente acopladas. En la pantalla de login, cuando un usuario se registra o inicia sesión, Supabase valida sus credenciales. Si el registro es exitoso, la base de datos local y remota interactúan de la siguiente forma:"*
  
1. **Trigger de Base de Datos**:
   > *"Diseñamos un Trigger SQL en PostgreSQL (`supabase_schema.sql`) que reacciona de forma automática tras una inserción en la tabla `auth.users` llamando a la función `handle_new_user()`. Esto crea inmediatamente un registro de perfil de la empresa en la tabla de perfiles, asegurando la consistencia relacional de los datos."*
2. **Seguridad RLS (Row Level Security)**:
   > *"Adicionalmente, habilitamos Row Level Security (RLS) en todas las tablas (`documents`, `reminders`, `profiles`). Esto significa que las operaciones CRUD de un usuario están blindadas en el servidor mediante la cláusula `auth.uid() = user_id`, impidiendo que un usuario malicioso o una empresa diferente consulte o modifique facturas ajenas."*

```dart
// Fragmento de autenticación en lib/screens/login_screen.dart
if (_isSignUp) {
  final AuthResponse response = await supabase.auth.signUp(
    email: email,
    password: password,
    data: {'name': name},
  );
  saveUserData(email, name); // Guarda la sesión en local con Hive
} else {
  final AuthResponse response = await supabase.auth.signInWithPassword(
    email: email,
    password: password,
  );
  saveUserData(email, fetchedName);
}
```
