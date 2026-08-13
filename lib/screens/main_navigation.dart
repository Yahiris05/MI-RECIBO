import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/db_service.dart';
import 'dashboard_screen.dart';
import 'documents_screen.dart';
import 'reminders_screen.dart';
import 'profile_screen.dart';
import 'scanner_screen.dart';
import 'add_document_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  bool _isLoading = true;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const DocumentsScreen(),
    const RemindersScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await DbService.instance.fetchAll();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al sincronizar datos: $e'),
            backgroundColor: AppColors.accentOrange,
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

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(
            color: AppColors.accentOrange,
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      
      // Boton flotante naranja centrado
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDocumentMenu(context),
        backgroundColor: AppColors.accentOrange,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      
      // BottomAppBar con espacio recortado para el FAB
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 12,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Lado izquierdo: Inicio y Documentos
            _buildNavItem(0, Icons.home_filled, 'Inicio'),
            _buildNavItem(1, Icons.description_outlined, 'Documentos'),
            
            // Espacio vacío para que el FAB no tape los iconos
            const SizedBox(width: 48),
            
            // Lado derecho: Recordatorios y Perfil
            _buildNavItem(2, Icons.calendar_today_outlined, 'Recordatorios'),
            _buildNavItem(3, Icons.person_outline, 'Perfil'),
          ],
        ),
      ),
    );
  }

  void _showAddDocumentMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Agregar documento',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildMenuOption(
                      context,
                      icon: Icons.camera_alt_outlined,
                      label: 'Tomar foto',
                      onTap: () async {
                        Navigator.pop(context);
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(builder: (context) => const ScannerScreen()),
                        );
                        if (result == true && mounted) {
                          setState(() {});
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMenuOption(
                      context,
                      icon: Icons.file_upload_outlined,
                      label: 'Subir archivo',
                      onTap: () async {
                        Navigator.pop(context);
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(builder: (context) => const AddDocumentScreen()),
                        );
                        if (result == true && mounted) {
                          setState(() {});
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuOption(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : AppColors.bgInput,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : AppColors.bgInput, width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: isDark ? AppColors.accentOrange : AppColors.primaryNavy, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : AppColors.primaryNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _currentIndex == index;
    final color = isSelected 
        ? (isDark ? AppColors.accentOrange : AppColors.primaryNavy) 
        : AppColors.textMuted;
    
    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
