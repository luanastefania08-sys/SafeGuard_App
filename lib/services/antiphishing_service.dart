// ============================================================
// Anti-Phishing Service — Detecta links y dominios fraudulentos
// Caso especial: links bancarios por WhatsApp / buscadores
// ============================================================

class PhishingRiskLevel {
  static const String safe = 'SEGURO';
  static const String suspicious = 'SOSPECHOSO';
  static const String dangerous = 'PELIGROSO';
  static const String critical = 'CRITICO';
}

class PhishingAnalysisResult {
  final String url;
  final String riskLevel;
  final String title;
  final String description;
  final List<String> redFlags;
  final List<String> recommendations;
  final bool shouldBlock;

  const PhishingAnalysisResult({
    required this.url,
    required this.riskLevel,
    required this.title,
    required this.description,
    required this.redFlags,
    required this.recommendations,
    required this.shouldBlock,
  });
}

class AntiPhishingService {
  static final AntiPhishingService _instance = AntiPhishingService._internal();
  factory AntiPhishingService() => _instance;
  AntiPhishingService._internal();

  // ─── Dominios legítimos conocidos ────────────────────────
  static const Map<String, String> _legitimateDomains = {
    'bbva.mx': 'BBVA México',
    'banamex.com': 'Citibanamex',
    'citibanamex.com': 'Citibanamex',
    'banorte.com': 'Banorte',
    'santander.com.mx': 'Santander México',
    'hsbc.com.mx': 'HSBC México',
    'nu.com.mx': 'Nu',
    'nubank.com': 'Nu',
    'condusef.gob.mx': 'CONDUSEF',
    'banxico.org.mx': 'BANXICO',
    'cnbv.gob.mx': 'CNBV',
    'gob.mx': 'Gobierno de México',
    'clip.mx': 'Clip',
    'mercadopago.com': 'Mercado Pago',
    'mercadopago.com.mx': 'Mercado Pago',
    'paypal.com': 'PayPal',
    'tarjetanaranja.com': 'Tarjeta Naranja',
  };

  // ─── Patrones de phishing comunes ────────────────────────
  static const List<String> _phishingKeywords = [
    'login', 'verify', 'verification', 'secure', 'account',
    'update', 'confirm', 'validar', 'verificar', 'seguro',
    'acceso', 'actualizar', 'confirmar', 'banca', 'banco-',
    '-banco', 'ban-co', 'naranja-', '-naranja', 'bbva-',
    '-bbva', 'banamex-', '-banamex', 'santander-',
  ];

  static const List<String> _suspiciousTLDs = [
    '.xyz', '.tk', '.ml', '.ga', '.cf', '.gq',
    '.top', '.pw', '.click', '.download', '.work',
    '.link', '.info',
  ];

  static const List<String> _shortenerDomains = [
    'bit.ly', 'tinyurl.com', 'goo.gl', 't.co', 'ow.ly',
    'short.io', 'rebrand.ly', 'tiny.cc', 'is.gd',
    'cutt.ly', 'shorturl.at',
  ];

  // ─── WhatsApp / Buscador link detection ──────────────────
  static const List<String> _bankingSearchPatterns = [
    'tarjeta naranja',
    'naranja x',
    'bbva ingresar',
    'banamex login',
    'banorte acceso',
    'santander banca',
    'banco login',
    'ingresar banco',
    'mi cuenta banco',
  ];

