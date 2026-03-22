import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../services/security_service.dart';
import 'user_profile_screen.dart';
import 'whatsapp_seguro_screen.dart';
import 'security_audit_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _bloqueoPantalla = true;
  bool _notificacionesAlerta = true;
  bool _analisisLlamadas = true;
  bool _advertenciasDetalladas = true;
  bool _modoEscudoMayor = false;
  String _familyName = '';
  String _familyPhone = '';

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
  }

  Future<void> _cargarConfiguracion() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _bloqueoPantalla = prefs.getBool('screen_security') ?? true;
        _notificacionesAlerta = prefs.getBool('alert_notifications') ?? true;
        _analisisLlamadas = prefs.getBool('call_analysis') ?? true;
        _advertenciasDetalladas = prefs.getBool('detailed_warnings') ?? true;
        _modoEscudoMayor = prefs.getBool('modo_escudo_mayor') ?? false;
        _familyName = prefs.getString('family_name') ?? '';
        _familyPhone = prefs.getString('family_phone') ?? '';
      });
    }
  }

  Future<void> _guardar(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final isNeon = Theme.of(context).brightness == Brightness.dark;
    final bg = isNeon ? AppColors.background : ClassicColors.background;
    final accent = isNeon ? AppColors.neonCyan : ClassicColors.mintGreen;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isNeon ? AppColors.surface : ClassicColors.surface,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_rounded, color: accent, size: 20),
            const SizedBox(width: 8),
            Text(
              'INFORMACIÓN',
              style: TextStyle(
                color: accent,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Apariencia / Tema ─────────────────────────────
          _buildSectionHeader('APARIENCIA', isNeon),
          _buildThemeSwitcher(isNeon, accent),

          // ── Perfil de Usuario ─────────────────────────────
          _buildSectionHeader('PERFIL DE USUARIO', isNeon),
          _buildProfileCard(isNeon, accent),

          // ── Seguridad ─────────────────────────────────────
          _buildSectionHeader('SEGURIDAD DE PANTALLA', isNeon),
          _buildSwitch(
            isNeon: isNeon,
            icon: Icons.screenshot_monitor_rounded,
            iconColor: AppColors.alertRed,
            title: 'Bloqueo de Pantalla',
            subtitle: 'Impide capturas de pantalla y grabaciones remotas (FLAG_SECURE)',
            value: _bloqueoPantalla,
            onChanged: (v) async {
              setState(() => _bloqueoPantalla = v);
              await _guardar('screen_security', v);
              if (v) {
                await SecurityService.enableScreenSecurity();
              } else {
                await SecurityService.disableScreenSecurity();
              }
            },
          ),

          // ── Detección ─────────────────────────────────────
          _buildSectionHeader('DETECCIÓN Y ALERTAS', isNeon),
          _buildSwitch(
            isNeon: isNeon,
            icon: Icons.radar_rounded,
            iconColor: isNeon ? AppColors.neonCyan : ClassicColors.mintGreen,
            title: 'Análisis de Llamadas',
            subtitle: 'Monitorea llamadas activas para detectar patrones de vishing',
            value: _analisisLlamadas,
            onChanged: (v) async {
              setState(() => _analisisLlamadas = v);
              await _guardar('call_analysis', v);
            },
          ),
          _buildSwitch(
            isNeon: isNeon,
            icon: Icons.notifications_active_rounded,
            iconColor: isNeon ? AppColors.warningAmber : ClassicColors.warningAmber,
            title: 'Notificaciones de Alerta',
            subtitle: 'Muestra alertas en tiempo real al detectar riesgos',
            value: _notificacionesAlerta,
            onChanged: (v) async {
              setState(() => _notificacionesAlerta = v);
              await _guardar('alert_notifications', v);
            },
          ),
          _buildSwitch(
            isNeon: isNeon,
            icon: Icons.info_outline_rounded,
            iconColor: isNeon ? AppColors.neonCyanDim : ClassicColors.mintGreenLight,
            title: 'Advertencias Detalladas',
            subtitle: 'Muestra explicaciones completas con cada alerta',
            value: _advertenciasDetalladas,
            onChanged: (v) async {
              setState(() => _advertenciasDetalladas = v);
              await _guardar('detailed_warnings', v);
            },
          ),

          // ── Modo Escudo Mayor ─────────────────────────────
          if (_modoEscudoMayor) ...[
            _buildSectionHeader('MODO ESCUDO MAYOR', isNeon),
            _buildEscudoMayorCard(isNeon),
          ],

          // ── Lista Negra de Apps ───────────────────────────
          _buildSectionHeader('LISTA NEGRA DE APLICACIONES', isNeon),
          _buildBlacklistCard(isNeon),

          // ── Emergencias ───────────────────────────────────
          _buildSectionHeader('CONTACTOS DE EMERGENCIA', isNeon),
          _buildEmergencyContacts(isNeon),

          // ── Herramientas de Seguridad ──────────────────────
          _buildSectionHeader('HERRAMIENTAS DE SEGURIDAD', isNeon),
          _buildNavCard(
            isNeon: isNeon,
            icon: '💬',
            title: 'Misión WhatsApp Seguro',
            subtitle: 'Guía paso a paso para activar la Verificación en Dos Pasos',
            color: const Color(0xFF25D366),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WhatsappSeguroScreen()),
            ),
          ),
          _buildNavCard(
            isNeon: isNeon,
            icon: '🛡',
            title: 'Auditoría de Seguridad',
            subtitle: 'Analizar root, SIM Swap, apps remotas y más',
            color: isNeon ? AppColors.neonCyan : ClassicColors.mintGreen,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SecurityAuditScreen()),
            ),
          ),

          // ── Acerca de ─────────────────────────────────────
          _buildSectionHeader('ACERCA DE', isNeon),
          _buildAboutCard(isNeon, accent),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─── Theme Switcher ───────────────────────────────────────
  Widget _buildThemeSwitcher(bool isNeon, Color accent) {
    return Consumer<ThemeProvider>(
      builder: (ctx, themeProvider, _) {
        final cardColor = isNeon ? AppColors.surfaceCard : ClassicColors.surfaceCard;
        final borderColor = isNeon ? AppColors.borderSubtle : ClassicColors.shadowDark.withOpacity(0.3);
        final textPrimary = isNeon ? AppColors.textPrimary : ClassicColors.textPrimary;
        final textSecondary = isNeon ? AppColors.textSecondary : ClassicColors.textSecondary;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
              boxShadow: isNeon ? null : [
                BoxShadow(color: ClassicColors.shadowLight, offset: const Offset(-3, -3), blurRadius: 6),
                BoxShadow(color: ClassicColors.shadowDark.withOpacity(0.5), offset: const Offset(3, 3), blurRadius: 6),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modo de Visualización',
                  style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  'Seleccione el tema de la aplicación',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildThemeOption(
                        isSelected: themeProvider.isNeonMode,
                        label: 'Modo Neón',
                        subtitle: 'Oscuro & Futurista',
                        icon: Icons.dark_mode_rounded,
                        color: AppColors.neonCyan,
                        bgColor: const Color(0xFF0A0E1A),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          themeProvider.setTheme(AppThemeMode.neon);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildThemeOption(
                        isSelected: themeProvider.isClassicMode,
                        label: 'Escudo Clásico',
                        subtitle: 'Suave & Accesible',
                        icon: Icons.light_mode_rounded,
                        color: ClassicColors.mintGreen,
                        bgColor: ClassicColors.background,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          themeProvider.setTheme(AppThemeMode.classic);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOption({
    required bool isSelected,
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : bgColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: color.withOpacity(0.7), fontSize: 10),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Icon(Icons.check_circle_rounded, color: color, size: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(bool isNeon, Color accent) {
    final cardColor = isNeon ? AppColors.surfaceCard : ClassicColors.surfaceCard;
    final borderColor = isNeon ? AppColors.borderSubtle : ClassicColors.shadowDark.withOpacity(0.3);
    final textPrimary = isNeon ? AppColors.textPrimary : ClassicColors.textPrimary;
    final textSecondary = isNeon ? AppColors.textSecondary : ClassicColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UserProfileScreen()),
          );
          _cargarConfiguracion();
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent.withOpacity(0.5)),
                ),
                child: Icon(Icons.person_rounded, color: accent, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _familyName.isNotEmpty ? 'Familiar: $_familyName' : 'Configurar Familiar de Confianza',
                      style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    Text(
                      _familyPhone.isNotEmpty ? 'Tel: $_familyPhone' : 'Toque para configurar su perfil',
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: textSecondary, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEscudoMayorCard(bool isNeon) {
    final accent = isNeon ? AppColors.warningAmber : ClassicColors.warningAmber;
    final cardColor = isNeon ? AppColors.surfaceCard : ClassicColors.surfaceCard;
    final borderColor = accent.withOpacity(0.4);
    final textSecondary = isNeon ? AppColors.textSecondary : ClassicColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.elderly_rounded, color: accent, size: 22),
                const SizedBox(width: 8),
                Text(
                  'MODO ESCUDO MAYOR — ACTIVO',
                  style: TextStyle(color: accent, fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _familyName.isNotEmpty
                  ? 'Familiar asignado: $_familyName (${_familyPhone})\nDurante la alerta de 60s aparecerá el botón "LLAMAR A $_familyName" con prioridad máxima.'
                  : 'Configure un familiar de confianza para activar el botón de llamada de emergencia.',
              style: TextStyle(color: textSecondary, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlacklistCard(bool isNeon) {
    final apps = [
      {'name': 'AnyDesk', 'pkg': 'com.anydesk.anydeskandroid'},
      {'name': 'TeamViewer', 'pkg': 'com.teamviewer.teamviewer'},
      {'name': 'RustDesk', 'pkg': 'com.rustdesk.rustdesk'},
      {'name': 'VNC Viewer', 'pkg': 'com.realvnc.viewer.android'},
    ];
    final cardColor = isNeon ? AppColors.surfaceCard : ClassicColors.surfaceCard;
    final borderColor = isNeon ? AppColors.borderSubtle : ClassicColors.shadowDark.withOpacity(0.3);
    final textSecondary = isNeon ? AppColors.textSecondary : ClassicColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: apps.map((app) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.block_rounded, color: AppColors.alertRed, size: 16),
                    const SizedBox(width: 8),
                    Text(app['name']!, style: const TextStyle(color: AppColors.alertRed, fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(app['pkg']!, style: TextStyle(color: textSecondary, fontSize: 11), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              )).toList(),
        ),
      ),
    );
  }

  Widget _buildEmergencyContacts(bool isNeon) {
    final contacts = [
      {'name': 'CONDUSEF', 'phone': '800 999 8080', 'color': 0xFFFFAB00},
      {'name': 'Policía Federal', 'phone': '911', 'color': 0xFFFF1744},
      {'name': 'BANXICO', 'phone': '800 226 9426', 'color': 0xFF00E5FF},
    ];
    final cardColor = isNeon ? AppColors.surfaceCard : ClassicColors.surfaceCard;
    final borderColor = isNeon ? AppColors.borderSubtle : ClassicColors.shadowDark.withOpacity(0.3);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: contacts.map((c) {
            final color = Color(c['color'] as int);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.phone_rounded, color: color, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(c['name']! as String, style: TextStyle(color: isNeon ? AppColors.textPrimary : ClassicColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Clipboard.setData(ClipboardData(text: c['phone']! as String));
                    },
                    child: Text(c['phone']! as String, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAboutCard(bool isNeon, Color accent) {
    final cardColor = isNeon ? AppColors.surfaceCard : ClassicColors.surfaceCard;
    final borderColor = isNeon ? AppColors.borderSubtle : ClassicColors.shadowDark.withOpacity(0.3);
    final textSecondary = isNeon ? AppColors.textSecondary : ClassicColors.textSecondary;
    final textPrimary = isNeon ? AppColors.textPrimary : ClassicColors.textPrimary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(Icons.shield_rounded, color: accent, size: 40),
          const SizedBox(height: 8),
          Text(
            'ANTI-ESTAFA',
            style: TextStyle(color: accent, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2),
          ),
          const SizedBox(height: 4),
          Text('Versión 1.0.0', style: TextStyle(color: textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Text(
            'Herramienta de protección contra Vishing y estafas telefónicas. Desarrollada para adultos mayores.',
            textAlign: TextAlign.center,
            style: TextStyle(color: textPrimary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Anti-Estafa es una herramienta de asistencia. El desarrollador no se responsabiliza por pérdidas derivadas de transferencias voluntarias del usuario.',
            textAlign: TextAlign.center,
            style: TextStyle(color: textSecondary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ─── Navigation card ─────────────────────────────────────
  Widget _buildNavCard({
    required bool isNeon,
    required String icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final cardColor = isNeon ? AppColors.surfaceCard : ClassicColors.surfaceCard;
    final borderColor = isNeon ? AppColors.borderSubtle : ClassicColors.shadowDark.withOpacity(0.3);
    final textPrimary = isNeon ? AppColors.textPrimary : ClassicColors.textPrimary;
    final textSecondary = isNeon ? AppColors.textSecondary : ClassicColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.5)),
                ),
                child: Center(child: Text(icon, style: const TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(color: textSecondary, fontSize: 12, height: 1.3)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────
  Widget _buildSectionHeader(String title, bool isNeon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Text(
        title,
        style: TextStyle(
          color: isNeon ? AppColors.textSecondary : ClassicColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitch({
    required bool isNeon,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final cardColor = isNeon ? AppColors.surfaceCard : ClassicColors.surfaceCard;
    final borderColor = isNeon ? AppColors.borderSubtle : ClassicColors.shadowDark.withOpacity(0.3);
    final textPrimary = isNeon ? AppColors.textPrimary : ClassicColors.textPrimary;
    final textSecondary = isNeon ? AppColors.textSecondary : ClassicColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: textSecondary, fontSize: 11, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: isNeon ? AppColors.neonCyan : ClassicColors.mintGreen,
            ),
          ],
        ),
      ),
    );
  }
}
