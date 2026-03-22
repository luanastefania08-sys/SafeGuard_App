enum CallThreatLevel { safe, suspicious, dangerous, unknown }

enum CallType { incoming, outgoing, missed }

class CallRecord {
  final String id;
  final String phoneNumber;
  final String? contactName;
  final DateTime timestamp;
  final Duration duration;
  final CallType callType;
  final CallThreatLevel threatLevel;
  final List<String> threatIndicators;
  final bool wasBlocked;
  final String? analysisNote;

  const CallRecord({
    required this.id,
    required this.phoneNumber,
    this.contactName,
    required this.timestamp,
    required this.duration,
    required this.callType,
    required this.threatLevel,
    this.threatIndicators = const [],
    this.wasBlocked = false,
    this.analysisNote,
  });

  bool get isThreat =>
      threatLevel == CallThreatLevel.dangerous ||
      threatLevel == CallThreatLevel.suspicious;

  String get displayName => contactName ?? phoneNumber;

  String get threatLevelLabel {
    switch (threatLevel) {
      case CallThreatLevel.safe:
        return 'Segura';
      case CallThreatLevel.suspicious:
        return 'Sospechosa';
      case CallThreatLevel.dangerous:
        return '¡PELIGRO!';
      case CallThreatLevel.unknown:
        return 'Desconocida';
    }
  }
}

class ThreatPattern {
  final String id;
  final String name;
  final String description;
  final String category;
  final List<String> keywords;
  final int riskScore;

  const ThreatPattern({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.keywords,
    required this.riskScore,
  });
}

final List<ThreatPattern> vishingPatterns = [
  ThreatPattern(
    id: 'bank_fraud',
    name: 'Fraude Bancario',
    description: 'Se hacen pasar por empleados de banco',
    category: 'Financiero',
    keywords: [
      'banco', 'cuenta', 'tarjeta', 'transferencia', 'urgente',
      'bloqueada', 'verificación', 'pin', 'clave', 'suspendida'
    ],
    riskScore: 95,
  ),
  ThreatPattern(
    id: 'government_scam',
    name: 'Fraude Gubernamental',
    description: 'Se hacen pasar por entidades del gobierno',
    category: 'Gobierno',
    keywords: [
      'hacienda', 'seguridad social', 'imss', 'sat', 'multa',
      'deuda', 'impuesto', 'policía', 'juzgado', 'mandato'
    ],
    riskScore: 90,
  ),
  ThreatPattern(
    id: 'prize_scam',
    name: 'Premio o Lotería Falsa',
    description: 'Notifican premios o rifas fraudulentas',
    category: 'Premio',
    keywords: [
      'ganaste', 'premio', 'lotería', 'sorteo', 'depósito',
      'impuesto del premio', 'costo de envío', 'reclamar'
    ],
    riskScore: 88,
  ),
  ThreatPattern(
    id: 'tech_support',
    name: 'Soporte Técnico Falso',
    description: 'Fingen ser soporte técnico para acceder al dispositivo',
    category: 'Tecnología',
    keywords: [
      'virus', 'hackeado', 'microsoft', 'apple', 'google',
      'acceso remoto', 'instalar', 'link', 'descarga'
    ],
    riskScore: 85,
  ),
  ThreatPattern(
    id: 'family_emergency',
    name: 'Emergencia Familiar Falsa',
    description: 'Simulan una emergencia de un familiar',
    category: 'Personal',
    keywords: [
      'accidente', 'hospital', 'preso', 'secuestro', 'ayuda',
      'no cuentes', 'rescate', 'fianza', 'urgente'
    ],
    riskScore: 92,
  ),
];
