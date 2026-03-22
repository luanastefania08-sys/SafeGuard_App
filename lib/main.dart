import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/vishing_detector_screen.dart';
import 'screens/oficiales_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/security_service.dart';
import 'services/bcra_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── FLAG_SECURE: bloquea capturas de pantalla y grabación remota ──
  await SecurityService.enableScreenSecurity();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0D1526),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // ── Inicializar BCRA sync service ─────────────────────────
  await BcraService().initialize();

  // ── Solicitar ignorar optimización de batería (primera vez) ──
  await _requestBatteryOptimizationIfNeeded();

  final prefs = await SharedPreferences.getInstance();
  final termsAccepted = prefs.getBool('terms_accepted') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => BcraService()),
      ],
      child: AntiEstafaApp(showOnboarding: !termsAccepted),
    ),
  );
}

// ── Verificar y solicitar permiso de batería ──────────────────
Future<void> _requestBatteryOptimizationIfNeeded() async {
  try {
    const batteryChannel = MethodChannel('com.safeguard.mobile/battery');
    final bool isIgnoring =
        await batteryChannel.invokeMethod('isIgnoringBatteryOptimizations') ?? false;

    if (!isIgnoring) {
      // Solicitar directamente — abre el diálogo del sistema
      await batteryChannel.invokeMethod('requestIgnoreBatteryOptimizations');
    }
  } catch (_) {
    // No disponible en este dispositivo o versión de Android
  }
}

class AntiEstafaApp extends StatelessWidget {
  final bool showOnboarding;

  const AntiEstafaApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (ctx, themeProvider, _) {
        return MaterialApp(
          title: 'Anti-Estafa',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.isClassicMode
              ? AppTheme.classicTheme
              : AppTheme.darkTheme,
          home: showOnboarding
              ? const OnboardingScreen()
              : const MainNavigationShell(),
        );
      },
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  static const List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.shield_outlined,
      selectedIcon: Icons.shield_rounded,
      label: 'Escudo',
    ),
    _NavItem(
      icon: Icons.radar_outlined,
      selectedIcon: Icons.radar_rounded,
      label: 'Escanear',
    ),
    _NavItem(
      icon: Icons.verified_user_outlined,
      selectedIcon: Icons.verified_user_rounded,
      label: 'Oficiales',
    ),
    _NavItem(
      icon: Icons.info_outline_rounded,
      selectedIcon: Icons.info_rounded,
      label: 'Información',
    ),
  ];

  static const List<Widget> _screens = [
    DashboardScreen(),
    VishingDetectorScreen(),
    OficialesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isNeon = Theme.of(context).brightness == Brightness.dark;
    final navBg = isNeon ? AppColors.surface : ClassicColors.surface;
    final selectedColor = isNeon ? AppColors.neonCyan : ClassicColors.mintGreen;
    final unselectedColor = isNeon ? AppColors.textMuted : ClassicColors.textMuted;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBg,
          border: Border(
            top: BorderSide(
              color: isNeon
                  ? AppColors.borderSubtle
                  : ClassicColors.shadowDark.withOpacity(0.3),
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navItems.length, (index) {
                final item = _navItems[index];
                final selected = _currentIndex == index;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _currentIndex = index);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: selected
                                ? selectedColor.withOpacity(0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            selected ? item.selectedIcon : item.icon,
                            color: selected ? selectedColor : unselectedColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: selected ? selectedColor : unselectedColor,
                            fontSize: 11,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
