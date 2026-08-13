import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/document.dart';
import '../models/reminder.dart';

class DbService extends ChangeNotifier {
  static final DbService instance = DbService._internal();
  DbService._internal();

  final _supabase = Supabase.instance.client;

  // Listas en memoria que actúan como caché sincronizado
  final List<Document> documents = [];
  final List<Reminder> reminders = [];

  // Método para sincronizar todos los datos desde Supabase
  Future<void> fetchAll() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      documents.clear();
      reminders.clear();
      return;
    }

    try {
      // 1. Obtener documentos del usuario actual
      final docsResponse = await _supabase
          .from('documents')
          .select()
          .order('date', ascending: false);
      
      final fetchedDocs = (docsResponse as List)
          .map((data) => Document.fromJson(data as Map<String, dynamic>))
          .toList();

      documents.clear();
      documents.addAll(fetchedDocs);

      // 2. Obtener recordatorios del usuario actual
      final remindersResponse = await _supabase
          .from('reminders')
          .select()
          .order('date', ascending: true);

      final fetchedReminders = (remindersResponse as List)
          .map((data) => Reminder.fromJson(data as Map<String, dynamic>))
          .toList();

      reminders.clear();
      reminders.addAll(fetchedReminders);

      // Si el usuario es nuevo y no tiene ningún dato, pre-poblamos con datos de demostración
      if (documents.isEmpty && reminders.isEmpty) {
        await _seedDefaultData(user.id);
      }
      notifyListeners();
    } catch (e) {
      print('Error al sincronizar datos con Supabase: $e');
      rethrow;
    }
  }

  // Guardar un nuevo documento en memoria y en Supabase
  Future<void> addDocument(Document doc) async {
    // Actualización optimista de la UI (inserción local inmediata)
    documents.insert(0, doc);
    notifyListeners();

    final user = _supabase.auth.currentUser;
    if (user != null) {
      final json = doc.toJson();
      json['user_id'] = user.id;
      
      try {
        await _supabase.from('documents').insert(json);
      } catch (e) {
        print('Error al guardar documento en Supabase: $e');
        // Si falla la inserción real, podemos recargar para mantener la consistencia
        await fetchAll();
        rethrow;
      }
    }
  }

  // Guardar un nuevo recordatorio en memoria y en Supabase
  Future<void> addReminder(Reminder reminder) async {
    // Actualización optimista de la UI (inserción local inmediata)
    reminders.insert(0, reminder);
    notifyListeners();

    final user = _supabase.auth.currentUser;
    if (user != null) {
      final json = reminder.toJson();
      json['user_id'] = user.id;
      
      try {
        await _supabase.from('reminders').insert(json);
      } catch (e) {
        print('Error al guardar recordatorio en Supabase: $e');
        // Si falla la inserción real, podemos recargar para mantener la consistencia
        await fetchAll();
        rethrow;
      }
    }
  }

  // Alternar el estado del recordatorio en memoria y en Supabase
  Future<void> toggleReminderStatus(String id) async {
    final index = reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      final r = reminders[index];
      final newStatus = r.status == 'pending' ? 'completed' : 'pending';
      
      // Actualización optimista local
      reminders[index] = r.copyWith(status: newStatus);
      notifyListeners();

      try {
        await _supabase
            .from('reminders')
            .update({'status': newStatus})
            .eq('id', id);
      } catch (e) {
        print('Error al actualizar recordatorio en Supabase: $e');
        await fetchAll();
        rethrow;
      }
    }
  }

  // Eliminar un documento en memoria y en Supabase
  Future<void> deleteDocument(String id) async {
    documents.removeWhere((d) => d.id == id);
    notifyListeners();

    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        await _supabase.from('documents').delete().eq('id', id);
      } catch (e) {
        print('Error al eliminar documento en Supabase: $e');
        await fetchAll();
        rethrow;
      }
    }
  }

  // Eliminar un recordatorio en memoria y en Supabase
  Future<void> deleteReminder(String id) async {
    reminders.removeWhere((r) => r.id == id);
    notifyListeners();

    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        await _supabase.from('reminders').delete().eq('id', id);
      } catch (e) {
        print('Error al eliminar recordatorio en Supabase: $e');
        await fetchAll();
        rethrow;
      }
    }
  }

  int get pendingRemindersCount {
    return reminders.where((r) => r.status == 'pending').length;
  }

  // Pre-poblar datos de demostración para nuevos usuarios
  Future<void> _seedDefaultData(String userId) async {
    final defaultDocs = [
      Document(
        id: "doc-1",
        supplier: "EDEEste",
        type: "Factura",
        date: "2024-05-08",
        category: "Servicios públicos",
        amount: 1540.20,
        notes: "Pago de electricidad mensual local comercial.",
        format: "PDF",
      ),
      Document(
        id: "doc-2",
        supplier: "Office Depot",
        type: "Factura",
        date: "2024-05-07",
        category: "Útiles de oficina",
        amount: 4920.00,
        notes: "Compra de suministros: Resmas de papel, tóner HP y carpetas.",
        format: "PDF",
      ),
      Document(
        id: "doc-3",
        supplier: "Altice",
        type: "Factura",
        date: "2024-05-06",
        category: "Telecomunicaciones",
        amount: 2200.00,
        notes: "Servicio de internet fibra óptica y telefonía fija.",
        format: "PDF",
      ),
      Document(
        id: "doc-4",
        supplier: "IMCA",
        type: "Comprobante",
        date: "2024-05-05",
        category: "Mantenimiento",
        amount: 8900.50,
        notes: "Mantenimiento preventivo de planta eléctrica.",
        format: "PDF",
      ),
      Document(
        id: "doc-5",
        supplier: "Recibo de pago equipo",
        type: "Recibo",
        date: "2024-05-04",
        category: "Tecnología",
        amount: 12500.00,
        notes: "Compra de periféricos de oficina (teclados y monitores).",
        format: "PDF",
      ),
      Document(
        id: "doc-6",
        supplier: "Factura Agua",
        type: "Factura",
        date: "2024-05-03",
        category: "Servicios públicos",
        amount: 450.00,
        notes: "Factura mensual CAASD.",
        format: "PDF",
      ),
    ];

    final defaultReminders = [
      Reminder(
        id: "rem-1",
        title: "Declaración ITBIS",
        date: "2024-05-12",
        daysLeft: 3,
        urgency: "Importante",
        status: "pending",
      ),
      Reminder(
        id: "rem-2",
        title: "Renovación licencia comercial",
        date: "2024-05-19",
        daysLeft: 10,
        urgency: "Importante",
        status: "pending",
      ),
      Reminder(
        id: "rem-3",
        title: "Pago Seguridad Social",
        date: "2024-05-27",
        daysLeft: 18,
        urgency: "Normal",
        status: "pending",
      ),
      Reminder(
        id: "rem-4",
        title: "Renovación póliza de seguro",
        date: "2024-06-03",
        daysLeft: 25,
        urgency: "Normal",
        status: "pending",
      ),
      Reminder(
        id: "rem-5",
        title: "Pago de Alquiler",
        date: "2024-06-08",
        daysLeft: 30,
        urgency: "Normal",
        status: "pending",
      ),
    ];

    try {
      // Mapear e insertar documentos vinculándolos al usuario actual
      final docsJson = defaultDocs.map((d) {
        final json = d.toJson();
        json['user_id'] = userId;
        return json;
      }).toList();
      await _supabase.from('documents').insert(docsJson);

      // Mapear e insertar recordatorios vinculándolos al usuario actual
      final remindersJson = defaultReminders.map((r) {
        final json = r.toJson();
        json['user_id'] = userId;
        return json;
      }).toList();
      await _supabase.from('reminders').insert(remindersJson);

      // Poblar listas locales para visualización inmediata
      documents.addAll(defaultDocs);
      reminders.addAll(defaultReminders);
    } catch (e) {
      print('Error al pre-poblar los datos de demostración: $e');
    }
  }
}
