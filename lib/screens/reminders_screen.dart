import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/db_service.dart';
import '../models/reminder.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  String _activeFilter = 'Próximos'; // Próximos, Calendario, Completados

  final List<String> _filters = ['Próximos', 'Calendario', 'Completados'];

  @override
  void initState() {
    super.initState();
    DbService.instance.addListener(_onDbChanged);
  }

  @override
  void dispose() {
    DbService.instance.removeListener(_onDbChanged);
    super.dispose();
  }

  void _onDbChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = DbService.instance;
    
    // Si el filtro activo es "Completados", mostramos los completados.
    // De lo contrario (Próximos / Calendario), los pendientes.
    final targetStatus = _activeFilter == 'Completados' ? 'completed' : 'pending';
    
    final filteredReminders = db.reminders.where((r) => r.status == targetStatus).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () {},
        ),
        title: const Text(
          'Recordatorios',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          // Filtros de categoría exactos al mockup
          Container(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            padding: const EdgeInsets.only(top: 8, bottom: 16, left: 20, right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _filters.map((filter) {
                final isActive = _activeFilter == filter;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Container(
                        alignment: Alignment.center,
                        child: Text(
                          filter,
                          style: TextStyle(
                            color: isActive ? Colors.white : AppColors.textMuted,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      selected: isActive,
                      selectedColor: AppColors.primaryNavy,
                      backgroundColor: AppColors.bgInput,
                      checkmarkColor: Colors.white,
                      showCheckmark: false,
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _activeFilter = filter;
                          });
                        }
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide.none,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Listado de recordatorios
          Expanded(
            child: filteredReminders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _activeFilter == 'Completados' ? Icons.check_circle_outline : Icons.calendar_today_outlined,
                          size: 48,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _activeFilter == 'Completados'
                              ? 'No hay recordatorios completados'
                              : 'No hay recordatorios pendientes',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredReminders.length,
                    itemBuilder: (context, index) {
                      final reminder = filteredReminders[index];
                      return _buildReminderCard(reminder, db);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddReminderBottomSheet(context, db),
        backgroundColor: AppColors.primaryNavy,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  void _showAddReminderBottomSheet(BuildContext context, DbService db) {
    final titleController = TextEditingController();
    DateTime? selectedDate;
    String selectedUrgency = 'Normal';
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Nuevo recordatorio',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textMuted),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Concepto o título',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: 'Ej. Declaración ITBIS',
                        filled: true,
                        fillColor: AppColors.bgInput,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingresa un título';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Fecha de vencimiento',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppColors.primaryNavy,
                                  onPrimary: Colors.white,
                                  onSurface: AppColors.textDark,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (pickedDate != null) {
                          setModalState(() {
                            selectedDate = pickedDate;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.bgInput,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              selectedDate == null
                                  ? 'Selecciona una fecha'
                                  : '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: selectedDate == null ? AppColors.textMuted : AppColors.textDark,
                                fontSize: 14,
                              ),
                            ),
                            const Icon(Icons.calendar_today, color: AppColors.textMuted, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Prioridad / Urgencia',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: ['Normal', 'Importante'].map((urgency) {
                        final isSelected = selectedUrgency == urgency;
                        final activeColor = urgency == 'Importante'
                            ? AppColors.statusImportantText
                            : Colors.teal;
                        final activeBg = urgency == 'Importante'
                            ? AppColors.statusImportantBg
                            : Colors.teal.shade50;

                        return Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: ChoiceChip(
                            label: Text(urgency),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) {
                                setModalState(() {
                                  selectedUrgency = urgency;
                                });
                              }
                            },
                            selectedColor: activeBg,
                            backgroundColor: AppColors.bgInput,
                            labelStyle: TextStyle(
                              color: isSelected ? activeColor : AppColors.textMuted,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide.none,
                            ),
                            showCheckmark: false,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                if (selectedDate == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Por favor selecciona una fecha de vencimiento'),
                                      backgroundColor: AppColors.accentOrange,
                                    ),
                                  );
                                  return;
                                }

                                setModalState(() {
                                  isSaving = true;
                                });

                                // Calcular dias restantes
                                final daysLeft = selectedDate!.difference(DateTime.now()).inDays + 1;

                                final newReminder = Reminder(
                                  id: 'rem-${DateTime.now().millisecondsSinceEpoch}',
                                  title: titleController.text.trim(),
                                  date: '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}',
                                  daysLeft: daysLeft < 0 ? 0 : daysLeft,
                                  urgency: selectedUrgency,
                                  status: 'pending',
                                );

                                try {
                                  await db.addReminder(newReminder);
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    setState(() {});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Recordatorio creado exitosamente'),
                                        backgroundColor: AppColors.statusSuccessText,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error al guardar recordatorio: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } finally {
                                  setModalState(() {
                                    isSaving = false;
                                  });
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryNavy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Guardar recordatorio',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReminderCard(Reminder reminder, DbService db) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isImportant = reminder.urgency == 'Importante';
    final Color urgencyColor = isImportant ? AppColors.statusImportantText : AppColors.statusNormalText;
    final Color urgencyBg = isImportant 
        ? (isDark ? AppColors.statusImportantText.withOpacity(0.15) : AppColors.statusImportantBg)
        : (isDark ? AppColors.statusNormalText.withOpacity(0.15) : AppColors.statusNormalBg);
    final Color iconColor = isImportant ? AppColors.statusImportantText : Colors.teal;
    final Color iconBg = isImportant 
        ? (isDark ? AppColors.statusImportantText.withOpacity(0.15) : AppColors.statusImportantBg)
        : (isDark ? Colors.teal.withOpacity(0.15) : Colors.teal.shade50);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x06061C3F),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                )
              ],
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            db.toggleReminderStatus(reminder.id);
          });
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.calendar_month,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Vence en ${reminder.daysLeft} días',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isImportant ? AppColors.statusImportantText : (isDark ? Colors.white70 : AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reminder.date,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: urgencyBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                reminder.urgency,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: urgencyColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    title: Text('¿Eliminar recordatorio?', style: TextStyle(color: isDark ? Colors.white : AppColors.textDark)),
                    content: Text('Esta acción no se puede deshacer.', style: TextStyle(color: isDark ? Colors.white70 : AppColors.textMuted)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await db.deleteReminder(reminder.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Recordatorio eliminado correctamente'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