  // ─── Análisis principal ───────────────────────────────────
  PhishingAnalysisResult analyzeUrl(String url, {String? source}) {
    final uri = Uri.tryParse(url.toLowerCase());
    if (uri == null) {
      return PhishingAnalysisResult(
        url: url,
        riskLevel: PhishingRiskLevel.suspicious,
        title: 'URL no válida',
        description: 'El enlace tiene un formato inusual.',
        redFlags: ['Formato de URL inválido'],
        recommendations: ['No abra este enlace'],
        shouldBlock: true,
      );
    }

    final redFlags = <String>[];
    final recommendations = <String>[];
    int riskScore = 0;

    final host = uri.host;

    // 1. Es un acortador de URL?
    if (_isUrlShortener(host)) {
      redFlags.add('El enlace usa un acortador (${host}). Oculta el destino real.');
      riskScore += 40;
    }

    // 2. Es un dominio legítimo conocido?
    if (_isLegitimate(host)) {
      return PhishingAnalysisResult(
        url: url,
        riskLevel: PhishingRiskLevel.safe,
        title: '${_legitimateDomains[_getMainDomain(host)]} — Sitio Oficial',
        description: 'Este dominio pertenece a una entidad verificada.',
        redFlags: [],
        recommendations: [
          'Siempre verifique el candado HTTPS en el navegador.',
          'Nunca ingrese contraseñas si alguien lo pidió por teléfono.',
        ],
        shouldBlock: false,
      );
    }

    // 3. TLD sospechoso?
    if (_hasSuspiciousTLD(host)) {
      redFlags.add('Dominio con extensión inusual (${uri.host.split('.').last}).');
      riskScore += 35;
    }

    // 4. Simula dominio bancario?
    if (_mimicsBankDomain(host)) {
      redFlags.add('El dominio imita el nombre de un banco real.');
      riskScore += 50;
    }

    // 5. Contiene palabras clave de phishing?
    for (final kw in _phishingKeywords) {
      if (host.contains(kw) || uri.path.contains(kw)) {
        redFlags.add('Contiene palabra clave de phishing: "$kw"');
        riskScore += 15;
        break;
      }
    }

    // 6. No usa HTTPS?
    if (uri.scheme != 'https') {
      redFlags.add('No usa conexión segura (HTTPS).');
      riskScore += 25;
    }

    // 7. Proviene de WhatsApp? (riesgo adicional)
    if (source == 'whatsapp') {
      redFlags.add('Enlace recibido por WhatsApp — alta probabilidad de phishing.');
      riskScore += 20;
      recommendations.add('Los bancos NUNCA envían links de acceso por WhatsApp.');
    }

    // 8. IP en lugar de dominio?
    if (_isIPAddress(host)) {
      redFlags.add('El enlace usa una IP en lugar de un dominio.');
      riskScore += 45;
    }

    // Determinar nivel de riesgo
    String riskLevel;
    String title;
    String description;
    bool shouldBlock;

    if (riskScore >= 70) {
      riskLevel = PhishingRiskLevel.critical;
      title = 'ENLACE PELIGROSO — POSIBLE PHISHING';
      description =
          'Este enlace presenta múltiples características de fraude. NO lo abra.';
      shouldBlock = true;
    } else if (riskScore >= 40) {
      riskLevel = PhishingRiskLevel.dangerous;
      title = 'ENLACE SOSPECHOSO';
      description =
          'Este enlace tiene características inusuales. Se recomienda no abrirlo.';
      shouldBlock = true;
    } else if (riskScore >= 20) {
      riskLevel = PhishingRiskLevel.suspicious;
      title = 'PRECAUCIÓN';
      description = 'Verifique la fuente antes de ingresar datos.';
      shouldBlock = false;
    } else {
      riskLevel = PhishingRiskLevel.safe;
      title = 'Sin riesgos detectados';
      description = 'No se encontraron señales de phishing.';
      shouldBlock = false;
    }

    if (recommendations.isEmpty) {
      recommendations.addAll([
        'Abra la app bancaria directamente, nunca desde links.',
        'Ante dudas, llame al número oficial de su banco.',
      ]);
    }

    return PhishingAnalysisResult(
      url: url,
      riskLevel: riskLevel,
      title: title,
      description: description,
      redFlags: redFlags,
      recommendations: recommendations,
      shouldBlock: shouldBlock,
    );
  }

  // ─── Detector de búsqueda bancaria por WhatsApp ───────────
  bool isBankingSearchQuery(String query) {
    final lower = query.toLowerCase();
    return _bankingSearchPatterns.any((p) => lower.contains(p));
  }

  PhishingAnalysisResult analyzeBankingSearch(String query) {
    return PhishingAnalysisResult(
      url: query,
      riskLevel: PhishingRiskLevel.dangerous,
      title: 'RIESGO: Búsqueda bancaria detectada',
      description:
          'Buscar su banco en Google o seguir links de WhatsApp puede llevarle a sitios FALSOS. Los primeros resultados a veces son anuncios fraudulentos.',
      redFlags: [
        'Nunca busque su banco en Google para ingresar.',
        'Los anuncios patrocinados pueden ser sitios falsos.',
        'Links de WhatsApp bancarios son generalmente fraudulentos.',
      ],
      recommendations: [
        'Abra la app oficial de su banco instalada en el teléfono.',
        'Use el número de teléfono impreso en su tarjeta física.',
        'Escriba la URL del banco directamente en el navegador.',
      ],
      shouldBlock: false,
    );
  }

  // ─── Helpers ─────────────────────────────────────────────
  bool _isUrlShortener(String host) =>
      _shortenerDomains.any((d) => host == d || host.endsWith('.$d'));

  bool _isLegitimate(String host) {
    for (final domain in _legitimateDomains.keys) {
      if (host == domain || host.endsWith('.$domain')) return true;
    }
    return false;
  }

  bool _hasSuspiciousTLD(String host) =>
      _suspiciousTLDs.any((tld) => host.endsWith(tld));

  bool _mimicsBankDomain(String host) {
    final bankKeywords = [
      'bbva', 'banamex', 'banorte', 'santander', 'hsbc',
      'bancomer', 'naranja', 'nubank', 'condusef', 'banxico',
    ];
    return bankKeywords.any((k) =>
        host.contains(k) && !_isLegitimate(host));
  }

  bool _isIPAddress(String host) {
    final parts = host.split('.');
    if (parts.length != 4) return false;
    return parts.every((p) => int.tryParse(p) != null);
  }

  String _getMainDomain(String host) {
    final parts = host.split('.');
    if (parts.length >= 2) {
      return '${parts[parts.length - 2]}.${parts[parts.length - 1]}';
    }
    return host;
  }
}
