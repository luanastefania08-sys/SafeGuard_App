import 'package:flutter/material.dart';

class SecurityAuditScreen extends StatelessWidget {
  const SecurityAuditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auditoría de Seguridad'),
        backgroundColor: const Color(0xFF0D47A1),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Text(
                'Análisis de Seguridad en curso...',
                textAlign: TextAlign.center, // AQUÍ ESTABA EL ERROR: Ahora está dentro de Text, no de TextStyle.
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
