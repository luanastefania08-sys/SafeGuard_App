import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/bcra_service.dart';
import '../services/antiphishing_service.dart';

class OficialesScreen extends StatefulWidget {
  const OficialesScreen({super.key});

  @override
  State<OficialesScreen> createState() => _OficialesScreenState();
}

class _OficialesScreenState extends State<OficialesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _urlController = TextEditingController();
  PhishingAnalysisResult? _lastAnalysis;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _analizarUrl() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    HapticFeedback.mediumImpact();
    final result = AntiPhishingService().analyzeUrl(url);
    setState(() => _lastAnalysis = result);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final isNeon = Theme.of(context).brightness == Brightness.dark;
    final bg = isNeon ? AppColors.background : ClassicColors.background;
    final accent = isNeon ? AppColors.neonCyan : ClassicColors.mintGreen;
    final textPrimary = isNeon ? AppColors.textPrimary : ClassicColors.textPrimary;
    final textSecondary = isNeon ? AppColors.textSecondary : ClassicColors.textSecondary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isNeon ? AppColors.surface : ClassicColors.surface,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_user_rounded, color: accent, size: 20),
            const SizedBox(width: 8),
            Text(
              'CANALES OFICIALES',
              style: TextStyle(
                color: accent,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accent,
          labelColor: accent,
          unselectedLabelColor: textSecondary,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'BANCOS & REGULADORES'),
            Tab(text: 'ALERTAS ACTIVAS'),
            Tab(text: 'ANTI-PHISHING'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChannelsTab(isNeon, accent, textPrimary, textSecondary),
          _buildAlertsTab(isNeon, accent, textPrimary, textSecondary),
          _buildPhishingTab(isNeon, accent, textPrimary, textSecondary),
        ],
      ),
    );
  }

  // ─── TAB 1: Canales Oficiales ─────────────────────────────
  Widget _buildChannelsTab(bool isNeon, Color accent, Color textPrimary, Color textSecondary) {
    return Consumer<BcraService>(
      builder: (ctx, bcra, _) {
        return RefreshIndicator(
          color: accent,
          onRefresh: bcra.syncNow,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSyncBanner(isNeon, accent, bcra),
              const SizedBox(height: 16),
              ...bcra.officialChannels.map((ch) =>
                  _buildChannelCard(ch, isNeon, accent, textPrimary, textSecondary)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSyncBanner(bool isNeon, Color accent, BcraService bcra) {
    final cardColor = isNeon ? AppColors.surfaceCard : ClassicColors.surfaceCard;
    final borderColor = isNeon ? AppColors.borderSubtle : ClassicColors.shadowDark.withOpacity(0.3);
    final textSecondary = isNeon ? AppColors.textSecondary : ClassicColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          bcra.isSyncing
              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: accent, strokeWidth: 2))
              : Icon(Icons.sync_rounded, color: accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              bcra.syncStatus,
              style: TextStyle(color: textSecondary, fontSize: 12),
            ),
          ),
          if (!bcra.isSyncing)
            GestureDetector(
              onTap: bcra.syncNow,
              child: Text(
                'Actualizar',
                style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChannelCard(BcraOfficialChannel ch, bool isNeon, Color accent, Color textPrimary, Color textSecondary) {
    final cardColor = isNeon ? AppColors.surfaceCard : ClassicColors.surfaceCard;
    final borderColor = isNeon ? AppColors.borderSubtle : ClassicColors.shadowDark.withOpacity(0.3);

    Color typeColor;
    IconData typeIcon;
    switch (ch.type) {
      case 'emergencia':
        typeColor = AppColors.alertRed;
        typeIcon = Icons.emergency_rounded;
        break;
      case 'regulatorio':
      case 'banco_central':
        typeColor = isNeon ? AppColors.warningAmber : ClassicColors.warningAmber;
        typeIcon = Icons.account_balance_rounded;
        break;
      case 'fintech':
        typeColor = isNeon ? AppColors.neonCyan : ClassicColors.mintGreen;
        typeIcon = Icons.phone_android_rounded;
        break;
      default:
        typeColor = isNeon ? AppColors.neonCyan : ClassicColors.mintGreen;
        typeIcon = Icons.account_balance_wallet_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ch.name,
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (ch.isVerified)
                            Icon(Icons.verified_rounded, color: accent, size: 16),
                        ],
                      ),
                      Text(
                        ch.type.toUpperCase().replaceAll('_', ' '),
                        style: TextStyle(color: typeColor, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              ch.description,
              style: TextStyle(color: textSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                Clipboard.setData(ClipboardData(text: ch.phone));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Número copiado: ${ch.phone}'),
                    backgroundColor: isNeon ? AppColors.safeGreen : ClassicColors.safeGreen,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: typeColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.phone_rounded, color: typeColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      ch.phone,
                      style: TextStyle(
                        color: typeColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.copy_rounded, color: typeColor.withOpacity(0.6), size: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TAB 2: Alertas Activas ───────────────────────────────
  Widget _buildAlertsTab(bool isNeon, Color accent, Color textPrimary, Color textSecondary) {
    return Consumer<BcraService>(
      builder: (ctx, bcra, _) {
        if (bcra.scamAlerts.isEmpty) {
          return Center(
            child: Text('Sin alertas activas', style: TextStyle(color: textSecondary)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bcra.scamAlerts.length,
          itemBuilder: (_, i) => _buildScamAlertCard(bcra.scamAlerts[i], isNeon, textPrimary, textSecondary),
        );
      },
    );
  }

  Widget _buildScamAlertCard(ScamAlert alert, bool isNeon, Color textPrimary, Color textSecondary) {
    Color severityColor;
    switch (alert.severity) {
      case 'critica':
        severityColor = AppColors.alertRed;
        break;
      case 'alta':
        severityColor = isNeon ? AppColors.warningAmber : ClassicColors.warningAmber;
        break;
      default:
        severityColor = isNeon ? AppColors.safeGreen : ClassicColors.safeGreen;
    }

    final cardColor = isNeon ? AppColors.surfaceCard : ClassicColors.surfaceCard;
    final borderColor = isNeon ? AppColors.borderSubtle : ClassicColors.shadowDark.withOpacity(0.3);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: severityColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    alert.severity.toUpperCase(),
                    style: TextStyle(color: severityColor, fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert.title,
                    style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              alert.description,
              style: TextStyle(color: textSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 6),
            Text(
              '${alert.date.day}/${alert.date.month}/${alert.date.year}',
              style: TextStyle(color: textSecondary.withOpacity(0.6), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TAB 3: Anti-Phishing ─────────────────────────────────
  Widget _buildPhishingTab(bool isNeon, Color accent, Color textPrimary, Color textSecondary) {
    final fillColor = isNeon ? AppColors.surfaceCard : ClassicColors.surfaceCard;
    final borderColor = isNeon ? AppColors.borderSubtle : ClassicColors.shadowDark.withOpacity(0.4);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPhishingIntro(isNeon, accent, textPrimary, textSecondary),
        const SizedBox(height: 16),
        Text(
          'VERIFICAR ENLACE',
          style: TextStyle(
            color: textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _urlController,
                style: TextStyle(color: textPrimary, fontSize: 15),
                autocorrect: false,
                decoration: InputDecoration(
                  hintText: 'Pegue el enlace aquí...',
                  hintStyle: TextStyle(color: isNeon ? AppColors.textMuted : ClassicColors.textMuted),
                  filled: true,
                  fillColor: fillColor,
                  prefixIcon: Icon(Icons.link_rounded, color: accent, size: 20),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accent, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _analizarUrl,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: isNeon ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Analizar', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        if (_lastAnalysis != null) ...[
          const SizedBox(height: 16),
          _buildAnalysisResult(_lastAnalysis!, isNeon, textPrimary, textSecondary),
        ],
        const SizedBox(height: 20),
        _buildPhishingTips(isNeon, accent, textPrimary, textSecondary),
      ],
    );
  }

  Widget _buildPhishingIntro(bool isNeon, Color accent, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.alertRed.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.alertRed.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.phishing_rounded, color: AppColors.alertRed, size: 20),
              const SizedBox(width: 8),
              Text(
                'Caso Tarjeta Naranja — Links Falsos',
                style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Se detectaron links fraudulentos distribuidos por WhatsApp que imitan la app de Tarjeta Naranja. Antes de abrir cualquier link bancario, verifíquelo aquí.',
            style: TextStyle(color: textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResult(PhishingAnalysisResult result, bool isNeon, Color textPrimary, Color textSecondary) {
    Color riskColor;
    IconData riskIcon;
    switch (result.riskLevel) {
      case PhishingRiskLevel.critical:
        riskColor = AppColors.alertRed;
        riskIcon = Icons.dangerous_rounded;
        break;
      case PhishingRiskLevel.dangerous:
        riskColor = isNeon ? AppColors.warningAmber : ClassicColors.alertOrange;
        riskIcon = Icons.warning_rounded;
        break;
      case PhishingRiskLevel.suspicious:
        riskColor = isNeon ? AppColors.warningAmber : ClassicColors.warningAmber;
        riskIcon = Icons.help_outline_rounded;
        break;
      default:
        riskColor = isNeon ? AppColors.safeGreen : ClassicColors.safeGreen;
        riskIcon = Icons.check_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: riskColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: riskColor.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(riskIcon, color: riskColor, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      style: TextStyle(color: riskColor, fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    Text(
                      result.description,
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (result.redFlags.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...result.redFlags.map((flag) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.flag_rounded, color: riskColor, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(flag, style: TextStyle(color: textSecondary, fontSize: 12, height: 1.4)),
                      ),
                    ],
                  ),
                )),
          ],
          if (result.recommendations.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(color: Colors.white12),
            const SizedBox(height: 6),
            ...result.recommendations.map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_rounded,
                          color: isNeon ? AppColors.neonCyan : ClassicColors.mintGreen, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(rec, style: TextStyle(color: textSecondary, fontSize: 12, height: 1.4)),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildPhishingTips(bool isNeon, Color accent, Color textPrimary, Color textSecondary) {
    final tips = [
      'NUNCA abra links bancarios recibidos por WhatsApp o SMS.',
      'Los bancos NO envían links de acceso por mensajes.',
      'Abra siempre la app oficial instalada en su teléfono.',
      'En Google, los primeros resultados pueden ser anuncios FALSOS.',
      'Verifique que la URL comience con "https://" y el nombre correcto del banco.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REGLAS DE ORO ANTI-PHISHING',
          style: TextStyle(
            color: textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        ...tips.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: accent.withOpacity(0.4)),
                    ),
                    child: Center(
                      child: Text(
                        '${e.key + 1}',
                        style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(e.value, style: TextStyle(color: textSecondary, fontSize: 13, height: 1.5)),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
