import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================
// NFC Protection Service
// Detecta actividad NFC no solicitada y muestra alerta preventiva.
// Los estafadores usan NFC para clonar tarjetas de débito/crédito
// cuando el dispositivo está en la cartera (pocket skimming).
// ============================================================
class NfcProtectionService {
  static const MethodChannel _controlChannel =
      MethodChannel('com.safeguard.mobile/nfc_control');
  static const EventChannel _nfcEvents =
      EventChannel('com.safeguard.mobile/nfc_events');

  static StreamSubscription<dynamic>? _subscription;

  static Future<bool> isNfcAvailable() async {
    try {
      return await _controlChannel.invokeMethod('isNfcAvailable') as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isNfcEnabled() async {
    try {
      return await _controlChannel.invokeMethod('isNfcEnabled') as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openNfcSettings() async {
    try {
      await _controlChannel.invokeMethod('openNfcSettings');
    } catch (_) {}
  }

  static Future<void> openConnectivitySettings() async {
    try {
      await _controlChannel.invokeMethod('openConnectivitySettings');
    } catch (_) {}
  }

  // ─── Iniciar monitoreo NFC ────────────────────────────────
  static void startMonitoring(BuildContext context) {
    _subscription?.cancel();
    _subscription = _nfcEvents.receiveBroadcastStream().listen((event) {
      if (event == true) {
        _showNfcAlert(context);
      }
    });
  }

  static void stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
  }

  // ─── Alerta visual de actividad NFC ──────────────────────
  static void _showNfcAlert(BuildContext context) {
    HapticFeedback.heavyImpact();
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFFFAB00), width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.nfc_rounded, color: Color(0xFFFFAB00), size: 26),
            SizedBox(width: 10),
            Text(
              '⚠️ ACTIVIDAD NFC',
              style: TextStyle(
                color: Color(0xFFFFAB00),
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Se detectó actividad NFC en su dispositivo.',
              style: TextStyle(
                color: Color(0xFFF0F4FF),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Los estafadores usan lectores NFC ocultos para leer tarjetas bancarias a distancia.\n\n'
              'Si no está usando NFC activamente, le recomendamos desactivarlo en Ajustes.',
              style: TextStyle(
                color: Color(0xFF7A8BA8),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'IGNORAR',
              style: TextStyle(color: Color(0xFF7A8BA8)),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFAB00),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.settings_rounded, size: 18),
            label: const Text('VER AJUSTES', style: TextStyle(fontWeight: FontWeight.w800)),
            onPressed: () {
              Navigator.pop(ctx);
              openConnectivitySettings();
            },
          ),
        ],
      ),
    );
  }
}
