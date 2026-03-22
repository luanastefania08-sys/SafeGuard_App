import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

// ============================================================
// MISIÓN WHATSAPP SEGURO
// Guía paso a paso para activar la Verificación en Dos Pasos
// Diseñada especialmente para adultos mayores (65+)
// ============================================================

class WhatsappSeguroScreen extends StatefulWidget {
  const WhatsappSeguroScreen({super.key});

  @override
  State<WhatsappSeguroScreen> createState() => _WhatsappSeguroScreenState();
}

class _WhatsappSeguroScreenState extends State<WhatsappSeguroScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  final PageController _pageController = PageController();
  late AnimationController _checkController;
  late Animation<double> _checkAnim;

  static const List<_WaStep> _steps = [
    _WaStep(
      icon: '🛡',
      title: '¿Por qué necesito esto?',
      subtitle: 'Entendé el riesgo en 30 segundos',
      color: Color(0xFF00E5FF),
      body: _StepBody.intro,
    ),
    _WaStep(
      icon: '⚙️',
      title: 'Paso 1',
      subtitle: 'Abrir Configuración de WhatsApp',
      color: Color(0xFF25D366),
      body: _StepBody.step1,
    ),
    _WaStep(
      icon: '👤',
      title: 'Paso 2',
      subtitle: 'Ir a "Cuenta"',
      color: Color(0xFF25D366),
      body: _StepBody.step2,
    ),
    _WaStep(
      icon: '🔐',
      title: 'Paso 3',
      subtitle: 'Activar Verificación en Dos Pasos',
      color: Color(0xFF25D366),
      body: _StepBody.step3,
    ),
    _WaStep(
      icon: '🔢',
      title: 'Paso 4',
      subtitle: 'Crear tu PIN de 6 dígitos',
      color: Color(0xFFFFAB00),
      body: _StepBody.step4,
    ),
    _WaStep(
      icon: '✉️',
      title: 'Paso 5',
      subtitle: 'Agregar correo de recuperación',
      color: Color(0xFFFFAB00),
      body: _StepBody.step5,
    ),
    _WaStep(
      icon: '🏆',
      title: '¡Misión Cumplida!',
      subtitle: 'Tu WhatsApp ahora está protegido',
      color: Color(0xFF00E676),
      body: _StepBody.done,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _checkAnim = CurvedAnimation(parent: _checkController, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  void _nextStep() {
    HapticFeedback.mediumImpact();
    if (_currentStep < _steps.length - 1) {
      _currentStep++;
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      if (_currentStep == _steps.length - 1) {
        _checkController.forward();
      }
      setState(() {});
    }
  }

  void _prevStep() {
    HapticFeedback.selectionClick();
    if (_currentStep > 0) {
      _currentStep--;
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNeon = Theme.of(context).brightness == Brightness.dark;
    final bg = isNeon ? AppColors.background : ClassicColors.background;
    final accent = _steps[_currentStep].color;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isNeon ? AppColors.surface : ClassicColors.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: isNeon ? AppColors.neonCyan : ClassicColors.mintGreen),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💬', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              'MISIÓN WHATSAPP SEGURO',
              style: TextStyle(
                color: const Color(0xFF25D366),
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildProgressBar(isNeon, accent),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _steps.length,
              itemBuilder: (_, i) => _buildStepPage(_steps[i], isNeon, i),
            ),
          ),
          _buildNavButtons(isNeon, accent),
        ],
      ),
    );
  }

  Widget _buildProgressBar(bool isNeon, Color accent) {
    final total = _steps.length;
    final progress = (_currentStep + 1) / total;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          Row(
            children: [
              Text(
                'Paso ${_currentStep + 1} de $total',
                style: TextStyle(
                  color: accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}% completado',
                style: TextStyle(
                  color: isNeon ? AppColors.textSecondary : ClassicColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: isNeon ? AppColors.borderSubtle : ClassicColors.shadowDark.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepPage(_WaStep step, bool isNeon, int index) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Ícono grande
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: step.color.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: step.color, width: 2),
            ),
            child: Center(
              child: Text(step.icon, style: const TextStyle(fontSize: 42)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            step.title,
            style: TextStyle(
              color: step.color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            step.subtitle,
            style: TextStyle(
              color: isNeon ? AppColors.textPrimary : ClassicColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          _buildStepContent(step.body, isNeon, step.color),
        ],
      ),
    );
  }

  Widget _buildStepContent(_StepBody body, bool isNeon, Color accent) {
    switch (body) {
      case _StepBody.intro:
        return _buildIntro(isNeon, accent);
      case _StepBody.step1:
        return _buildStep1(isNeon, accent);
      case _StepBody.step2:
        return _buildStep2(isNeon, accent);
      case _StepBody.step3:
        return _buildStep3(isNeon, accent);
      case _StepBody.step4:
        return _buildStep4(isNeon, accent);
      case _StepBody.step5:
        return _buildStep5(isNeon, accent);
      case _StepBody.done:
        return _buildDone(isNeon, accent);
    }
  }

  // ── Pantalla de Intro ──────────────────────────────────────
  Widget _buildIntro(bool isNeon, Color accent) {
    return Column(
      children: [
        _card(
          isNeon,
          color: AppColors.alertRed,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _rowIcon('🔴', '¿Qué puede pasar sin protección?', AppColors.alertRed, isNeon),
              const SizedBox(height: 12),
              _bulletPoint('Un estafador puede clonar tu WhatsApp si roba tu código de verificación por SMS.', isNeon),
              _bulletPoint('Con tu WhatsApp, pueden escribir a tus familiares pidiéndoles dinero "de emergencia".', isNeon),
              _bulletPoint('La Verificación en Dos Pasos es un PIN secreto que SOLO vos conocés.', isNeon),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _card(
          isNeon,
          color: const Color(0xFF25D366),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _rowIcon('🟢', '¿Qué hace la Verificación en Dos Pasos?', const Color(0xFF25D366), isNeon),
              const SizedBox(height: 12),
              _bulletPoint('Si alguien intenta instalar tu WhatsApp en otro teléfono, necesita tu PIN.', isNeon),
              _bulletPoint('Sin el PIN, NO pueden acceder a tus mensajes aunque tengan tu número.', isNeon),
              _bulletPoint('Es gratis, fácil de activar y tarda menos de 3 minutos.', isNeon),
            ],
          ),
        ),
      ],
    );
  }

  // ── Paso 1: Abrir configuración ────────────────────────────
  Widget _buildStep1(bool isNeon, Color accent) {
    return Column(
      children: [
        _visualStep(
          number: 1,
          isNeon: isNeon,
          accent: accent,
          instruction: 'Abrí la aplicación de WhatsApp en tu teléfono.',
          visual: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF075E54),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('💬', style: TextStyle(fontSize: 40)),
                const SizedBox(width: 12),
                const Text('WhatsApp', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _visualStep(
          number: 2,
          isNeon: isNeon,
          accent: accent,
          instruction: 'Tocá los tres puntitos (⋮) en la esquina superior derecha.',
          visual: _phoneUiMock(
            isNeon: isNeon,
            content: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('WhatsApp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('⋮', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('← Tocá aquí', style: TextStyle(color: Colors.yellowAccent, fontSize: 13)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _visualStep(
          number: 3,
          isNeon: isNeon,
          accent: accent,
          instruction: 'En el menú que se abre, seleccioná "Configuración".',
          visual: _menuMock(
            isNeon: isNeon,
            items: ['Nuevo grupo', 'Nueva difusión', '⚙️ Configuración ←', 'Cerrar sesión'],
            highlighted: 2,
          ),
        ),
      ],
    );
  }

  // ── Paso 2: Ir a Cuenta ────────────────────────────────────
  Widget _buildStep2(bool isNeon, Color accent) {
    return Column(
      children: [
        _visualStep(
          number: 1,
          isNeon: isNeon,
          accent: accent,
          instruction: 'Dentro de Configuración, buscá y tocá "Cuenta".',
          visual: _menuMock(
            isNeon: isNeon,
            items: ['🔔 Notificaciones', '💬 Chats', '👤 Cuenta ←', '💾 Almacenamiento'],
            highlighted: 2,
          ),
        ),
        const SizedBox(height: 14),
        _infoBox(
          isNeon: isNeon,
          icon: '💡',
          text: 'La sección "Cuenta" es donde están todas las configuraciones de seguridad de tu WhatsApp.',
          color: accent,
        ),
      ],
    );
  }

  // ── Paso 3: Activar verificación ───────────────────────────
  Widget _buildStep3(bool isNeon, Color accent) {
    return Column(
      children: [
        _visualStep(
          number: 1,
          isNeon: isNeon,
          accent: accent,
          instruction: 'Dentro de Cuenta, tocá "Verificación en dos pasos".',
          visual: _menuMock(
            isNeon: isNeon,
            items: ['📧 Correo electrónico', '🔐 Verificación en dos pasos ←', '🗑 Eliminar cuenta'],
            highlighted: 1,
          ),
        ),
        const SizedBox(height: 14),
        _visualStep(
          number: 2,
          isNeon: isNeon,
          accent: accent,
          instruction: 'Tocá el botón verde "Activar" que aparece en pantalla.',
          visual: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isNeon ? AppColors.surfaceCard : ClassicColors.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isNeon ? AppColors.borderSubtle : ClassicColors.shadowDark.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Text('🔐', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 8),
                Text(
                  'Verificación en dos pasos desactivada',
                  style: TextStyle(
                    color: isNeon ? AppColors.textPrimary : ClassicColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Text('ACTIVAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Paso 4: Crear PIN ──────────────────────────────────────
  Widget _buildStep4(bool isNeon, Color accent) {
    return Column(
      children: [
        _card(
          isNeon,
          color: accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _rowIcon('🔢', '¿Cómo elegir un buen PIN de 6 dígitos?', accent, isNeon),
              const SizedBox(height: 12),
              _pinRule('❌', 'NO uses tu fecha de nacimiento (ej: 150358)', isNeon, bad: true),
              _pinRule('❌', 'NO uses el número de tu teléfono ni el DNI', isNeon, bad: true),
              _pinRule('❌', 'NO uses "123456" ni números repetidos', isNeon, bad: true),
              const SizedBox(height: 8),
              _pinRule('✅', 'SÍ usá una frase que recuerdes: la inicial de cada palabra', isNeon, bad: false),
              _pinRule('✅', 'Ejemplo: "Mi hijo Juan nació en año 1985" → 045219', isNeon, bad: false),
              _pinRule('✅', 'Anotalo en un papel guardado en un lugar seguro de tu casa', isNeon, bad: false),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _card(
          isNeon,
          color: isNeon ? AppColors.neonCyan : ClassicColors.mintGreen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _rowIcon('⚠️', 'MUY IMPORTANTE', isNeon ? AppColors.warningAmber : ClassicColors.warningAmber, isNeon),
              const SizedBox(height: 8),
              Text(
                'WhatsApp te pedirá confirmar el PIN dos veces. Anotalo ANTES de ingresarlo. Si lo olvidás, deberás esperar 7 días para restablecerlo.',
                style: TextStyle(
                  color: isNeon ? AppColors.textSecondary : ClassicColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Paso 5: Correo de recuperación ────────────────────────
  Widget _buildStep5(bool isNeon, Color accent) {
    return Column(
      children: [
        _visualStep(
          number: 1,
          isNeon: isNeon,
          accent: accent,
          instruction: 'WhatsApp te pedirá un correo electrónico de recuperación. Es opcional pero MUY recomendable.',
          visual: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isNeon ? AppColors.surfaceCard : ClassicColors.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isNeon ? AppColors.borderSubtle : ClassicColors.shadowDark.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Text('✉️', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
                Text(
                  'Agregar correo electrónico',
                  style: TextStyle(color: isNeon ? AppColors.textPrimary : ClassicColors.textPrimary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isNeon ? AppColors.surfaceElevated : ClassicColors.shadowDark.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF25D366)),
                  ),
                  child: Text(
                    'ejemplo@gmail.com',
                    style: TextStyle(color: isNeon ? AppColors.textMuted : ClassicColors.textMuted, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _card(
          isNeon,
          color: const Color(0xFF25D366),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _rowIcon('💡', 'Consejos para el correo', const Color(0xFF25D366), isNeon),
              const SizedBox(height: 12),
              _bulletPoint('Usá el correo que revisa con más frecuencia (Gmail, Hotmail).', isNeon),
              _bulletPoint('Si alguien de tu familia te ayuda con el correo, usá ese correo.', isNeon),
              _bulletPoint('Este correo se usará para recuperar el PIN si lo olvidás.', isNeon),
            ],
          ),
        ),
      ],
    );
  }

  // ── Pantalla final ─────────────────────────────────────────
  Widget _buildDone(bool isNeon, Color accent) {
    return Column(
      children: [
        ScaleTransition(
          scale: _checkAnim,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: accent, width: 3),
            ),
            child: const Center(child: Text('✅', style: TextStyle(fontSize: 50))),
          ),
        ),
        const SizedBox(height: 20),
        _card(
          isNeon,
          color: accent,
          child: Column(
            children: [
              Text(
                '¡Tu WhatsApp ahora tiene doble candado!',
                style: TextStyle(
                  color: accent,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              _bulletPoint('Si alguien intenta entrar a tu WhatsApp, necesitará tu PIN de 6 dígitos.', isNeon),
              _bulletPoint('Incluso si roban tu SIM card, no podrán acceder sin el PIN.', isNeon),
              _bulletPoint('Recordá: NUNCA compartas este PIN con nadie, ni con WhatsApp.', isNeon),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _card(
          isNeon,
          color: isNeon ? AppColors.warningAmber : ClassicColors.warningAmber,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _rowIcon('📋', 'Resumen de lo que hiciste', isNeon ? AppColors.warningAmber : ClassicColors.warningAmber, isNeon),
              const SizedBox(height: 12),
              _checkItem('Activaste la Verificación en Dos Pasos', isNeon),
              _checkItem('Creaste un PIN de 6 dígitos seguro', isNeon),
              _checkItem('Agregaste un correo de recuperación', isNeon),
              _checkItem('Tu WhatsApp está ahora protegido', isNeon),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _infoBox(
          isNeon: isNeon,
          icon: '🔁',
          text: 'WhatsApp te pedirá tu PIN de vez en cuando para que no lo olvides. Es normal.',
          color: isNeon ? AppColors.neonCyan : ClassicColors.mintGreen,
        ),
      ],
    );
  }

  // ─── Botones de navegación ────────────────────────────────
  Widget _buildNavButtons(bool isNeon, Color accent) {
    final isLast = _currentStep == _steps.length - 1;
    final isFirst = _currentStep == 0;
    final navBg = isNeon ? AppColors.surface : ClassicColors.surface;
    final borderColor = isNeon ? AppColors.borderSubtle : ClassicColors.shadowDark.withOpacity(0.3);
    final textColor = isNeon ? AppColors.textPrimary : ClassicColors.textPrimary;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: navBg,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          if (!isFirst)
            Expanded(
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  foregroundColor: isNeon ? AppColors.textSecondary : ClassicColors.textSecondary,
                  side: BorderSide(color: borderColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('← Anterior'),
              ),
            ),
          if (!isFirst) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: isLast ? () => Navigator.pop(context) : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: isLast ? Colors.black : (isNeon ? Colors.black : Colors.white),
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              child: Text(isLast ? '¡Listo! Volver al inicio' : 'Siguiente →'),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Widgets helpers ──────────────────────────────────────
  Widget _card(bool isNeon, {required Color color, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: child,
    );
  }

  Widget _rowIcon(String emoji, String text, Color color, bool isNeon) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _bulletPoint(String text, bool isNeon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•', style: TextStyle(color: isNeon ? AppColors.textSecondary : ClassicColors.textSecondary, fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isNeon ? AppColors.textSecondary : ClassicColors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pinRule(String emoji, String text, bool isNeon, {required bool bad}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: bad ? AppColors.alertRed : (isNeon ? AppColors.safeGreen : ClassicColors.safeGreen),
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkItem(String text, bool isNeon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Text('✅', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isNeon ? AppColors.textPrimary : ClassicColors.textPrimary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox({required bool isNeon, required String icon, required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isNeon ? AppColors.textSecondary : ClassicColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _visualStep({
    required int number,
    required bool isNeon,
    required Color accent,
    required String instruction,
    required Widget visual,
  }) {
    final textColor = isNeon ? AppColors.textPrimary : ClassicColors.textPrimary;
    final cardColor = isNeon ? AppColors.surfaceCard : ClassicColors.surfaceCard;
    final borderColor = isNeon ? AppColors.borderSubtle : ClassicColors.shadowDark.withOpacity(0.3);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent),
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  instruction,
                  style: TextStyle(color: textColor, fontSize: 15, height: 1.4, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          visual,
        ],
      ),
    );
  }

  Widget _phoneUiMock({required bool isNeon, required Widget content}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF075E54),
        borderRadius: BorderRadius.circular(12),
      ),
      child: content,
    );
  }

  Widget _menuMock({required bool isNeon, required List<String> items, required int highlighted}) {
    return Container(
      decoration: BoxDecoration(
        color: isNeon ? AppColors.surfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8)],
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final isHighlighted = e.key == highlighted;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isHighlighted ? const Color(0xFF25D366).withOpacity(0.12) : Colors.transparent,
              border: Border(
                bottom: e.key < items.length - 1
                    ? BorderSide(
                        color: isNeon ? AppColors.borderSubtle : Colors.grey.withOpacity(0.3),
                      )
                    : BorderSide.none,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    e.value,
                    style: TextStyle(
                      color: isHighlighted
                          ? const Color(0xFF25D366)
                          : (isNeon ? AppColors.textPrimary : const Color(0xFF1A2340)),
                      fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w400,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (isHighlighted)
                  const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF25D366), size: 14),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Modelos ──────────────────────────────────────────────
enum _StepBody { intro, step1, step2, step3, step4, step5, done }

class _WaStep {
  final String icon;
  final String title;
  final String subtitle;
  final Color color;
  final _StepBody body;

  const _WaStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.body,
  });
}
