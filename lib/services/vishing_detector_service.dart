import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/call_record.dart';

enum AppRiskLevel { safe, moderate, critical }

class RiskyApp {
  final String packageName;
  final String displayName;
  final AppRiskLevel riskLevel;
  final String reason;

  const RiskyApp({
    required this.packageName,
    required this.displayName,
    required this.riskLevel,
    required this.reason,
  });
}

// ============================================================
// LISTA NEGRA — Apps de acceso remoto (CRÍTICO) y
// 20 apps bancarias/fintech Argentina + México (MODERADO)
// Escudo Activo dispara alerta: llamada activa + cualquiera de estas
// ============================================================
const List<RiskyApp> kRiskyApps = [

  // ── Acceso Remoto — RIESGO CRÍTICO ───────────────────────
  RiskyApp(
    packageName: 'com.anydesk.anydeskandroid',
    displayName: 'AnyDesk',
    riskLevel: AppRiskLevel.critical,
    reason: 'AnyDesk es usada por estafadores para tomar control remoto del dispositivo y robar credenciales bancarias.',
  ),
  RiskyApp(
    packageName: 'com.anydesk.anydeskandroid.partner',
    displayName: 'AnyDesk (Partner)',
    riskLevel: AppRiskLevel.critical,
    reason: 'Variante de AnyDesk usada en fraudes de soporte técnico falso.',
  ),
  RiskyApp(
    packageName: 'com.teamviewer.teamviewer',
    displayName: 'TeamViewer',
    riskLevel: AppRiskLevel.critical,
    reason: 'TeamViewer permite acceso remoto total. Los estafadores la usan para robar datos bancarios.',
  ),
  RiskyApp(
    packageName: 'com.teamviewer.host',
    displayName: 'TeamViewer Host',
    riskLevel: AppRiskLevel.critical,
    reason: 'Permite control permanente del dispositivo. Extremadamente peligroso si fue instalado por un tercero.',
  ),
  RiskyApp(
    packageName: 'com.rustdesk.rustdesk',
    displayName: 'RustDesk',
    riskLevel: AppRiskLevel.critical,
    reason: 'RustDesk es usada frecuentemente en fraudes de soporte técnico falso.',
  ),
  RiskyApp(
    packageName: 'com.realvnc.viewer.android',
    displayName: 'VNC Viewer',
    riskLevel: AppRiskLevel.critical,
    reason: 'Permite control remoto del dispositivo.',
  ),
  RiskyApp(
    packageName: 'org.uvnc.bvnc',
    displayName: 'bVNC Remote Desktop',
    riskLevel: AppRiskLevel.critical,
    reason: 'Control remoto del dispositivo.',
  ),
  RiskyApp(
    packageName: 'net.christianbeier.droidvnc_ng',
    displayName: 'droidVNC-NG',
    riskLevel: AppRiskLevel.critical,
    reason: 'Permite que otros controlen tu pantalla de forma remota.',
  ),

  // ── Argentina — RIESGO MODERADO ───────────────────────────
  RiskyApp(
    packageName: 'com.mercadopago.wallet',
    displayName: 'Mercado Pago',
    riskLevel: AppRiskLevel.moderate,
    reason: 'Billetera digital — alerta si hay llamada activa simultánea.',
  ),
  RiskyApp(
    packageName: 'com.modo.app',
    displayName: 'Modo',
    riskLevel: AppRiskLevel.moderate,
    reason: 'App de pagos interoperables — alerta si hay llamada activa.',
  ),
  RiskyApp(
    packageName: 'la.uala.ar',
    displayName: 'Ualá',
    riskLevel: AppRiskLevel.moderate,
    reason: 'Billetera virtual — alerta si hay llamada activa simultánea.',
  ),
  RiskyApp(
    packageName: 'ar.com.bna.cuentadni',
    displayName: 'Cuenta DNI (BNA)',
    riskLevel: AppRiskLevel.moderate,
    reason: 'App del Banco Nación — alerta si hay llamada activa simultánea.',
  ),
  RiskyApp(
    packageName: 'ar.com.bna.bnamas',
    displayName: 'BNA+',
    riskLevel: AppRiskLevel.moderate,
    reason: 'App del Banco Nación — alerta si hay llamada activa simultánea.',
  ),
  RiskyApp(
    packageName: 'com.naranjadigital.naranjaX',
    displayName: 'Naranja X',
    riskLevel: AppRiskLevel.moderate,
    reason: 'Fintech Argentina — alerta si hay llamada activa simultánea.',
  ),
  RiskyApp(
    packageName: 'com.telecom.personalPay',
    displayName: 'Personal Pay',
    riskLevel: AppRiskLevel.moderate,
    reason: 'Billetera digital Personal — alerta si hay llamada activa.',
  ),
  RiskyApp(
    packageName: 'com.amx.claropay',
    displayName: 'Claro Pay',
    riskLevel: AppRiskLevel.moderate,
    reason: 'Billetera digital Claro — alerta si hay llamada activa.',
  ),
  RiskyApp(
    packageName: 'com.dolarapp',
    displayName: 'Dolar App',
    riskLevel: AppRiskLevel.moderate,
    reason: 'Exchange de divisas — alerta si hay llamada activa simultánea.',
  ),
  RiskyApp(
    packageName: 'com.prexcard.app',
    displayName: 'Prex',
    riskLevel: AppRiskLevel.moderate,
    reason: 'Tarjeta prepaga digital — alerta si hay llamada activa.',
  ),
  RiskyApp(
    packageName: 'ar.com.santander.rio.mobileapp',
    displayName: 'Santander Argentina',
    riskLevel: AppRiskLevel.moderate,
    reason: 'App bancaria — alerta si hay llamada activa simultánea.',
  ),
  RiskyApp(
    packageName: 'ar.com.bancogalicia.android',
    displayName: 'Banco Galicia',
    riskLevel: AppRiskLevel.moderate,
    reason: 'App bancaria — alerta si hay llamada activa simultánea.',
  ),
  RiskyApp(
    packageName: 'ar.com.bbva',
    displayName: 'BBVA Argentina',
    riskLevel: AppRiskLevel.moderate,
    reason: 'App bancaria — alerta si hay llamada activa simultánea.',
  ),
  RiskyApp(
    packageName: 'ar.com.macro.mobile',
    displayName: 'Banco Macro',
    riskLevel: AppRiskLevel.moderate,
    reason: 'App bancaria — alerta si hay llamada activa simultánea.',
  ),
  RiskyApp(
    packageName: 'ar.com.brubank',
    displayName: 'Brubank',
    riskLevel: AppRiskLevel.moderate,
    reason: 'Banco digital — alerta si hay llamada activa simultánea.',
  ),
  RiskyApp(
    packageName: 'com.lemoncash',
    displayName: 'Lemon Cash',
    riskLevel: AppRiskLevel.moderate,
    reason: 'Billetera cripto/fiat — alerta si hay llamada activa.',
  ),
  RiskyApp(
    packageName: 'com.binance.dev',
    displayName: 'Binance',
    riskLevel: AppRiskLevel.moderate,
    reason: 'Exchange de criptomonedas — alerta si hay llamada activa.',
  ),
  RiskyApp(
    packageName: 'ar.com.belo',
    displayName: 'Belo',
    riskLevel: AppRiskLevel.moderate,
    reason: 'Billetera cripto — alerta si hay llamada activa simultánea.',
  ),
  RiskyApp(
    packageName: 'ar.com.vibrant',
    displayName: 'Vibrant',
    riskLevel: AppRiskLevel.moderate,
    reason: 'Billetera digital — alerta si hay llamada activa simultánea.',
  ),
  RiskyApp(
    packageName: 'ar.gob.anses',
    displayName: 'Mi ANSES',
    riskLevel: AppRiskLevel.moderate,
    reason: 'App de ANSES — alerta si hay llamada activa (estafadores se hacen pasar por agentes).',
  ),

  // ── México — RIESGO MODERADO ──────────────────────────────
  RiskyApp(
    packageName: 'com.bbva.bbvacontigo',
    displayName: 'BBVA México',
    riskLevel: AppRiskLevel.moderate,
    reason: 'App bancaria — alerta si hay llamada activa simultánea.',
  ),
  RiskyApp(
    packageName: 'com.citibanamex.citi',
    displayName: 'Citibanamex',
    riskLevel: AppRiskLevel.moderate,
    reason: 'App bancaria — alerta si hay llamada activa simultánea.',
  ),
  RiskyApp(
    packageName: 'com.banorte.wellmex',
    displayName: 'Banorte Móvil',
    riskLevel: AppRiskLevel.moderate,
    reason: 'App bancaria — alerta si hay llamada activa simultánea.',
  ),
  RiskyApp(
    packageName: 'com.santander.personal',
    displayName: 'Santander México',
    riskLevel: AppRiskLevel.moderate,
    reason: 'App bancaria — alerta si hay llamada activa simultánea.',
  ),
  RiskyApp(
    packageName: 'com.hsbc.hsbcmexicomobile',
    displayName: 'HSBC México',
    riskLevel: AppRiskLevel.moderate,
    reason: 'App bancaria — alerta si hay llamada activa simultánea.',
  ),
  RiskyApp(
    packageName: 'mx.bancomer.movil',
    displayName: 'Bancomer',
    riskLevel: AppRiskLevel.moderate,
    reason: 'App bancaria — alerta si hay llamada activa simultánea.',
  ),
  RiskyApp(
    packageName: 'com.nu.production',
    displayName: 'Nu (Nubank)',
    riskLevel: AppRiskLevel.moderate,
    reason: 'App bancaria/fintech — alerta si hay llamada activa simultánea.',
  ),
  RiskyApp(
    packageName: 'com.clip.clipmpos',
    displayName: 'Clip',
    riskLevel: AppRiskLevel.moderate,
    reason: 'App de pagos — alerta si hay llamada activa simultánea.',
  ),
];

