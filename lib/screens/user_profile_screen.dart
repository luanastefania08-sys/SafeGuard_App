import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class UserProfileScreen extends StatefulWidget {
  final bool isOnboarding;

  const UserProfileScreen({super.key, this.isOnboarding = false});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _ageController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isModoEscudoMayor = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _ageController.addListener(_checkAge);
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ageController.text = prefs.getString('user_age') ?? '';
      _nameController.text = prefs.getString('family_name') ?? '';
      _phoneController.text = prefs.getString('family_phone') ?? '';
      _checkAge();
    });
  }

  void _checkAge() {
    final age = int.tryParse(_ageController.text) ?? 0;
    final newVal = age >= 65;
    if (newVal != _isModoEscudoMayor) {
      setState(() => _isModoEscudoMayor = newVal);
    }
  }

  Future<void> _guardarPerfil() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_age', _ageController.text);
    await prefs.setString('family_name', _nameController.text);
    await prefs.setString('family_phone', _phoneController.text);
    await prefs.setBool('modo_escudo_mayor', _isModoEscudoMayor);
    setState(() => _saved = true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.safeGreen,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.black),
              const SizedBox(width: 8),
              Text(
                'Perfil guardado${_isModoEscudoMayor ? ' — Modo Escudo Mayor ACTIVADO' : ''}',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      );

      if (widget.isOnboarding) {
        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted) Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNeon = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isNeon ? AppColors.background : ClassicColors.background,
      appBar: widget.isOnboarding
          ? null
          : AppBar(
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: isNeon ? AppColors.neonCyan : ClassicColors.mintGreen,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isNeon),
                const SizedBox(height: 20),
                _buildProfileCard(isNeon),
                const SizedBox(height: 20),
                _buildAgeField(isNeon),
                if (_isModoEscudoMayor) ...[
                  const SizedBox(height: 10),
                  _buildEscudoMayorBadge(isNeon),
                ],
                const SizedBox(height: 20),
                _buildFamilySection(isNeon),
                const SizedBox(height: 28),
                _buildSaveButton(isNeon),
                const SizedBox(height: 14),
                _buildWarningNote(isNeon),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isNeon) {
    final titleColor = isNeon ? AppColors.neonCyan : ClassicColors.mintGreen;
    final subColor = isNeon ? AppColors.textSecondary : ClassicColors.textSecondary;

    return Column(
      children: [
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: titleColor.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_rounded, color: titleColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'ANTI-ESTAFA',
                      style: TextStyle(
                        color: titleColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'BASE DE DATOS',
                style: TextStyle(
                  color: isNeon ? AppColors.textPrimary : ClassicColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tácticas criminales y cómo defenderse',
                style: TextStyle(color: subColor, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(bool isNeon) {
    final cardColor = isNeon ? AppColors.surfaceCard : ClassicColors.surfaceCard;
    final borderColor = isNeon ? AppColors.borderSubtle : ClassicColors.shadowDark.withOpacity(0.3);
    final textColor = isNeon ? AppColors.textPrimary : ClassicColors.textPrimary;
    final subColor = isNeon ? AppColors.textSecondary : ClassicColors.textSecondary;
    final badgeColor = isNeon ? AppColors.warningAmber : ClassicColors.warningAmber;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: isNeon
            ? null
            : [
                BoxShadow(color: ClassicColors.shadowLight, offset: const Offset(-4, -4), blurRadius: 8),
                BoxShadow(color: ClassicColors.shadowDark.withOpacity(0.6), offset: const Offset(4, 4), blurRadius: 8),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isNeon ? AppColors.neonCyanGlow : ClassicColors.mintGreenGlow,
              shape: BoxShape.circle,
              border: Border.all(
                color: isNeon ? AppColors.neonCyan : ClassicColors.mintGreen,
              ),
            ),
            child: Icon(
              Icons.person_rounded,
              color: isNeon ? AppColors.neonCyan : ClassicColors.mintGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PERFIL DEL USUARIO',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Familiar de confianza + edad',
                  style: TextStyle(color: subColor, fontSize: 12),
                ),
              ],
            ),
          ),
          if (_isModoEscudoMayor)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: badgeColor),
              ),
              child: Text(
                'ESCUDO\nMAYOR',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAgeField(bool isNeon) {
    final labelColor = isNeon ? AppColors.textSecondary : ClassicColors.textSecondary;
    final borderColor = isNeon ? AppColors.borderSubtle : ClassicColors.shadowDark.withOpacity(0.4);
    final activeBorder = isNeon ? AppColors.neonCyan : ClassicColors.mintGreen;
    final textColor = isNeon ? AppColors.textPrimary : ClassicColors.textPrimary;
    final fillColor = isNeon ? AppColors.surfaceCard : ClassicColors.surfaceCard;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EDAD DEL USUARIO',
          style: TextStyle(
            color: labelColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _ageController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
          style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor,
            suffix: _isModoEscudoMayor
                ? Text(
                    '+65 ✓',
                    style: TextStyle(
                      color: isNeon ? AppColors.safeGreen : ClassicColors.safeGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  )
                : null,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: activeBorder, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.alertRed),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.alertRed, width: 2),
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Ingrese su edad';
            final age = int.tryParse(v);
            if (age == null || age < 1 || age > 120) return 'Edad no válida';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildEscudoMayorBadge(bool isNeon) {
    final color = isNeon ? AppColors.neonCyan : ClassicColors.mintGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline_rounded, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Modo Escudo Mayor se activará — botón de llamada de emergencia habilitado',
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilySection(bool isNeon) {
    final labelColor = isNeon ? AppColors.textSecondary : ClassicColors.textSecondary;
    final borderColor = isNeon ? AppColors.borderSubtle : ClassicColors.shadowDark.withOpacity(0.4);
    final activeBorder = isNeon ? AppColors.neonCyan : ClassicColors.mintGreen;
    final textColor = isNeon ? AppColors.textPrimary : ClassicColors.textPrimary;
    final fillColor = isNeon ? AppColors.surfaceCard : ClassicColors.surfaceCard;

    InputDecoration fieldDecoration(String? hint, {IconData? prefixIcon}) => InputDecoration(
          filled: true,
          fillColor: fillColor,
          hintText: hint,
          hintStyle: TextStyle(color: isNeon ? AppColors.textMuted : ClassicColors.textMuted),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: isNeon ? AppColors.textMuted : ClassicColors.textMuted, size: 20)
              : null,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: activeBorder, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.alertRed),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.alertRed, width: 2),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NOMBRE DEL FAMILIAR DE CONFIANZA',
          style: TextStyle(
            color: labelColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          style: TextStyle(color: textColor, fontSize: 16),
          textCapitalization: TextCapitalization.words,
          decoration: fieldDecoration('Ej: Hija María, Hijo Pedro...'),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Ingrese el nombre del familiar';
            return null;
          },
        ),
        const SizedBox(height: 20),
        Text(
          'NÚMERO DEL FAMILIAR (CON CÓDIGO DE ÁREA)',
          style: TextStyle(
            color: labelColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: TextStyle(color: textColor, fontSize: 16),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(15)],
          decoration: fieldDecoration('Ej: 3764149943', prefixIcon: Icons.phone_rounded),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Ingrese el número del familiar';
            if (v.length < 7) return 'Número demasiado corto';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSaveButton(bool isNeon) {
    final bgColor = isNeon ? AppColors.warningAmber : ClassicColors.mintGreen;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.save_rounded, size: 20),
        label: const Text('GUARDAR PERFIL'),
        onPressed: _guardarPerfil,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 18),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildWarningNote(bool isNeon) {
    final color = isNeon ? AppColors.neonCyan : ClassicColors.mintGreen;
    final familyName = _nameController.text.isNotEmpty ? _nameController.text : 'su familiar';

    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(
            color: isNeon ? AppColors.textSecondary : ClassicColors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
          children: [
            const TextSpan(text: 'Durante la alerta de 60s aparecerá el botón\n'),
            TextSpan(
              text: 'LLAMAR A $familyName',
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
            const TextSpan(text: ' como prioridad máxima.'),
          ],
        ),
      ),
    );
  }
}
