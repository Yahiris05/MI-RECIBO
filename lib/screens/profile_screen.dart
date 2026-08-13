import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import '../services/db_service.dart';
import 'api_demo_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = 'Cargando...';
  String _email = 'Cargando...';
  String _rnc = '1-01-12345-6';
  String _phone = '809-123-4567';
  
  final List<String> _customCategories = [];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final box = Hive.box('userBox');
    final String cachedName = box.get('name', defaultValue: 'Empresa S.R.L.');
    final String cachedEmail = box.get('email', defaultValue: 'empresa@ejemplo.com');

    if (mounted) {
      setState(() {
        _name = cachedName;
        _email = cachedEmail;
      });
    }

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        final profileData = await supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();

        if (mounted) {
          setState(() {
            _name = profileData['name'] ?? cachedName;
            _rnc = profileData['rnc'] ?? '1-01-12345-6';
            _phone = profileData['phone'] ?? '809-123-4567';
          });
        }

        // Sincronizar cache de Hive
        box.put('name', _name);
      }
    } catch (e) {
      print('Error al obtener perfil de Supabase: $e');
    }
  }

  Future<void> _updateProfile(String name, String email, String rnc, String phone) async {
    final box = Hive.box('userBox');
    box.put('name', name);
    box.put('email', email);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase.from('profiles').update({
          'name': name,
          'rnc': rnc,
          'phone': phone,
        }).eq('id', user.id);
      }
      
      if (mounted) {
        setState(() {
          _name = name;
          _email = email;
          _rnc = rnc;
          _phone = phone;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado correctamente'),
            backgroundColor: AppColors.statusSuccessText,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar perfil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSettingsDialog() {
    final nameController = TextEditingController(text: _name);
    final emailController = TextEditingController(text: _email);
    final rncController = TextEditingController(text: _rnc);
    final phoneController = TextEditingController(text: _phone);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        final box = Hive.box('userBox');
        return ValueListenableBuilder(
          valueListenable: box.listenable(),
          builder: (context, box, child) {
            final isDark = box.get('isDarkMode', defaultValue: false);
            return Dialog(
              backgroundColor: Theme.of(context).dialogBackgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
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
                              'Configuración',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 18,
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
                        const Divider(color: AppColors.bgInput),
                        const SizedBox(height: 12),
                        
                        // Switch Modo Oscuro
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Modo Oscuro',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Switch(
                              value: isDark,
                              activeColor: AppColors.accentOrange,
                              onChanged: (val) {
                                box.put('isDarkMode', val);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        const Text('Nombre de la Empresa', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: nameController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.bgInput,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa el nombre' : null,
                        ),
                        const SizedBox(height: 12),

                        const Text('Correo Electrónico', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: emailController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.bgInput,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa el correo' : null,
                        ),
                        const SizedBox(height: 12),

                        const Text('RNC', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: rncController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.bgInput,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        const SizedBox(height: 12),

                        const Text('Teléfono', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: phoneController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.bgInput,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (!formKey.currentState!.validate()) return;
                              _updateProfile(
                                nameController.text.trim(),
                                emailController.text.trim(),
                                rncController.text.trim(),
                                phoneController.text.trim(),
                              );
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryNavy,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Guardar Cambios', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCategoriesDialog() {
    final catController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final uniqueCats = DbService.instance.documents.map((d) => d.category).toSet().toList();
            final allCats = {...uniqueCats, 'Servicios públicos', 'Útiles de oficina', 'Telecomunicaciones', 'Mantenimiento', 'Tecnología', ..._customCategories}.toList();

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Categorías',
                          style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textMuted),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.bgInput),
                    const SizedBox(height: 8),
                    
                    // Lista
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: allCats.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: const Icon(Icons.folder, color: Colors.blue),
                            title: Text(allCats[index], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    Form(
                      key: formKey,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: catController,
                              decoration: InputDecoration(
                                hintText: 'Nueva categoría',
                                filled: true,
                                fillColor: AppColors.bgInput,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa un nombre' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              if (!formKey.currentState!.validate()) return;
                              setState(() {
                                _customCategories.add(catController.text.trim());
                              });
                              setDialogState(() {
                                catController.clear();
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryNavy,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Icon(Icons.add, size: 20),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showBackupDialog() {
    final docs = DbService.instance.documents;
    String csv = 'ID;Proveedor;Tipo;Fecha;Categoria;Monto;Notas\n';
    for (var doc in docs) {
      csv += '${doc.id};${doc.supplier};${doc.type};${doc.date};${doc.category};${doc.amount};${doc.notes}\n';
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Respaldo y Seguridad',
                      style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: AppColors.bgInput),
                const SizedBox(height: 12),
                const Text(
                  'Puedes exportar tu base de datos de documentos almacenados localmente a formato CSV:',
                  style: TextStyle(fontSize: 12, color: AppColors.textDark),
                ),
                const SizedBox(height: 14),
                
                // Previsualización del CSV
                Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.bgInput,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      csv,
                      style: const TextStyle(fontFamily: 'Courier', fontSize: 10, color: Colors.black87),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: csv));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Datos exportados y copiados al portapapeles en formato CSV'),
                          backgroundColor: AppColors.statusSuccessText,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copiar al Portapapeles (CSV)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showHelpSupportDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                      'Ayuda y Soporte',
                      style: TextStyle(
                        fontFamily: 'Outfit', 
                        fontSize: 18, 
                        fontWeight: FontWeight.bold, 
                        color: isDark ? Colors.white : AppColors.primaryNavy
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
                Text(
                  'Preguntas frecuentes:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? AppColors.accentOrange : AppColors.primaryNavy),
                ),
                const SizedBox(height: 8),
                Text(
                  '• ¿Cómo escanear facturas?\n  Ve a la pestaña de inicio, haz clic en el botón central naranja (+), alinea la factura y haz la captura.\n\n• ¿Cómo crear recordatorios?\n  Ve a Recordatorios, haz clic en el botón (+) e introduce los datos del vencimiento.',
                  style: TextStyle(fontSize: 11, height: 1.4, color: isDark ? Colors.white70 : AppColors.textDark),
                ),
                const SizedBox(height: 16),
                Text(
                  'Contacto de soporte:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? AppColors.accentOrange : AppColors.primaryNavy),
                ),
                const SizedBox(height: 6),
                Text(
                  'Correo: soporte@mirecibord.com\nTeléfono: +1 (809) 555-0199',
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : AppColors.textMuted, height: 1.4),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Aceptar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: isDark ? Colors.white : AppColors.primaryNavy, size: 20),
          onPressed: () {},
        ),
        title: const Text(
          'Perfil de la empresa',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 1. Tarjeta superior de la empresa
            Container(
              padding: const EdgeInsets.all(16),
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
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.accentOrange : AppColors.primaryNavy,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.business,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'RNC: $_rnc',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _email,
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _phone,
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // 2. Bloque de opciones de configuración rediseñado
            Container(
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
              child: Column(
                children: [
                  _buildProfileOption(Icons.folder_open_outlined, 'Categorías', _showCategoriesDialog),
                  Divider(height: 1, color: isDark ? Colors.white12 : AppColors.bgInput, indent: 52),
                  _buildProfileOption(Icons.security_outlined, 'Respaldo y seguridad', _showBackupDialog),
                  Divider(height: 1, color: isDark ? Colors.white12 : AppColors.bgInput, indent: 52),
                  _buildProfileOption(Icons.settings_outlined, 'Configuración', _showSettingsDialog),
                  Divider(height: 1, color: isDark ? Colors.white12 : AppColors.bgInput, indent: 52),
                  _buildProfileOption(Icons.help_outline, 'Ayuda y soporte', _showHelpSupportDialog),
                  Divider(height: 1, color: isDark ? Colors.white12 : AppColors.bgInput, indent: 52),
                  _buildProfileOption(Icons.api_outlined, 'Actividad APIs y Navegación', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ApiDemoScreen()),
                    );
                  }),
                  Divider(height: 1, color: isDark ? Colors.white12 : AppColors.bgInput, indent: 52),
                  
                  // Cerrar sesión
                  InkWell(
                    onTap: () async {
                      await Supabase.instance.client.auth.signOut();
                      final box = Hive.box('userBox');
                      box.put('isLoggedIn', false);
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: Colors.red, size: 20),
                          SizedBox(width: 16),
                          Text(
                            'Cerrar sesión',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          Spacer(),
                          Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: isDark ? AppColors.accentOrange : AppColors.primaryNavy, size: 20),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : AppColors.textDark,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
