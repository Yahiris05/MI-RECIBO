import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../theme.dart';
import '../models/document.dart';
import '../services/db_service.dart';

class AddDocumentScreen extends StatefulWidget {
  final Document? initialDocument;
  const AddDocumentScreen({super.key, this.initialDocument});

  @override
  State<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends State<AddDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supplierController = TextEditingController();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _notesController = TextEditingController();
  final _dateController = TextEditingController();
  String _selectedType = 'Factura';
  
  bool _isSaving = false;
  String? _imageBase64;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    if (widget.initialDocument != null) {
      final doc = widget.initialDocument!;
      _supplierController.text = doc.supplier;
      _amountController.text = doc.amount.toStringAsFixed(2);
      _categoryController.text = doc.category;
      _notesController.text = doc.notes;
      _dateController.text = doc.date;
      _selectedType = doc.type;
      if (doc.imageUrl != null && doc.imageUrl!.startsWith('data:image/')) {
        _imageBase64 = doc.imageUrl;
        try {
          final base64Part = doc.imageUrl!.split(',').last;
          _imageBytes = base64Decode(base64Part);
        } catch (_) {}
      }
    } else {
      _dateController.text = '05/05/2024';
    }
  }

  @override
  void dispose() {
    _supplierController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        final base64Str = base64Encode(bytes);
        
        setState(() {
          _imageBytes = bytes;
          _imageBase64 = 'data:image/png;base64,$base64Str';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final newDoc = Document(
      id: widget.initialDocument?.id ?? 'doc-${DateTime.now().millisecondsSinceEpoch}',
      supplier: _supplierController.text.trim(),
      type: _selectedType,
      date: _dateController.text.trim(),
      category: _categoryController.text.trim(),
      amount: double.tryParse(_amountController.text) ?? 4920.00,
      notes: _notesController.text.trim(),
      format: _imageBytes != null ? 'IMG' : (widget.initialDocument?.format ?? 'PDF'),
      imageUrl: _imageBase64,
    );

    try {
      await DbService.instance.addDocument(newDoc);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documento guardado exitosamente'),
            backgroundColor: AppColors.statusSuccessText,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar documento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgApp,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Agregar documento',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Botones de "Tomar foto" y "Subir archivo" lado a lado conforme al mockup
              Row(
                children: [
                  Expanded(
                    child: _buildActionSelector(
                      Icons.camera_alt_outlined,
                      'Tomar foto',
                      onTap: _isSaving ? null : () => _pickImage(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionSelector(
                      Icons.file_upload_outlined,
                      'Subir archivo',
                      onTap: _isSaving ? null : () => _pickImage(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
              if (_imageBytes != null) ...[
                const SizedBox(height: 16),
                Center(
                  child: Stack(
                    children: [
                      Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.bgInput, width: 1.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(
                            _imageBytes!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          radius: 18,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                            onPressed: _isSaving ? null : () {
                              setState(() {
                                _imageBytes = null;
                                _imageBase64 = null;
                              });
                            },
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              
              // Subtítulo de sección
              const Text(
                'Información del documento',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              
              // 2. Formulario de Datos
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x04061C3F),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Proveedor
                    const Text('Proveedor', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _supplierController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.bgInput,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa el proveedor' : null,
                    ),
                    const SizedBox(height: 14),

                    // Tipo de documento dropdown
                    const Text('Tipo de documento', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.bgInput,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: ['Factura', 'Comprobante', 'Recibo'].map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedType = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Fecha del documento con icono calendario a la derecha
                    const Text('Fecha del documento', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _dateController,
                      decoration: InputDecoration(
                        suffixIcon: const Icon(Icons.calendar_today_outlined, color: AppColors.textMuted, size: 18),
                        filled: true,
                        fillColor: AppColors.bgInput,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Monto (Monto total del comprobante)
                    const Text('Monto Total (RD\$)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.bgInput,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa el monto' : null,
                    ),
                    const SizedBox(height: 14),

                    // Categoría con chevron-right
                    const Text('Categoría', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _categoryController,
                      decoration: InputDecoration(
                        suffixIcon: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.bgInput,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Notas opcionales
                    const Text('Notas (opcional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Compra de suministros...',
                        filled: true,
                        fillColor: AppColors.bgInput,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveDocument,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 1,
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Guardar documento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionSelector(IconData icon, String label, {required VoidCallback? onTap}) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1.0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.bgInput, width: 1.5),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primaryNavy, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
