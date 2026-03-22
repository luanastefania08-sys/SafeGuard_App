import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// BCRA Sync Service — Sincroniza canales oficiales cada 24h
// Simula API JSON de BCRA / CONDUSEF con datos embebidos
// ============================================================

class BcraOfficialChannel {
  final String name;
  final String type;
  final String phone;
  final String website;
  final String description;
  final bool isVerified;

  const BcraOfficialChannel({
    required this.name,
    required this.type,
    required this.phone,
    required this.website,
    required this.description,
    this.isVerified = true,
  });

  factory BcraOfficialChannel.fromJson(Map<String, dynamic> json) {
    return BcraOfficialChannel(
      name: json['name'] as String,
      type: json['type'] as String,
      phone: json['phone'] as String,
      website: json['website'] as String,
      description: json['description'] as String,
      isVerified: json['isVerified'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'phone': phone,
        'website': website,
        'description': description,
        'isVerified': isVerified,
      };
}

class ScamAlert {
  final String id;
  final String title;
  final String description;
  final String category;
  final String severity;
  final DateTime date;

  const ScamAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.severity,
    required this.date,
  });

  factory ScamAlert.fromJson(Map<String, dynamic> json) {
    return ScamAlert(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      severity: json['severity'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }
}

class BcraService extends ChangeNotifier {
  static final BcraService _instance = BcraService._internal();
  factory BcraService() => _instance;
  BcraService._internal();

  List<BcraOfficialChannel> _officialChannels = [];
  List<ScamAlert> _scamAlerts = [];
  DateTime? _lastSync;
  bool _isSyncing = false;
  String _syncStatus = 'Pendiente de sincronización';

  List<BcraOfficialChannel> get officialChannels => _officialChannels;
  List<ScamAlert> get scamAlerts => _scamAlerts;
  DateTime? get lastSync => _lastSync;
  bool get isSyncing => _isSyncing;
  String get syncStatus => _syncStatus;

  static const Duration _syncInterval = Duration(hours: 24);
  Timer? _syncTimer;

  // ─── Datos embebidos (simulación de API BCRA/CONDUSEF) ────
  static const String _mockApiResponse = '''
{
  "version": "2026.03.15",
  "officialChannels": [
    {
      "name": "CONDUSEF",
      "type": "regulatorio",
      "phone": "800 999 8080",
      "website": "https://www.condusef.gob.mx",
      "description": "Comisión Nacional para la Protección y Defensa de los Usuarios de Servicios Financieros. Atención a quejas y reclamaciones bancarias.",
      "isVerified": true
    },
    {
      "name": "BANXICO",
      "type": "banco_central",
      "phone": "800 226 9426",
      "website": "https://www.banxico.org.mx",
      "description": "Banco de México. Nunca realiza llamadas directas a clientes. Denuncie si alguien dice llamar de BANXICO.",
      "isVerified": true
    },
    {
      "name": "Policía Federal / Emergencias",
      "type": "emergencia",
      "phone": "911",
      "website": "https://www.gob.mx/policiafederal",
      "description": "Número de emergencias nacional. Ante extorsión o amenaza, llame al 911 inmediatamente.",
      "isVerified": true
    },
    {
      "name": "BBVA México",
      "type": "banco",
      "phone": "55 5226 2663",
      "website": "https://www.bbva.mx",
      "description": "Atención a clientes BBVA. El banco NUNCA solicita contraseñas ni tokens por teléfono.",
      "isVerified": true
    },
    {
      "name": "Citibanamex",
      "type": "banco",
      "phone": "800 021 2345",
      "website": "https://www.citibanamex.com",
      "description": "Atención a clientes Citibanamex. Verifique siempre que usted llame al banco, no al revés.",
      "isVerified": true
    },
    {
      "name": "Banorte",
      "type": "banco",
      "phone": "800 226 6783",
      "website": "https://www.banorte.com",
      "description": "Atención a clientes Banorte. No comparta NIP ni claves dinámicas.",
      "isVerified": true
    },
    {
      "name": "Santander México",
      "type": "banco",
      "phone": "800 501 0000",
      "website": "https://www.santander.com.mx",
      "description": "Atención a clientes Santander. Ante sospecha de fraude, bloquee su tarjeta desde la app.",
      "isVerified": true
    },
    {
      "name": "Nu (Nubank)",
      "type": "fintech",
      "phone": "55 4040 0406",
      "website": "https://nu.com.mx",
      "description": "Atención Nu. Nu no realiza llamadas no solicitadas. Todo se gestiona desde la app oficial.",
      "isVerified": true
    },
    {
      "name": "HSBC México",
      "type": "banco",
      "phone": "800 890 0890",
      "website": "https://www.hsbc.com.mx",
      "description": "Atención HSBC. No acepte transferencias a terceros bajo ningún pretexto.",
      "isVerified": true
    }
  ],
  "scamAlerts": [
    {
      "id": "SA-2026-001",
      "title": "Falso funcionario CONDUSEF",
      "description": "Personas se hacen pasar por funcionarios de CONDUSEF pidiendo datos bancarios para 'resolver una queja'. CONDUSEF NUNCA solicita datos por teléfono.",
      "category": "vishing",
      "severity": "alta",
      "date": "2026-03-10"
    },
    {
      "id": "SA-2026-002",
      "title": "Estafa Tarjeta Naranja / Links Falsos",
      "description": "Se detectaron links fraudulentos de Tarjeta Naranja distribuidos por WhatsApp. Los links redirigen a páginas que clonan la app real para robar credenciales.",
      "category": "phishing",
      "severity": "alta",
      "date": "2026-03-08"
    },
    {
      "id": "SA-2026-003",
      "title": "Falso soporte técnico bancario",
      "description": "Estafadores llaman pidiendo instalar AnyDesk o TeamViewer para 'actualizar la seguridad'. Ningún banco solicita acceso remoto a su dispositivo.",
      "category": "remote_access",
      "severity": "critica",
      "date": "2026-03-05"
    },
    {
      "id": "SA-2026-004",
      "title": "Secuestro virtual",
      "description": "Llamadas amenazando con 'secuestro de familiar' exigiendo transferencias inmediatas. Corte la llamada y contacte directamente a su familiar.",
      "category": "extorsion",
      "severity": "critica",
      "date": "2026-02-28"
    },
    {
      "id": "SA-2026-005",
      "title": "Premio falso / Lotería",
      "description": "Mensajes informando de premios falsos que exigen pago previo para 'liberar' el supuesto premio. Ninguna lotería legítima cobra por cobrar un premio.",
      "category": "fraude",
      "severity": "media",
      "date": "2026-02-20"
    }
  ]
}
''';

  // ─── Inicializar y programar sincronización ───────────────
  Future<void> initialize() async {
    await _loadCachedData();
    final needsSync = await _needsSync();
    if (needsSync) {
      await syncNow();
    }
    _scheduleSyncTimer();
  }

  void _scheduleSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) => syncNow());
  }

  Future<bool> _needsSync() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncMs = prefs.getInt('bcra_last_sync');
    if (lastSyncMs == null) return true;
    final last = DateTime.fromMillisecondsSinceEpoch(lastSyncMs);
    return DateTime.now().difference(last) >= _syncInterval;
  }

  // ─── Sincronizar (simula HTTP GET a BCRA API) ─────────────
  Future<void> syncNow() async {
    if (_isSyncing) return;
    _isSyncing = true;
    _syncStatus = 'Sincronizando...';
    notifyListeners();

    try {
      // Simula latencia de red
      await Future.delayed(const Duration(milliseconds: 800));

      // En producción, reemplazar con:
      // final response = await http.get(Uri.parse('https://api.condusef.gob.mx/anti-estafa/v1/channels'));
      // final json = jsonDecode(response.body);
      final json = jsonDecode(_mockApiResponse) as Map<String, dynamic>;

      final channels = (json['officialChannels'] as List)
          .map((c) => BcraOfficialChannel.fromJson(c as Map<String, dynamic>))
          .toList();

      final alerts = (json['scamAlerts'] as List)
          .map((a) => ScamAlert.fromJson(a as Map<String, dynamic>))
          .toList();

      _officialChannels = channels;
      _scamAlerts = alerts;
      _lastSync = DateTime.now();

      await _saveToCache(channels, alerts);

      _syncStatus = 'Actualizado ${_formatDate(_lastSync!)}';
    } catch (e) {
      _syncStatus = 'Error al sincronizar. Usando datos locales.';
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _saveToCache(
      List<BcraOfficialChannel> channels, List<ScamAlert> alerts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bcra_last_sync', DateTime.now().millisecondsSinceEpoch);
    await prefs.setString(
      'bcra_channels',
      jsonEncode(channels.map((c) => c.toJson()).toList()),
    );
  }

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncMs = prefs.getInt('bcra_last_sync');
    if (lastSyncMs != null) {
      _lastSync = DateTime.fromMillisecondsSinceEpoch(lastSyncMs);
      _syncStatus = 'Última sync: ${_formatDate(_lastSync!)}';
    }

    final channelsJson = prefs.getString('bcra_channels');
    if (channelsJson != null) {
      try {
        final list = jsonDecode(channelsJson) as List;
        _officialChannels =
            list.map((c) => BcraOfficialChannel.fromJson(c as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

    // Siempre carga alertas desde datos embebidos como fallback
    if (_officialChannels.isEmpty || _scamAlerts.isEmpty) {
      final json = jsonDecode(_mockApiResponse) as Map<String, dynamic>;
      if (_officialChannels.isEmpty) {
        _officialChannels = (json['officialChannels'] as List)
            .map((c) => BcraOfficialChannel.fromJson(c as Map<String, dynamic>))
            .toList();
      }
      _scamAlerts = (json['scamAlerts'] as List)
          .map((a) => ScamAlert.fromJson(a as Map<String, dynamic>))
          .toList();
    }
  }

  String _formatDate(DateTime dt) {
    final months = [
      '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}
