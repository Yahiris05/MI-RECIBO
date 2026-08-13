import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import '../widgets/waves_painter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isSignUp = false;

  @override
  void initState() {
    super.initState();
    final box = Hive.box('userBox');
    _rememberMe = box.get('rememberMe', defaultValue: true);
    final savedEmail = box.get('email', defaultValue: '');
    _emailController = TextEditingController(text: _rememberMe ? savedEmail : '');
    
    if (_emailController.text.isEmpty) {
      _emailController.text = 'empresa@ejemplo.com';
    }
    _passwordController.text = 'contrasena123';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void saveUserData(String email, String name) {
    var box = Hive.box('userBox');
    box.put('email', email);
    box.put('name', name);
    box.put('rememberMe', _rememberMe);
    box.put('isLoggedIn', true);
  }

  void _toggleAuthMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final supabase = Supabase.instance.client;

    try {
      if (_isSignUp) {
        final name = _nameController.text.trim();
        final AuthResponse response = await supabase.auth.signUp(
          email: email,
          password: password,
          data: {
            'name': name,
          },
        );
        
        if (response.user == null) {
          throw Exception('No se pudo registrar el usuario.');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Registro exitoso! Iniciando sesión...'),
              backgroundColor: AppColors.statusSuccessText,
            ),
          );
        }

        saveUserData(email, name);
      } else {
        final AuthResponse response = await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (response.user == null) {
          throw Exception('Usuario no encontrado.');
        }

        // Intentar obtener el nombre desde la tabla de perfiles en Supabase o metadatos
        String fetchedName = 'Mi Empresa S.R.L.';
        try {
          final profileData = await supabase
              .from('profiles')
              .select('name')
              .eq('id', response.user!.id)
              .single();
          fetchedName = profileData['name'] ?? fetchedName;
        } catch (_) {
          fetchedName = response.user!.userMetadata?['name'] ?? fetchedName;
        }

        saveUserData(email, fetchedName);
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Ondas de fondo al pie de pagina
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: WavesBackgroundWidget(height: 180),
          ),

          // 2. Contenido principal
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  
                  // Logo, Titulo y Subtitulo alineados en el centro conforme al mockup
                  Center(
                    child: Column(
                      children: [
                        // Logo (Documento con doblez naranja)
                        Container(
                          width: 64,
                          height: 64,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x10061C3F),
                                blurRadius: 12,
                                offset: Offset(0, 6),
                              )
                            ],
                          ),
                          child: Stack(
                            children: [
                              const Icon(
                                Icons.description_outlined,
                                color: AppColors.primaryNavy,
                                size: 44,
                              ),
                              Positioned(
                                right: 1,
                                bottom: 1,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: AppColors.accentOrange,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(3),
                                      bottomRight: Radius.circular(3),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Mi recibo',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isSignUp ? 'Crea una cuenta para tu empresa' : 'Bienvenido de nuevo',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 36),

                  // Formulario de login / registro
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isSignUp) ...[
                          const Text(
                            'Nombre de la empresa',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: 'Mi Empresa S.R.L.',
                              prefixIcon: const Icon(Icons.business, color: AppColors.textMuted, size: 20),
                              filled: true,
                              fillColor: AppColors.bgInput,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Por favor ingresa el nombre de la empresa';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        const Text(
                          'Correo empresarial',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'empresa@ejemplo.com',
                            prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textMuted, size: 20),
                            filled: true,
                            fillColor: AppColors.bgInput,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor ingresa tu correo';
                            }
                            final trimmed = value.trim();
                            final emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,6}$');
                            if (!emailRegex.hasMatch(trimmed)) {
                              return 'Por favor ingresa un formato de correo válido (ej: nombre@empresa.com)';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        const Text(
                          'Contraseña',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: AppColors.textMuted,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: AppColors.bgInput,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa tu contraseña';
                            }
                            if (_isSignUp && value.length < 6) {
                              return 'La contraseña debe tener al menos 6 caracteres';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 12),
                        
                        if (!_isSignUp)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      activeColor: AppColors.primaryNavy,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _rememberMe = value ?? true;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Recordarme',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  '¿Olvidaste tu contraseña?',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        
                        const SizedBox(height: 28),
                        
                        // Boton de envio
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleAuth,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryNavy,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    _isSignUp ? 'Registrarse' : 'Iniciar sesión',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Enlace para alternar Login y Registro
                        Center(
                          child: GestureDetector(
                            onTap: _toggleAuthMode,
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                                children: [
                                  TextSpan(text: _isSignUp ? '¿Ya tienes cuenta? ' : '¿Aún no tienes cuenta? '),
                                  TextSpan(
                                    text: _isSignUp ? 'Inicia sesión' : 'Regístrate',
                                    style: const TextStyle(
                                      color: AppColors.accentOrange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
