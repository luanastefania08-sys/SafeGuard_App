import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'user_profile_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _accepted = false;
  bool _scrolledToBottom = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 50) {
        if (!_scrolledToBottom) setState(() => _scrolledToBottom = true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _aceptarYContinuar() async {
    if (!_accepted) return;
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('terms_accepted', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const UserProfileScreen(isOnboarding: true)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNeon = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isNeon ? AppColors.background : ClassicColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isNeon),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTermsContent(isNeon),
                  ],
                ),
              ),
            ),
            _buildFooter(isNeon),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isNeon) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: isNeon ? AppColors.surface : ClassicColors.surface,
        border: Border(
          bottom: BorderSide(
            color: isNeon ? AppColors.borderSubtle : ClassicColors.shadowDark.withOpacity(0.3),
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isNeon ? AppColors.neonCyanGlow : ClassicColors.mintGreenGlow,
              shape: BoxShape.circle,
              border: Border.all(
                color: isNeon ? AppColors.neonCyan : ClassicColors.mintGreen,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.shield_rounded,
              color: isNeon ? AppColors.neonCyan : ClassicColors.mintGreen,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'ANTI-ESTAFA',
            style: TextStyle(
              color: isNeon ? AppColors.neonCyan : ClassicColors.mintGreen,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Términos de Uso y Descargo de Responsabilidad',
            style: TextStyle(
              color: isNeon ? AppColors.textSecondary : ClassicColors.textSecondary,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTermsContent(bool isNeon) {
    final textColor = isNeon ? AppColors.textPrimary : ClassicColors.textPrimary;
    final secColor = isNeon ? AppColors.textSecondary : ClassicColors.textSecondary;
    final cardColor = isNeon ? AppColors.surfaceCard : ClassicColors.surfaceCard;
    final borderColor = isNeon ? AppColors.borderSubtle : ClassicColors.shadowDark.withOpacity(0.3);
    final accentColor = isNeon ? AppColors.neonCyan : ClassicColors.mintGreen;
    final alertColor = isNeon ? AppColors.alertRed : ClassicColors.alertRed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        _TermsSection(
          title: '1. Propósito de la Aplicación',
          content:
              'Anti-Estafa es una herramienta de asistencia y orientación diseñada para ayudar a identificar posibles intentos de fraude telefónico (Vishing). La aplicación proporciona alertas informativas basadas en patrones conocidos de estafa.',
          textColor: textColor,
          secColor: secColor,
          cardColor: cardColor,
          borderColor: borderColor,
          accentColor: accentColor,
        ),
        _TermsSection(
          title: '2. Descargo de Responsabilidad',
          content:
              'Anti-Estafa es una herramienta de asistencia. El desarrollador NO se responsabiliza por pérdidas económicas, daños directos o indirectos derivados de transferencias voluntarias realizadas por el usuario, decisiones tomadas basándose en las alertas de la aplicación, ni por el uso indebido de la misma.',
          textColor: textColor,
          secColor: secColor,
          cardColor: cardColor,
          borderColor: borderColor,
          accentColor: alertColor,
          isAlert: true,
        ),
        _TermsSection(
          title: '3. Limitaciones del Sistema',
          content:
              'La aplicación no garantiza la detección del 100% de las estafas. Los algoritmos de detección pueden generar falsos positivos o negativos. Siempre consulte con su banco directamente ante cualquier duda. No comparta contraseñas ni datos personales por ningún medio.',
          textColor: textColor,
          secColor: secColor,
          cardColor: cardColor,
          borderColor: borderColor,
          accentColor: accentColor,
        ),
        _TermsSection(
          title: '4. Permisos Requeridos',
          content:
              'La aplicación solicita acceso a: estado del teléfono (detectar llamadas activas), lista de aplicaciones instaladas (detectar apps de riesgo), contactos (identificar llamantes conocidos) y notificaciones (enviar alertas de seguridad). Ningún dato es compartido con terceros.',
          textColor: textColor,
          secColor: secColor,
          cardColor: cardColor,
          borderColor: borderColor,
          accentColor: accentColor,
        ),
        _TermsSection(
          title: '5. Privacidad y Datos',
          content:
              'Toda la información procesada permanece en su dispositivo. Anti-Estafa no recopila ni envía datos personales a servidores externos. La base de datos de patrones de fraude se actualiza localmente.',
          textColor: textColor,
          secColor: secColor,
          cardColor: cardColor,
          borderColor: borderColor,
          accentColor: accentColor,
        ),
        _TermsSection(
          title: '6. Contacto de Emergencia',
          content:
              'Ante una estafa confirmada, comuníquese con:\n• CONDUSEF: 800 999 8080\n• Policía Federal / Emergencias: 911\n• BANXICO: 800 226 9426\n\nNunca comparta información financiera con desconocidos.',
          textColor: textColor,
          secColor: secColor,
          cardColor: cardColor,
          borderColor: borderColor,
          accentColor: accentColor,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: alertColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: alertColor.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: alertColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Lea todo el documento antes de aceptar. Desplace hacia abajo para habilitar el botón de aceptación.',
                  style: TextStyle(color: alertColor, fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildFooter(bool isNeon) {
    final accentColor = isNeon ? AppColors.neonCyan : ClassicColors.mintGreen;
    final bgColor = isNeon ? AppColors.surface : ClassicColors.surface;
    final borderColor = isNeon ? AppColors.borderSubtle : ClassicColors.shadowDark.withOpacity(0.3);
    final textColor = isNeon ? AppColors.textPrimary : ClassicColors.textPrimary;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _scrolledToBottom
                ? () => setState(() => _accepted = !_accepted)
                : null,
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _accepted ? accentColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _accepted ? accentColor : (isNeon ? AppColors.textMuted : ClassicColors.textMuted),
                      width: 2,
                    ),
                  ),
                  child: _accepted
                      ? const Icon(Icons.check_rounded, color: Colors.black, size: 16)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'He leído y acepto los Términos de Uso y el Descargo de Responsabilidad',
                    style: TextStyle(
                      color: _scrolledToBottom ? textColor : (isNeon ? AppColors.textMuted : ClassicColors.textMuted),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _accepted ? _aceptarYContinuar : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _accepted ? accentColor : (isNeon ? AppColors.surfaceElevated : ClassicColors.shadowDark),
                foregroundColor: _accepted ? Colors.black : (isNeon ? AppColors.textMuted : ClassicColors.textMuted),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
              child: Text(_accepted ? 'COMENZAR — ESTOY PROTEGIDO/A' : 'LEE LOS TÉRMINOS COMPLETOS'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  final String title;
  final String content;
  final Color textColor, secColor, cardColor, borderColor, accentColor;
  final bool isAlert;

  const _TermsSection({
    required this.title,
    required this.content,
    required this.textColor,
    required this.secColor,
    required this.cardColor,
    required this.borderColor,
    required this.accentColor,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isAlert ? accentColor.withOpacity(0.06) : cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isAlert ? accentColor.withOpacity(0.4) : borderColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: accentColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: TextStyle(color: secColor, fontSize: 13, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
