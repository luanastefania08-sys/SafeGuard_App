import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/call_record.dart';
import '../widgets/neon_card.dart';
import '../widgets/threat_badge.dart';
import '../widgets/pause_alert_screen.dart';
import '../services/vishing_detector_service.dart';
import '../services/nfc_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  bool _protectionActive = true;
  bool _isSeniorUser = false;
  String? _familyContact;
  TriangulationResult? _lastTriangulation;
  StreamSubscription<TriangulationResult>? _monitorSub;
  bool _shieldMajorActive = false;

  final List<CallRecord> _recentCalls = [
    CallRecord(
      id: '1',
      phoneNumber: '+52 55 4567-8901',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      duration: const Duration(seconds: 45),
      callType: CallType.incoming,
      threatLevel: CallThreatLevel.dangerous,
      threatIndicators: [
        'Fraude Bancario: "cuenta bloqueada" detectado',
        'Urgencia artificial: "inmediatamente"',
        'Solicitud de datos: "pin" detectado',
      ],
      wasBlocked: true,
      analysisNote:
          'Posible fraude bancario. Se solicitaron datos confidenciales.',
    ),
    CallRecord(
      id: '2',
      phoneNumber: '+52 55 1234-5678',
      contactName: 'María López',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      duration: const Duration(minutes: 5, seconds: 20),
      callType: CallType.incoming,
      threatLevel: CallThreatLevel.safe,
    ),
    CallRecord(
      id: '3',
      phoneNumber: '+1 800-555-0199',
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      duration: const Duration(minutes: 2),
      callType: CallType.incoming,
      threatLevel: CallThreatLevel.suspicious,
      threatIndicators: ['Premio o Lotería Falsa: "ganaste" detectado'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserProfile();
    _startMonitoring();
    // Iniciar protección NFC después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) NfcProtectionService.startMonitoring(context);
    });
  }

  Future<void> _loadUserProfile() async {
    final isSenior = await VishingDetectorService.isSeniorUser();
    final familyContact =
        await VishingDetectorService.getEmergencyFamilyContact();
    if (mounted) {
      setState(() {
        _isSeniorUser = isSenior;
        _familyContact = familyContact;
      });
    }
  }

  void _startMonitoring() {
    if (!_protectionActive) return;
    _monitorSub?.cancel();
    _monitorSub =
        VishingDetectorService.startContinuousMonitoring().listen((result) {
      if (!mounted) return;
      setState(() => _lastTriangulation = result);

      // Disparar alerta automática si es alto riesgo
      if (result.isHighRisk && _protectionActive) {
        _triggerHighRiskAlert(result);
      }
    });
  }

  void _stopMonitoring() {
    _monitorSub?.cancel();
    _monitorSub = null;
    VishingDetectorService.stopContinuousMonitoring();
  }

  void _triggerHighRiskAlert(TriangulationResult result) {
    PauseAlertScreen.show(
      context,
      threatDescription: result.riskDescription,
      callerNumber: result.activeCallNumber,
      onCallFamily: (_isSeniorUser && _familyContact != null)
          ? () => _callFamilyMember()
          : null,
    );
  }

  // ============================================================
  // MODO ESCUDO MAYOR — abre el marcador con el familiar guardado
  // Se activa cuando: usuario ≥ 65 años + riesgo alto detectado
  // ============================================================
  void _activateShieldMajor() async {
    final contact = _familyContact ??
        await VishingDetectorService.getEmergencyFamilyContact();

    if (contact == null || contact.isEmpty) {
      _showConfigureFamilyContact();
      return;
    }

    setState(() => _shieldMajorActive = true);
    HapticFeedback.heavyImpact();

    final encodedPhone = Uri.encodeComponent(contact);
    final uri = Uri.parse('tel:$encodedPhone');

    try {
      await SystemChannels.platform.invokeMethod(
        'SystemNavigator.pop',
        {'animated': false},
      );
    } catch (_) {}

    _callFamilyMember();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _shieldMajorActive = false);
    });
  }

  void _callFamilyMember() async {
    final contact = _familyContact;
    if (contact == null || contact.isEmpty) return;

    try {
      const channel = MethodChannel('com.safeguard.mobile/call_monitor');
      await channel.invokeMethod('openDialerWithNumber', {'phoneNumber': contact});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Llama a tu familiar: $contact'),
            backgroundColor: AppColors.safeGreen,
          ),
        );
      }
    }
  }

  void _showConfigureFamilyContact() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text(
          'Configurar Familiar de Confianza',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ingresa el número de tu familiar para el Modo Escudo Mayor',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Ej: +52 55 1234-5678',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.neonCyan),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final number = controller.text.trim();
              if (number.isNotEmpty) {
                await VishingDetectorService.setEmergencyFamilyContact(number);
                if (mounted) {
                  setState(() => _familyContact = number);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Familiar guardado correctamente'),
                      backgroundColor: AppColors.safeGreen,
                    ),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopMonitoring();
    NfcProtectionService.stopMonitoring();
    super.dispose();
  }

  int get _blockedToday => _recentCalls.where((c) => c.wasBlocked).length;
  int get _threatsDetected => _recentCalls.where((c) => c.isThreat).length;
  int get _safeCount =>
      _recentCalls.where((c) => c.threatLevel == CallThreatLevel.safe).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildProtectionStatus()),
            SliverToBoxAdapter(child: _buildTriangulationCard()),
            if (_isSeniorUser) SliverToBoxAdapter(child: _buildShieldMajor()),
            SliverToBoxAdapter(child: _buildEstadisticas()),
            SliverToBoxAdapter(child: _buildLlamadasRecientesTitle()),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildCallCard(_recentCalls[index]),
                childCount: _recentCalls.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.neonCyanGlow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.neonCyan.withOpacity(0.4)),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: AppColors.neonCyan,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Centro de Mando',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                    ),
              ),
              Text(
                'SafeGuard Mobile',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: AppColors.neonCyan),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildProtectionStatus() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: NeonCard(
        glowColor: _protectionActive ? AppColors.neonCyan : AppColors.alertRed,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _protectionActive
                        ? AppColors.neonCyanGlow
                        : AppColors.alertRedGlow,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _protectionActive
                        ? Icons.security_rounded
                        : Icons.security_update_warning_rounded,
                    color: _protectionActive
                        ? AppColors.neonCyan
                        : AppColors.alertRed,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estado de Protección',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                      Text(
                        _protectionActive ? 'Activo' : 'Desactivado',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      StatusIndicator(
                        isActive: _protectionActive,
                        activeLabel: 'Monitoreando llamadas',
                        inactiveLabel: 'Toca para activar',
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _protectionActive,
                  onChanged: (value) {
                    setState(() => _protectionActive = value);
                    if (value) {
                      _startMonitoring();
                    } else {
                      _stopMonitoring();
                    }
                  },
                ),
              ],
            ),
            if (!_protectionActive) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.warningAmber, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sin protección activa. Tus llamadas no serán analizadas.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.warningAmber,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TARJETA DE TRIANGULACIÓN EN TIEMPO REAL
  // ============================================================
  Widget _buildTriangulationCard() {
    final result = _lastTriangulation;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: NeonCard(
        glowColor: result?.isHighRisk == true
            ? AppColors.alertRed
            : AppColors.neonCyan,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.radar_rounded,
                    color: AppColors.neonCyan, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Análisis en Tiempo Real',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _protectionActive
                        ? AppColors.safeGreen
                        : AppColors.textMuted,
                    shape: BoxShape.circle,
                    boxShadow: _protectionActive
                        ? [
                            BoxShadow(
                              color: AppColors.safeGreen.withOpacity(0.6),
                              blurRadius: 6,
                            )
                          ]
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (result == null)
              Text(
                _protectionActive
                    ? 'Inicializando motor de detección...'
                    : 'Protección desactivada.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else ...[
              _buildTriangulationRow(
                icon: Icons.phone_in_talk_rounded,
                label: 'Llamada activa',
                value: result.activeCallNumber ?? 'Ninguna',
                isAlert: result.activeCallNumber != null,
              ),
              const SizedBox(height: 8),
              _buildTriangulationRow(
                icon: Icons.account_balance_rounded,
                label: 'App bancaria abierta',
                value: result.hasBankingApp
                    ? result.detectedBankingApps.join(', ')
                    : 'Ninguna',
                isAlert: result.isCallBankingCombo,
              ),
              const SizedBox(height: 8),
              _buildTriangulationRow(
                icon: Icons.desktop_access_disabled_rounded,
                label: 'App de acceso remoto',
                value: result.hasRemoteAccessApp
                    ? result.detectedRiskyApps.join(', ')
                    : 'No detectada',
                isAlert: result.hasRemoteAccessApp,
              ),
              if (result.isHighRisk) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _triggerHighRiskAlert(result),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.alertRedGlow,
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: AppColors.alertRed.withOpacity(0.5)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_rounded,
                            color: AppColors.alertRed, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '¡RIESGO ALTO DETECTADO! Toca para ver la alerta',
                            style: TextStyle(
                              color: AppColors.alertRed,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTriangulationRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isAlert,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: isAlert ? AppColors.alertRed : AppColors.textMuted,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 13),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: isAlert ? AppColors.alertRed : AppColors.textPrimary,
            fontWeight: isAlert ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
          textAlign: TextAlign.right,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ============================================================
  // MODO ESCUDO MAYOR (solo usuarios ≥ 65 años)
  // Botón que llama directamente al familiar guardado
  // ============================================================
  Widget _buildShieldMajor() {
    final hasContact = _familyContact != null && _familyContact!.isNotEmpty;
    final isHighRisk = _lastTriangulation?.isHighRisk ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              (isHighRisk ? AppColors.alertRed : AppColors.safeGreen)
                  .withOpacity(0.15),
              AppColors.surfaceCard,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (isHighRisk ? AppColors.alertRed : AppColors.safeGreen)
                .withOpacity(isHighRisk ? 0.6 : 0.3),
            width: isHighRisk ? 2 : 1,
          ),
          boxShadow: isHighRisk
              ? [
                  BoxShadow(
                    color: AppColors.alertRed.withOpacity(0.2),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.safeGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.safeGreen.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.elderly_rounded,
                      color: AppColors.safeGreen, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Modo Escudo Mayor',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.neonCyanGlow,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '65+',
                              style: TextStyle(
                                color: AppColors.neonCyan,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasContact
                            ? 'Familiar: $_familyContact'
                            : 'Configura tu familiar de confianza',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                              color: hasContact
                                  ? AppColors.safeGreen
                                  : AppColors.warningAmber,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _activateShieldMajor,
                icon: Icon(
                  hasContact ? Icons.call_rounded : Icons.person_add_rounded,
                  size: 20,
                ),
                label: Text(
                  hasContact
                      ? '¡LLAMAR A MI FAMILIAR AHORA!'
                      : 'CONFIGURAR FAMILIAR DE CONFIANZA',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isHighRisk ? AppColors.alertRed : AppColors.safeGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                  elevation: isHighRisk ? 4 : 0,
                ),
              ),
            ),
            if (isHighRisk && hasContact) ...[
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  '⚠ Riesgo alto detectado — se recomienda llamar ahora',
                  style: TextStyle(
                    color: AppColors.alertRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEstadisticas() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estadísticas de Hoy',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.block_rounded,
                  label: 'Bloqueadas',
                  value: '$_blockedToday',
                  color: AppColors.alertRed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.radar_rounded,
                  label: 'Amenazas',
                  value: '$_threatsDetected',
                  color: AppColors.warningAmber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.verified_user_rounded,
                  label: 'Seguras',
                  value: '$_safeCount',
                  color: AppColors.safeGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLlamadasRecientesTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Text(
            'Llamadas Recientes',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const Spacer(),
          TextButton(
            onPressed: () {},
            child: const Text('Ver todo'),
          ),
        ],
      ),
    );
  }

  Widget _buildCallCard(CallRecord call) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: NeonCard(
        glowColor: call.threatLevel == CallThreatLevel.dangerous
            ? AppColors.alertRed
            : call.threatLevel == CallThreatLevel.suspicious
                ? AppColors.warningAmber
                : AppColors.neonCyan,
        onTap: () => _showCallDetails(call),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _CallTypeIcon(
                    callType: call.callType,
                    threatLevel: call.threatLevel),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        call.displayName,
                        style: Theme.of(context).textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatTime(call.timestamp),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                ThreatBadge(level: call.threatLevel),
              ],
            ),
            if (call.threatIndicators.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              ...call.threatIndicators.take(2).map((indicator) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_right_rounded,
                            color: AppColors.alertRed, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            indicator,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
            if (call.wasBlocked) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.alertRedGlow,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.block_rounded,
                        color: AppColors.alertRed, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'LLAMADA BLOQUEADA',
                      style: TextStyle(
                        color: AppColors.alertRed,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCallDetails(CallRecord call) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => CallDetailSheet(call: call),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CallTypeIcon extends StatelessWidget {
  final CallType callType;
  final CallThreatLevel threatLevel;

  const _CallTypeIcon({required this.callType, required this.threatLevel});

  @override
  Widget build(BuildContext context) {
    final color = threatLevel == CallThreatLevel.dangerous
        ? AppColors.alertRed
        : threatLevel == CallThreatLevel.suspicious
            ? AppColors.warningAmber
            : AppColors.neonCyan;

    final icon = callType == CallType.incoming
        ? Icons.call_received_rounded
        : callType == CallType.outgoing
            ? Icons.call_made_rounded
            : Icons.call_missed_rounded;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class CallDetailSheet extends StatelessWidget {
  final CallRecord call;

  const CallDetailSheet({super.key, required this.call});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(child: AnimatedThreatBadge(level: call.threatLevel)),
          const SizedBox(height: 20),
          Center(
            child: Text(
              call.displayName,
              style: Theme.of(context).textTheme.headlineLarge,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              call.phoneNumber,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 20),
          if (call.analysisNote != null) ...[
            AlertCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.alertRed, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      call.analysisNote!,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (call.threatIndicators.isNotEmpty) ...[
            Text(
              'Indicadores Detectados',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            ...call.threatIndicators.map((ind) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.warningAmber, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ind,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Cerrar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.block_rounded),
                  label: const Text('Reportar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.alertRed,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
