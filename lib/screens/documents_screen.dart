import 'package:flutter/material.dart';
import 'dart:convert';
import '../theme.dart';
import '../services/db_service.dart';
import '../models/document.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  String _searchQuery = '';
  String _activeFilter = 'Todos';

  // Filtros identicos al mockup collage: Todos, Facturas, Recibos, Comprobantes
  final List<String> _filters = ['Todos', 'Facturas', 'Recibos', 'Comprobantes'];

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
    
    // Filtrar documentos
    final filteredDocs = db.documents.where((doc) {
      final matchesSearch = doc.supplier.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          doc.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          doc.notes.toLowerCase().contains(_searchQuery.toLowerCase());
      
      // Mapeo de filtro plural a singular de la base de datos
      bool matchesFilter = _activeFilter == 'Todos';
      if (_activeFilter == 'Facturas' && doc.type == 'Factura') matchesFilter = true;
      if (_activeFilter == 'Recibos' && doc.type == 'Recibo') matchesFilter = true;
      if (_activeFilter == 'Comprobantes' && doc.type == 'Comprobante') matchesFilter = true;
      
      return matchesSearch && matchesFilter;
    }).toList();

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
          'Mis documentos',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_alt_outlined, color: isDark ? Colors.white : AppColors.primaryNavy),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Caja de búsqueda y etiquetas de filtro
          Container(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            padding: const EdgeInsets.only(top: 8, bottom: 16, left: 20, right: 20),
            child: Column(
              children: [
                // Campo de busqueda
                TextField(
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar documento',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                    filled: true,
                    fillColor: AppColors.bgInput,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),
                
                // Filtros horizontales
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final isActive = _activeFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: ChoiceChip(
                          label: Text(
                            filter,
                            style: TextStyle(
                              color: isActive ? Colors.white : AppColors.textMuted,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
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
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Listado de documentos con scroll
          Expanded(
            child: filteredDocs.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'No se encontraron comprobantes',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      return _buildDocumentCard(doc);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(Document doc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => _showDocumentDetailsDialog(context, doc),
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
            // Icono carpeta roja o miniatura de imagen a la izquierda
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: doc.imageUrl != null ? Colors.transparent : (isDark ? Colors.red.withOpacity(0.1) : const Color(0xFFFFF2F2)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: doc.imageUrl != null && doc.imageUrl!.startsWith('data:image/')
                    ? Image.memory(
                        base64Decode(doc.imageUrl!.split(',').last),
                        fit: BoxFit.cover,
                      )
                    : const Center(
                        child: Icon(
                          Icons.folder,
                          color: Colors.red,
                          size: 22,
                        ),
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
                color: doc.imageUrl != null 
                    ? (isDark ? Colors.teal.withOpacity(0.15) : Colors.teal.shade50) 
                    : (isDark ? Colors.red.withOpacity(0.15) : const Color(0xFFFFE5E5)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                doc.imageUrl != null ? 'IMG' : doc.format,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: doc.imageUrl != null ? Colors.teal : Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDocumentDetailsDialog(BuildContext context, Document doc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        doc.type,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.primaryNavy,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textMuted),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Divider(color: isDark ? Colors.white12 : AppColors.bgInput),
                  const SizedBox(height: 12),
                  _buildDetailRow(context, 'Proveedor', doc.supplier),
                  _buildDetailRow(context, 'Fecha', doc.date),
                  _buildDetailRow(context, 'Monto', 'RD\$ ${doc.amount.toStringAsFixed(2)}'),
                  _buildDetailRow(context, 'Categoría', doc.category),
                  _buildDetailRow(context, 'Notas', doc.notes.isEmpty ? 'Ninguna' : doc.notes),
                  if (doc.imageUrl != null && doc.imageUrl!.startsWith('data:image/')) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Imagen de la factura:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : AppColors.textDark),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 250),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.white10 : AppColors.bgInput),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          base64Decode(doc.imageUrl!.split(',').last),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            title: Text('¿Eliminar documento?', style: TextStyle(color: isDark ? Colors.white : AppColors.textDark)),
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
                          await DbService.instance.deleteDocument(doc.id);
                          if (context.mounted) {
                            Navigator.pop(context); // Cierra la modal de detalles
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Documento eliminado correctamente'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                      label: const Text('Eliminar Documento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13, 
                color: isDark ? Colors.white70 : AppColors.textDark, 
                fontWeight: FontWeight.w600
              ),
            ),
          ),
        ],
      ),
    );
  }
}
