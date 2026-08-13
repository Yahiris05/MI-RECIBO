import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/document.dart';
import '../services/api_service.dart';
import 'add_document_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _isProcessing = false;

  Future<void> _capturePhoto() async {
    setState(() {
      _isProcessing = true;
    });

    // Simular procesamiento del escaneo y llamar al ApiService para obtener datos
    try {
      final apiService = ApiService('https://jsonplaceholder.typicode.com');
      final response = await apiService.fetchData();
      final title = response['title'] ?? 'Compra Local';

      // Generar documento pre-llenado en base a la API
      final doc = Document(
        id: 'doc-${DateTime.now().millisecondsSinceEpoch}',
        supplier: 'Office Depot',
        type: 'Factura',
        date: '2024-05-07',
        category: 'Útiles de oficina',
        amount: 4920.00,
        notes: 'Ticket extraído vía API REST: "$title"',
        format: 'PDF',
      );

      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });

      // Navegar a la pantalla de Agregar documento con los datos obtenidos
      final success = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => AddDocumentScreen(initialDocument: doc),
        ),
      );

      if (success == true && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      // Fallback
      final doc = Document(
        id: 'doc-${DateTime.now().millisecondsSinceEpoch}',
        supplier: 'Office Depot',
        type: 'Factura',
        date: '2024-05-07',
        category: 'Útiles de oficina',
        amount: 4920.00,
        notes: 'Compra de útiles de oficina (Modo local)',
        format: 'PDF',
      );
      
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });

      final success = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => AddDocumentScreen(initialDocument: doc),
        ),
      );

      if (success == true && mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Visor de Cámara con Bounding Box y Recibo simulado
          SafeArea(
            child: Column(
              children: [
                // App bar de la camara
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Escanear documento',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.flash_on, color: Colors.white, size: 20),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 10),
                const Text(
                  'Alinea el documento en el\nrecuadro para escanear',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Recuadro semitransparente que enmarca el ticket de Office Depot
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white.withOpacity(0.04),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Center(
                          child: Container(
                            width: 210,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Text(
                                    'OFFICE DEPOT',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                Center(
                                  child: Text(
                                    '--- FACTURA ---',
                                    style: TextStyle(color: Colors.black54, fontSize: 8),
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text('Fecha: 05/05/2024      10:30 a.m.', style: TextStyle(color: Colors.black, fontSize: 7)),
                                Text('Factura No:        000123456', style: TextStyle(color: Colors.black, fontSize: 7)),
                                Text('RNC: 1-01-12345-6', style: TextStyle(color: Colors.black, fontSize: 7)),
                                Divider(height: 10, color: Colors.black26, thickness: 0.5),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Descripción', style: TextStyle(color: Colors.black, fontSize: 7, fontWeight: FontWeight.bold)),
                                    Text('Total', style: TextStyle(color: Colors.black, fontSize: 7, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Resma de papel x1', style: TextStyle(color: Colors.black, fontSize: 7)),
                                    Text('\$250.00', style: TextStyle(color: Colors.black, fontSize: 7)),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Toner HP 05A x1', style: TextStyle(color: Colors.black, fontSize: 7)),
                                    Text('\$4,500.00', style: TextStyle(color: Colors.black, fontSize: 7)),
                                  ],
                                ),
                                Divider(height: 10, color: Colors.black26, thickness: 0.5),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Total', style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold)),
                                    Text('\$4,920.00', style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Center(
                                  child: Text(
                                    'Gracias por su compra!',
                                    style: TextStyle(color: Colors.black54, fontSize: 7, fontStyle: FontStyle.italic),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Controles inferiores exactos al mockup
                Container(
                  padding: const EdgeInsets.only(bottom: 24, top: 12),
                  child: Column(
                    children: [
                      // Galeria, Disparador y Cerrar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.image_outlined, color: Colors.white, size: 28),
                            onPressed: () {},
                          ),
                          
                          // Disparador circular blanco
                          GestureDetector(
                            onTap: _isProcessing ? null : _capturePhoto,
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 28),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Pestañas inferiores (Galería, Foto, Archivo)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Galería', style: TextStyle(color: Colors.white54, fontSize: 13)),
                          const SizedBox(width: 32),
                          const Text(
                            'Foto',
                            style: TextStyle(
                              color: AppColors.accentOrange,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 32),
                          const Text('Archivo', style: TextStyle(color: Colors.white54, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Loader al procesar OCR de la API
          if (_isProcessing)
            Container(
              color: Colors.black87,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.accentOrange),
                    SizedBox(height: 16),
                    Text(
                      'Extrayendo datos de la factura...',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
