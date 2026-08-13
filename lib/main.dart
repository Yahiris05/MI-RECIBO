import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_config.dart';
import 'theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Supabase antes de arrancar la aplicación
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  
  // Inicializacion obligatoria de Hive conforme al documento PDF
  await Hive.initFlutter();
  await Hive.openBox('userBox');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('userBox');
    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, Box box, child) {
        final bool isLoggedIn = box.get('isLoggedIn', defaultValue: false);
        final bool isDarkMode = box.get('isDarkMode', defaultValue: false);

        return MaterialApp(
          title: 'Mi Recibo RD',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: isLoggedIn ? const MainNavigation() : const LoginScreen(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const MainNavigation(),
          },
        );
      },
    );
  }
}
