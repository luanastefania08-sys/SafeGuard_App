import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class PauseAlertScreen extends StatefulWidget {
  final String? alertReason;
  final VoidCallback? onCallFamily;

  const PauseAlertScreen({
    super.key,
    this.alertReason,
    this.onCallFamily,
  });

  // ── Método estático para mostrar la alerta como ruta completa ──
  static Future<void> show(
    BuildContext context, {
    String? threatDescription,
    String? callerNumber,
    VoidCallback? onCallFamily,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        pageBuilder: (_, __, ___) => PauseAlertScreen(
          alertReason: threatDescription,
          onCallFamily: onCallFamily,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  State<PauseAlertScreen> createState() => _PauseAlertScreenState();
}

class _PauseAlertScreenState extends State<PauseAlertScreen>
    with TickerProviderStateMixin {
  static const int _totalSeconds = 60;
  int _secondsRemaining = _totalSeconds;
  bool _canClose = false;
  bool _alarmMuted = false;

  String _familyName = '';
  String _familyPhone = '';
  bool _hasFamilyContact = false;

  Timer? _countdownTimer;
  Timer? _vibrationTimer;

  late AnimationController _flashController;
  late AnimationController _pulseController;
  late Animation<double> _flashAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _loadFamilyContact();
    _initAnimations();
    _startCountdown();
    _startVibration();
  }

  Future<void> _loadFamilyContact() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('family_name') ?? '';
    final phone = prefs.getString('family_phone') ?? '';
    if (mounted) {
      setState(() {
        _familyName = name;
        _familyPhone = phone;
        _hasFamilyContact = name.isNotEmpty && phone.isNotEmpty;
      });
    }
  }

  void _initAnimations() {
    _flashController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);

    _flashAnim = Tween<double>(begin: 0.0, end: 0.14).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeInOut),
    );

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining <= 1) {
        t.cancel();
        setState(() {
          _secondsRemaining = 0;
          _canClose = true;
        });
        _flashController.stop();
        _vibrationTimer?.cancel();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  void _startVibration() {
    _vibrationTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_alarmMuted) {
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 200), HapticFeedback.heavyImpact);
        Future.delayed(const Duration(milliseconds: 400), HapticFeedback.heavyImpact);
        Future.delayed(const Duration(milliseconds: 700), HapticFeedback.vibrate);
      }
    });
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 200), HapticFeedback.heavyImpact);
    Future.delayed(const Duration(milliseconds: 400), HapticFeedback.heavyImpact);
  }

  Future<void> _llamarFamiliar() async {
    HapticFeedback.heavyImpact();
    // Usar callback si está definido (desde DashboardScreen)
    if (widget.onCallFamily != null) {
      widget.onCallFamily!();
      return;
    }
    // Fallback: usar el canal nativo directo
    if (!_hasFamilyContact) return;
    try {
      const platform = MethodChannel('com.safeguard.mobile/call_monitor');
      await platform.invokeMethod('openDialerWithNumber', {'phoneNumber': _familyPhone});
    } catch (_) {}
  }

  void _silenciarAlarma() {
    setState(() => _alarmMuted = !_alarmMuted);
    if (_alarmMuted) {
      _vibrationTimer?.cancel();
    } else {
      _startVibration();
    }
  }

  void _cerrarAlerta() {
    if (!_canClose) return;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _vibrationTimer?.cancel();
    _flashController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _canClose,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0000),
        body: AnimatedBuilder(
          animation: _flashAnim,
          builder: (ctx, child) {
            return Container(
              decoration: BoxDecoration(
                color: Color.lerp(
                  const Color(0xFF0A0000),
                  const Color(0xFF3A0000),
                  _flashAnim.value,
                ),
                border: Border.all(
                  color: AppColors.alertRed.withOpacity(0.8),
                  width: 3,
                ),
              ),
              child: child,
            );
          },
          child: SafeArea(
            child: Column(
              children: [
                _buildAlarmBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        _buildAlertIcon(),
                        const SizedBox(height: 16),
                        _buildAlertTitle(),
                        const SizedBox(height: 20),
                        _buildAlertBody(),
                        const SizedBox(height: 20),
                        if (_hasFamilyContact || widget.onCallFamily != null)
                          _buildLlamarButton(),
                        const SizedBox(height: 28),
                        _buildCountdown(),
                        const SizedBox(height: 20),
                        _buildCloseButton(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlarmBar() {
    return GestureDetector(
      onTap: _silenciarAlarma,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: _alarmMuted
              ? Colors.grey[900]
              : AppColors.alertRed.withOpacity(0.12),
          border: Border(
            bottom: BorderSide(color: AppColors.alertRed.withOpacity(0.35)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Transform.scale(
                scale: _alarmMuted ? 1.0 : _pulseAnim.value,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _alarmMuted ? Colors.grey : AppColors.alertRed,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              _alarmMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              color: _alarmMuted ? Colors.grey : AppColors.alertRed,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              _alarmMuted
                  ? 'ALARMA SILENCIADA'
                  : 'ALARMA ACTIVA · TOQUE PARA SILENCIAR',
              style: TextStyle(
                color: _alarmMuted ? Colors.grey : AppColors.alertRed,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertIcon() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, __) => Transform.scale(
        scale: _pulseAnim.value,
        child: Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.alertRed.withOpacity(0.1),
            border: Border.all(color: AppColors.alertRed, width: 2.5),
          ),
          child: const Icon(
            Icons.warning_rounded,
            color: AppColors.alertRed,
            size: 48,
          ),
        ),
      ),
    );
  }

  Widget _buildAlertTitle() {
    return Column(
      children: [
        const Text(
          '¡ALERTA!',
          style: TextStyle(
            color: AppColors.alertRed,
            fontSize: 38,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'POSIBLE ESTAFA DETECTADA',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertBody() {
    final reason = widget.alertReason;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.alertRed.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.alertRed.withOpacity(0.55),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          if (reason != null && reason.isNotEmpty) ...[
            Text(
              reason,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.alertRed,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white12),
            const SizedBox(height: 8),
          ] else
            RichText(
              textAlign: TextAlign.center,
              text: const TextSpan(
                style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.6),
                children: [
                  TextSpan(text: 'Se detectó una '),
                  TextSpan(
                    text: 'llamada activa',
                    style: TextStyle(color: AppColors.alertRed, fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: ' en simultáneo con la apertura de su App Bancaria.'),
                ],
              ),
            ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.content_cut_rounded, color: AppColors.alertRed, size: 18),
              SizedBox(width: 8),
              Text(
                'CORTE LA LLAMADA INMEDIATAMENTE',
                style: TextStyle(
                  color: AppColors.alertRed,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Los empleados bancarios reales NUNCA llaman pidiéndole abrir su aplicación.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildLlamarButton() {
    final name = _familyName.isNotEmpty ? _familyName : 'Familiar';

    return GestureDetector(
      onTap: _llamarFamiliar,
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, child) => Transform.scale(
          scale: 0.98 + (0.02 * _pulseAnim.value),
          child: child,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.warningAmber,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.warningAmber.withOpacity(0.35),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.phone_rounded, color: Colors.black, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'LLAMAR A ${name.toUpperCase()}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Toque para contactar a su familiar de confianza',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black87, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountdown() {
    return Column(
      children: [
        Text(
          'TIEMPO RESTANTE',
          style: TextStyle(
            color: _canClose
                ? Colors.white30
                : AppColors.alertRed.withOpacity(0.6),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Transform.scale(
            scale: _canClose ? 1.0 : (0.95 + 0.05 * _pulseAnim.value),
            child: Text(
              _canClose ? '0' : '$_secondsRemaining',
              style: TextStyle(
                color: _canClose ? Colors.white30 : AppColors.alertRed,
                fontSize: 80,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
        Text(
          'SEGUNDOS',
          style: TextStyle(
            color: _canClose ? Colors.white30 : Colors.white54,
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildCloseButton() {
    return GestureDetector(
      onTap: _cerrarAlerta,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          color: _canClose
              ? AppColors.alertRed.withOpacity(0.12)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _canClose ? AppColors.alertRed.withOpacity(0.5) : Colors.white12,
          ),
        ),
        child: Text(
          'ENTIENDO — CERRAR ALERTA',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _canClose ? Colors.white : Colors.white24,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
