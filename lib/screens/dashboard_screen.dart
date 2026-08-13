import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import '../theme.dart';
import '../services/db_service.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _exchangeRate = 59.20;
  bool _isLoadingRate = true;

  @override
  void initState() {
    super.initState();
    _loadExchangeRate();
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

  Future<void> _loadExchangeRate() async {
    final apiService = ApiService('');
    final rate = await apiService.fetchDopExchangeRate();
    if (mounted) {
      setState(() {
        _exchangeRate = rate;
        _isLoadingRate = false;
      });
    }
  }

  String getUserName() {
    var box = Hive.box('userBox');
    return box.get('name', defaultValue: 'Empresa');
  }

  @override
  Widget build(BuildContext context) {
    final String name = getUserName();
    final db = DbService.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Encabezado Azul Marino exacto al Mockup
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 50, bottom: 28, left: 24, right: 24),
              decoration: const BoxDecoration(
                color: AppColors.primaryNavy,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila superior con menú hamburguesa y campana de notificacion con badge 3
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.menu, color: Colors.white, size: 26),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      
                      // Campana con badge "3"
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.notifications_none, color: Colors.white, size: 24),
                          ),
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.accentOrange,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: const Text(
                                '3',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Saludo y subtitulo
                  Text(
                    '¡Hola, $name!',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Aquí tienes un resumen de tu negocio',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                  
                  // Tipo de cambio USD
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.trending_up, color: AppColors.accentOrange, size: 16),
                        const SizedBox(width: 6),
                        const Text(
                          'USD/DOP: ',
                          style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        _isLoadingRate
                            ? const SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
                              )
                            : Text(
                                'RD\$ ${_exchangeRate.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Cuadrícula de Estadísticas 2x2 idéntica al diseño
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.35,
                    children: [
                      _buildStatCard(
                        context,
                        'Documentos\nalmacenados',
                        '${122 + db.documents.length}',
                        Icons.description,
                        Colors.blue.shade600,
                        Colors.blue.shade50,
                      ),
                      _buildStatCard(
                        context,
                        'Recordatorios\npendientes',
                        '${db.pendingRemindersCount}',
                        Icons.notifications,
                        AppColors.accentOrange,
                        AppColors.accentOrangeLight,
                      ),
                      _buildStatCard(
                        context,
                        'Facturas de\neste mes',
                        '${14 + db.documents.where((d) => d.type == 'Factura').length}',
                        Icons.receipt_long,
                        Colors.green.shade600,
                        Colors.green.shade50,
                      ),
                      _buildStatCard(
                        context,
                        'Categorías\nregistradas',
                        '7',
                        Icons.folder,
                        Colors.blue.shade800,
                        Colors.blue.shade50,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // 3. Próximo recordatorio
                  Text(
                    'Próximo recordatorio',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildNextReminderCard(context, db),

                  const SizedBox(height: 28),

                  // 4. Documentos recientes con link "Ver todos"
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Documentos recientes',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textDark,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                        child: const Text(
                          'Ver todos',
                          style: TextStyle(
                            color: AppColors.accentOrange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Listado
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: db.documents.length > 3 ? 3 : db.documents.length,
                    itemBuilder: (context, index) {
                      final doc = db.documents[index];
                      return _buildRecentDocItem(context, doc);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color, Color bg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x06061C3F),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Etiqueta arriba
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white70 : AppColors.textMuted,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
          // Fila inferior con el valor y el icono
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.primaryNavy,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? color.withOpacity(0.15) : bg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextReminderCard(BuildContext context, DbService db) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pending = db.reminders.where((r) => r.status == 'pending').toList();
    if (pending.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No tienes recordatorios pendientes',
            style: TextStyle(color: isDark ? Colors.white70 : AppColors.textMuted, fontSize: 13),
          ),
        ),
      );
    }

    final reminder = pending.first;
    final bool isImportant = reminder.urgency == 'Importante';
    final Color urgencyColor = isImportant ? AppColors.statusImportantText : AppColors.statusNormalText;
    final Color urgencyBg = isImportant 
        ? (isDark ? AppColors.statusImportantText.withOpacity(0.15) : AppColors.statusImportantBg)
        : (isDark ? AppColors.statusNormalText.withOpacity(0.15) : AppColors.statusNormalBg);

    return Container(
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: urgencyBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.calendar_month,
              color: urgencyColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          
          // Informacion del recordatorio
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
                    fontSize: 12,
                    color: urgencyColor,
                    fontWeight: FontWeight.bold,
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
          const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
        ],
      ),
    );
  }

  Widget _buildRecentDocItem(BuildContext context, dynamic doc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isImage = doc.imageUrl != null;
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
      child: Row(
        children: [
          // Icono hoja gris o miniatura de imagen
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isImage ? Colors.transparent : (isDark ? const Color(0xFF0F172A) : AppColors.bgInput),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: isImage && doc.imageUrl!.startsWith('data:image/')
                  ? Image.memory(
                      base64Decode(doc.imageUrl!.split(',').last),
                      fit: BoxFit.cover,
                    )
                  : Icon(
                      Icons.description_outlined,
                      color: isDark ? Colors.white54 : AppColors.textMuted,
                      size: 22,
                    ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Datos del documento
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${doc.type} ${doc.supplier}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  doc.date,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          
          // Badge "PDF" o "IMG"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isImage ? Colors.teal.shade50 : const Color(0xFFFFE5E5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isImage ? 'IMG' : doc.format,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isImage ? Colors.teal : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