class TriangulationResult {
  final bool isHighRisk;
  final String? activeCallNumber;
  final List<String> detectedRiskyApps;
  final List<String> detectedBankingApps;
  final String riskDescription;
  final int riskScore;

  const TriangulationResult({
    required this.isHighRisk,
    this.activeCallNumber,
    required this.detectedRiskyApps,
    required this.detectedBankingApps,
    required this.riskDescription,
    required this.riskScore,
  });

  bool get hasRemoteAccessApp => detectedRiskyApps.isNotEmpty;
  bool get hasBankingApp => detectedBankingApps.isNotEmpty;
  bool get isCallBankingCombo =>
      activeCallNumber != null && hasBankingApp;
}

class VishingDetectorService {
  static const MethodChannel _appMonitorChannel =
      MethodChannel('com.safeguard.mobile/app_monitor');
  static const MethodChannel _callChannel =
      MethodChannel('com.safeguard.mobile/call_monitor');

  static StreamController<TriangulationResult>? _triangulationController;
  static Timer? _monitorTimer;
  static bool _isMonitoring = false;

  // ============================================================
  // MOTOR DE TRIANGULACIÓN DE RIESGO
  // Detecta: Llamada activa + App bancaria abierta → ALERTA
  //          App de acceso remoto detectada → ALERTA CRÍTICA
  // ============================================================
  static Future<TriangulationResult> runTriangulation() async {
    final List<String> installedPackages = await _getInstalledRiskyApps();
    final String? activeCall = await _getActiveCallNumber();

    final List<String> riskyRemoteApps = [];
    final List<String> openBankingApps = [];

    for (final pkg in installedPackages) {
      final match = kRiskyApps.where((a) => a.packageName == pkg).firstOrNull;
      if (match != null) {
        if (match.riskLevel == AppRiskLevel.critical) {
          riskyRemoteApps.add(match.displayName);
        } else if (match.riskLevel == AppRiskLevel.moderate) {
          openBankingApps.add(match.displayName);
        }
      }
    }

    int riskScore = 0;
    final List<String> riskFactors = [];

    // Factor 1: App de acceso remoto instalada — CRÍTICO
    if (riskyRemoteApps.isNotEmpty) {
      riskScore += 70;
      riskFactors.add('App de control remoto detectada: ${riskyRemoteApps.join(", ")}');
    }

    // Factor 2: Llamada activa + App bancaria abierta — CRÍTICO
    if (activeCall != null && openBankingApps.isNotEmpty) {
      riskScore += 90;
      riskFactors.add('ALERTA: Llamada activa mientras usas ${openBankingApps.join(", ")}');
    }

    // Factor 3: Solo llamada activa
    if (activeCall != null && !_isKnownContact(activeCall)) {
      riskScore += 20;
      riskFactors.add('Llamada activa detectada');
    }

    // Factor 4: App bancaria sola — informativo
    if (activeCall == null && openBankingApps.isNotEmpty) {
      riskScore += 5;
    }

    final bool isHighRisk = riskScore >= 60;
    final String description = riskFactors.isNotEmpty
        ? riskFactors.join(' | ')
        : 'Sin amenazas detectadas en este momento.';

    return TriangulationResult(
      isHighRisk: isHighRisk,
      activeCallNumber: activeCall,
      detectedRiskyApps: riskyRemoteApps,
      detectedBankingApps: openBankingApps,
      riskDescription: description,
      riskScore: riskScore.clamp(0, 100),
    );
  }

