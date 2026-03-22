import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/security_audit_service.dart';

// ============================================================
// PANTALLA DE AUDITORÍA DE SEGURIDAD
// Muestra el análisis completo del dispositivo con amenazas
// y recomendaciones concretas
// ============================================================

class SecurityAuditScreen extends StatefulWidget {
  const SecurityAuditScreen({super.key});

  @override
  State<SecurityAuditScreen> createState() => _SecurityAuditScreenState();
}

class _SecurityAuditScreenState extends State<SecurityAuditScreen>
    with SingleTickerProviderStateMixin {
  SecurityAuditResult? _result;
  bool _isLoading = false;
  late AnimationController _scoreController;
  late Animation<double> _scoreAnim;

  @override
  void initState() {
    super.initState();
    _scoreController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scoreAnim = CurvedAnimation(parent: _scoreController, curve: Curves.easeOut);
    _runAudit();
  }

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }

  Future<void> _runAudit() async {
    setState(() => _isLoading = true);
    final result = await SecurityAuditService().runFullAudit();
    if (mounted) {
      setState(() {
        _result = result;
        _isLoading = false;
      });
      _scoreController.forward(from: 0);
    }
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: accent),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.security_rounded, color: accent, size: 20),
            const SizedBox(width: 8),
            Text(
              'AUDITORÍA DE SEGURIDAD',
              style: TextStyle(
                color: accent,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: accent),
              onPressed: () {
                _scoreController.reset();
                _runAudit();
              },
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoading(isNeon, accent)
          : _result != null
              ? _buildResults(isNeon, accent)
              : const SizedBox.shrink(),
    );
  }

  Widget _buildLoading(bool isNeon, Color accent) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              color: accent,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Analizando su dispositivo...',
            style: TextStyle(
              color: isNeon ? AppColors.textPrimary : ClassicColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Verificando root, SIM, apps remotas y más',
            style: TextStyle(
              color: isNeon ? AppColors.textSecondary : ClassicColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(bool isNeon, Color accent) {
    final result = _result!;
    final score = result.overallScore;
    final scoreColor = score >= 80
        ? (isNeon ? AppColors.safeGreen : ClassicColors.safeGreen)
        : score >= 50
            ? (isNeon ? AppColors.warningAmber : ClassicColors.warningAmber)
            : AppColors.alertRed;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Score principal ───────────────────────────────
        _buildScoreCard(isNeon, score, scoreColor, result),
        const SizedBox(height: 16),

        // ── Resumen rápido ────────────────────────────────
        _buildQuickSummary(isNeon, result, scoreColor),
        const SizedBox(height: 16),

        // ── Amenazas detectadas ───────────────────────────
        if (result.threats.isNotEmpty) ...[
          _sectionLabel('AMENAZAS DETECTADAS', isNeon),
          ...result.threats.map((t) => _buildThreatCard(t, isNeon)),
          const SizedBox(height: 8),
        ],

        // ── Verificaciones superadas ──────────────────────
        _sectionLabel('VERIFICACIONES SUPERADAS', isNeon),
        if (!result.isRooted)
          _buildPassedCheck('Dispositivo sin ROOT', 'El sistema no ha sido modificado.', isNeon, accent),
        if (!result.simSwapDetected)
          _buildPassedCheck('SIM sin cambios', 'No se detectó intercambio de SIM card.', isNeon, accent),
        if (!result.remoteAccessAppDetected)
          _buildPassedCheck('Sin apps de acceso remoto', 'AnyDesk/TeamViewer/RustDesk no están instaladas.', isNeon, accent),
        if (!result.devModeEnabled)
          _buildPassedCheck('Modo desarrollador desactivado', 'No se permiten instalaciones no verificadas.', isNeon, accent),
        _buildPassedCheck('FLAG_SECURE activo', 'Las capturas de pantalla están bloqueadas.', isNeon, accent),

        const SizedBox(height: 20),

        // ── Próxima auditoría ─────────────────────────────
        _buildNextAuditInfo(isNeon, accent, result),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildScoreCard(bool isNeon, int score, Color scoreColor, SecurityAuditResult result) {
    final cardColor = isNeon ? AppColors.surfaceCard : ClassicColors.surfaceCard;
    final borderColor = isNeon ? AppColors.borderSubtle : ClassicColors.shadowDark.withOpacity(0.3);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scoreColor.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(color: scoreColor.withOpacity(0.12), blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _scoreAnim,
            builder: (_, __) => Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: _scoreAnim.value * score / 100,
                    strokeWidth: 10,
                    backgroundColor: isNeon ? AppColors.borderSubtle : ClassicColors.shadowDark.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '${(score * _scoreAnim.value).round()}',
                      style: TextStyle(
                        color: scoreColor,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      '/ 100',
                      style: TextStyle(
                        color: isNeon ? AppColors.textMuted : ClassicColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                SecurityAuditService.scoreEmoji(score),
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(
                SecurityAuditService.scoreLabel(score),
                style: TextStyle(
                  color: scoreColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result.deviceSecure
                ? 'No se detectaron amenazas. Dispositivo seguro.'
                : 'Se detectaron ${result.threats.length} amenaza${result.threats.length == 1 ? '' : 's'}. Revise las recomendaciones.',
            style: TextStyle(
              color: isNeon ? AppColors.textSecondary : ClassicColors.textSecondary,
              fontSize: 13,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSummary(bool isNeon, SecurityAuditResult result, Color scoreColor) {
    final items = [
      _SummaryItem('Root', !result.isRooted, result.isRooted ? 'DETECTADO' : 'LIMPIO'),
      _SummaryItem('SIM', !result.simSwapDetected, result.simSwapDetected ? '¡ALERTA!' : 'NORMAL'),
      _SummaryItem('Apps remotas', !result.remoteAccessAppDetected, result.remoteAccessAppDetected ? 'ENCONTRADAS' : 'NINGUNA'),
      _SummaryItem('Dev Mode', !result.devModeEnabled, result.devModeEnabled ? 'ACTIVO' : 'SEGURO'),
    ];

    return Row(
      children: items.map((item) {
        final color = item.ok
            ? (isNeon ? AppColors.safeGreen : ClassicColors.safeGreen)
            : AppColors.alertRed;
        final cardColor = isNeon ? AppColors.surfaceCard : ClassicColors.surfaceCard;
        final borderColor = isNeon ? AppColors.borderSubtle : ClassicColors.shadowDark.withOpacity(0.3);

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  Text(item.ok ? '✓' : '✗',
                      style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(item.label,
                      style: TextStyle(
                          color: isNeon ? AppColors.textSecondary : ClassicColors.textSecondary,
                          fontSize: 9,
                          fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 2),
                  Text(item.status,
                      style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildThreatCard(SecurityThreat threat, bool isNeon) {
    Color levelColor;
    String levelLabel;
    switch (threat.level) {
      case SecurityThreatLevel.critical:
        levelColor = AppColors.alertRed;
        levelLabel = '🚨 CRÍTICO';
        break;
      case SecurityThreatLevel.high:
        levelColor = isNeon ? AppColors.warningAmber : ClassicColors.warningAmber;
        levelLabel = '⚠️ ALTO';
        break;
      case SecurityThreatLevel.medium:
        levelColor = isNeon ? AppColors.neonCyan : ClassicColors.mintGreen;
        levelLabel = '⚡ MEDIO';
        break;
      default:
        levelColor = isNeon ? AppColors.safeGreen : ClassicColors.safeGreen;
        levelLabel = 'ℹ️ BAJO';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: levelColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: levelColor.withOpacity(0.4), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: levelColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: levelColor.withOpacity(0.5)),
                  ),
                  child: Text(levelLabel,
                      style: TextStyle(color: levelColor, fontSize: 10, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    threat.title,
                    style: TextStyle(
                      color: isNeon ? AppColors.textPrimary : ClassicColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              threat.description,
              style: TextStyle(
                color: isNeon ? AppColors.textSecondary : ClassicColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: levelColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: levelColor.withOpacity(0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline_rounded, color: levelColor, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      threat.recommendation,
                      style: TextStyle(color: levelColor, fontSize: 12, height: 1.4, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassedCheck(String title, String subtitle, bool isNeon, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isNeon ? AppColors.surfaceCard : ClassicColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isNeon ? AppColors.borderSubtle : ClassicColors.shadowDark.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(Icons.check_rounded, color: accent, size: 18),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: isNeon ? AppColors.textPrimary : ClassicColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  Text(subtitle,
                      style: TextStyle(
                          color: isNeon ? AppColors.textSecondary : ClassicColors.textSecondary,
                          fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextAuditInfo(bool isNeon, Color accent, SecurityAuditResult result) {
    final cardColor = isNeon ? AppColors.surfaceCard : ClassicColors.surfaceCard;
    final borderColor = isNeon ? AppColors.borderSubtle : ClassicColors.shadowDark.withOpacity(0.3);
    final textSecondary = isNeon ? AppColors.textSecondary : ClassicColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, color: accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Auditoría realizada: ${_formatTime(result.auditTime)}\nSe recomienda repetir cada 7 días.',
              style: TextStyle(color: textSecondary, fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, bool isNeon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: TextStyle(
          color: isNeon ? AppColors.textSecondary : ClassicColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final months = [
      '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _SummaryItem {
  final String label;
  final bool ok;
  final String status;
  const _SummaryItem(this.label, this.ok, this.status);
}
