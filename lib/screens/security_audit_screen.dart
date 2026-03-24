import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/security_audit_service.dart';

// ==========================================
// PANTALLA DE AUDITORÍA DE SEGURIDAD
// ==========================================

class SecurityAuditScreen extends StatefulWidget {
  const SecurityAuditScreen({super.key});

  @override
  State<SecurityAuditScreen> createState() => _SecurityAuditScreenState();
}

class _SecurityAuditScreenState extends State<SecurityAuditScreen>
    with SingleTickerProviderStateMixin {
  
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auditoría de Seguridad'),
        backgroundColor: const Color(0xFF0D47A1),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children:,
        ),
      ),
    );
  }
}
