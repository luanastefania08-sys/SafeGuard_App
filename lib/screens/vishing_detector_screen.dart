import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/call_record.dart';
import '../services/security_service.dart';
import '../widgets/neon_card.dart';
import '../widgets/threat_badge.dart';

class VishingDetectorScreen extends StatefulWidget {
  const VishingDetectorScreen({super.key});

  @override
  State<VishingDetectorScreen> createState() => _VishingDetectorScreenState();
}

class _VishingDetectorScreenState extends State<VishingDetectorScreen>
    with TickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _transcriptionController =
      TextEditingController();

  CallThreatLevel? _analysisResult;
  List<String> _detectedIndicators = [];
  bool _isAnalyzing = false;

  late AnimationController _radarController;
  late Animation<double> _radarAnimation;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _radarAnimation = Tween<double>(begin: 0, end: 1).animate(_radarController);
  }

  @override
  void dispose() {
    _radarController.dispose();
    _phoneController.dispose();
    _transcriptionController.dispose();
    super.dispose();
  }

  Future<void> _analyzeCall() async {
    if (_phoneController.text.isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
      _detectedIndicators = [];
    });

    await Future.delayed(const Duration(milliseconds: 1500));

    final phoneResult =
        SecurityService.analyzePhoneNumber(_phoneController.text);
    final textIndicators = _transcriptionController.text.isNotEmpty
        ? SecurityService.detectVishingIndicators(
            _transcriptionController.text, _phoneController.text)
        : <String>[];

    CallThreatLevel finalResult = phoneResult;
    if (textIndicators.isNotEmpty && textIndicators.length >= 2) {
      finalResult = CallThreatLevel.dangerous;
    } else if (textIndicators.isNotEmpty) {
      finalResult = CallThreatLevel.suspicious;
    }

    setState(() {
      _isAnalyzing = false;
      _analysisResult = finalResult;
      _detectedIndicators = textIndicators;
    });
  }

  void _reset() {
    setState(() {
      _analysisResult = null;
      _detectedIndicators = [];
      _phoneController.clear();
      _transcriptionController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detector de Vishing'),
        actions: [
          if (_analysisResult != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _reset,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIntroCard(),
              const SizedBox(height: 20),
              _buildInputSection(),
              const SizedBox(height: 20),
              if (_isAnalyzing) _buildAnalyzingState(),
              if (_analysisResult != null && !_isAnalyzing)
                _buildResultSection(),
              const SizedBox(height: 20),
              _buildPatternGuide(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return NeonCard(
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _radarAnimation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  ...List.generate(3, (i) {
                    final scale = 0.4 + (_radarAnimation.value + i * 0.33) % 1.0 * 0.6;
                    return Container(
                      width: 48 * scale,
                      height: 48 * scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.neonCyan.withOpacity(
                              (1.0 - (_radarAnimation.value + i * 0.33) % 1.0) * 0.5),
                          width: 1,
                        ),
                      ),
                    );
                  }),
                  const Icon(Icons.radar_rounded,
                      color: AppColors.neonCyan, size: 28),
                ],
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analizador de Llamadas',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Ingresa el número y/o lo que te dijeron para detectar si es una estafa.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '1. Número de Teléfono',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
            decoration: InputDecoration(
              hintText: 'Ej: +52 55 1234-5678',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              prefixIcon:
                  const Icon(Icons.phone_rounded, color: AppColors.neonCyan),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '2. ¿Qué te dijeron? (Opcional)',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'Escribe lo que recuerdes de la llamada',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: TextField(
            controller: _transcriptionController,
            maxLines: 4,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 15, height: 1.5),
            decoration: const InputDecoration(
              hintText:
                  'Ej: "Su cuenta está bloqueada, necesitamos verificar su PIN..."',
              hintStyle: TextStyle(color: AppColors.textMuted),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isAnalyzing ? null : _analyzeCall,
            icon: const Icon(Icons.search_rounded),
            label: const Text('ANALIZAR LLAMADA'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzingState() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Center(
          child: Column(
            children: [
              AnimatedBuilder(
                animation: _radarAnimation,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      ...List.generate(4, (i) {
                        final scale = (_radarAnimation.value + i * 0.25) % 1.0;
                        return Container(
                          width: 100 * scale,
                          height: 100 * scale,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.neonCyan
                                  .withOpacity((1.0 - scale) * 0.8),
                              width: 2,
                            ),
                          ),
                        );
                      }),
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: AppColors.neonCyanGlow,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.search_rounded,
                            color: AppColors.neonCyan, size: 32),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Analizando llamada...',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Verificando patrones de vishing',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildResultSection() {
    final isDangerous = _analysisResult == CallThreatLevel.dangerous;
    final isSuspicious = _analysisResult == CallThreatLevel.suspicious;
    final isSafe = _analysisResult == CallThreatLevel.safe;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        if (isDangerous)
          AlertCard(
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.dangerous_rounded,
                        color: AppColors.alertRed, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '¡ALERTA DE ESTAFA!',
                            style: TextStyle(
                              color: AppColors.alertRed,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'Esta llamada tiene múltiples señales de fraude',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _SafetyTip(
                  icon: Icons.lock_rounded,
                  text: 'NUNCA entregues contraseñas, PINs ni datos bancarios',
                ),
                const SizedBox(height: 8),
                const _SafetyTip(
                  icon: Icons.call_end_rounded,
                  text: 'Cuelga inmediatamente y llama a tu banco directamente',
                ),
                const SizedBox(height: 8),
                const _SafetyTip(
                  icon: Icons.family_restroom_rounded,
                  text: 'Avisa a un familiar de confianza sobre esta llamada',
                ),
              ],
            ),
          )
        else if (isSuspicious)
          NeonCard(
            glowColor: AppColors.warningAmber,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warningAmber.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      color: AppColors.warningAmber, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Llamada Sospechosa',
                        style: TextStyle(
                          color: AppColors.warningAmber,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Hay indicadores de posible fraude. Ten precaución.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else if (isSafe)
          NeonCard(
            glowColor: AppColors.safeGreen,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.safeGreen.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_user_rounded,
                      color: AppColors.safeGreen, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Llamada Segura',
                        style: TextStyle(
                          color: AppColors.safeGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'No se detectaron indicadores de fraude.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (_detectedIndicators.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Indicadores Encontrados',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          ..._detectedIndicators.map((ind) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: NeonCard(
                  glowColor: AppColors.alertRed,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_right_rounded,
                          color: AppColors.alertRed, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ind,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Analizar otra llamada'),
          ),
        ),
      ],
    );
  }

  Widget _buildPatternGuide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(
          'Tipos de Estafa Comunes',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        ...vishingPatterns.take(3).map((pattern) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: NeonCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.alertRedGlow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.warning_rounded,
                          color: AppColors.alertRed, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pattern.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pattern.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.alertRedGlow,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${pattern.riskScore}%',
                        style: const TextStyle(
                          color: AppColors.alertRed,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

class _SafetyTip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SafetyTip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.alertRed, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