  // ============================================================
  // MONITOREO CONTINUO — usando BroadcastReceiver en background
  // El Foreground Service maneja la detección crítica.
  // Este stream es para actualizar la UI cuando la app está abierta.
  // ============================================================
  static Stream<TriangulationResult> startContinuousMonitoring() {
    _triangulationController?.close();
    _triangulationController = StreamController<TriangulationResult>.broadcast();
    _isMonitoring = true;

    _monitorTimer?.cancel();
    // Polling reducido a 5 segundos (solo cuando la app está en primer plano)
    // El Foreground Service maneja las alertas en background via notificaciones
    _monitorTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!_isMonitoring) return;
      try {
        final result = await runTriangulation();
        _triangulationController?.add(result);
      } catch (_) {}
    });

    runTriangulation().then((result) {
      _triangulationController?.add(result);
    });

    return _triangulationController!.stream;
  }

  static void stopContinuousMonitoring() {
    _isMonitoring = false;
    _monitorTimer?.cancel();
    _monitorTimer = null;
    _triangulationController?.close();
    _triangulationController = null;
  }

  static Future<RiskyApp?> checkSpecificApp(String packageName) async {
    return kRiskyApps.where((a) => a.packageName == packageName).firstOrNull;
  }

  static List<RiskyApp> getAllCriticalApps() =>
      kRiskyApps.where((a) => a.riskLevel == AppRiskLevel.critical).toList();

  static List<RiskyApp> getAllBankingApps() =>
      kRiskyApps.where((a) => a.riskLevel == AppRiskLevel.moderate).toList();

  // ── Perfil de riesgo por edad ─────────────────────────────
  static Future<int> getUserAge() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_age') ?? 0;
  }

  static Future<void> setUserAge(int age) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_age', age);
  }

  static Future<bool> isSeniorUser() async {
    final age = await getUserAge();
    return age >= 65;
  }

  static Future<String?> getEmergencyFamilyContact() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('emergency_family_contact');
  }

  static Future<void> setEmergencyFamilyContact(String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('emergency_family_contact', phoneNumber);
  }

  // ── Métodos privados de interacción nativa ────────────────
  static Future<List<String>> _getInstalledRiskyApps() async {
    try {
      final List<dynamic>? result =
          await _appMonitorChannel.invokeMethod('getInstalledApps');
      if (result == null) return _simulateInstalledApps();
      return result.cast<String>();
    } on PlatformException {
      return _simulateInstalledApps();
    }
  }

  static Future<String?> _getActiveCallNumber() async {
    try {
      final String? result =
          await _callChannel.invokeMethod('getActiveCallNumber');
      return result;
    } on PlatformException {
      return null;
    }
  }

  // Simulación para desarrollo/demo
  static List<String> _simulateInstalledApps() {
    return ['ar.com.bancogalicia.android', 'com.mercadopago.wallet'];
  }

  static bool _isKnownContact(String phoneNumber) => false;
}
