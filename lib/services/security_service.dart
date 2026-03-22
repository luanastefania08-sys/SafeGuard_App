import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/call_record.dart';

class SecurityService {
  static const MethodChannel _channel =
      MethodChannel('com.safeguard.mobile/security');

  static final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static Future<void> enableScreenSecurity() async {
    try {
      await _channel.invokeMethod('setSecureFlag', {'enabled': true});
    } on PlatformException catch (e) {
      print('Error enabling screen security: ${e.message}');
    }
  }

  static Future<void> disableScreenSecurity() async {
    try {
      await _channel.invokeMethod('setSecureFlag', {'enabled': false});
    } on PlatformException catch (e) {
      print('Error disabling screen security: ${e.message}');
    }
  }

  static Future<bool> isScreenSecurityEnabled() async {
    try {
      final bool result =
          await _channel.invokeMethod('isSecureFlagEnabled') ?? false;
      return result;
    } on PlatformException {
      return false;
    }
  }

  static Future<void> saveSecureData(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  static Future<String?> getSecureData(String key) async {
    return await _secureStorage.read(key: key);
  }

  static Future<void> deleteSecureData(String key) async {
    await _secureStorage.delete(key: key);
  }

  static Future<void> clearAllSecureData() async {
    await _secureStorage.deleteAll();
  }

  static CallThreatLevel analyzePhoneNumber(String phoneNumber) {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    if (_isKnownSafeNumber(cleanNumber)) return CallThreatLevel.safe;
    if (_isKnownDangerousNumber(cleanNumber)) return CallThreatLevel.dangerous;

    int suspicionScore = 0;

    if (cleanNumber.startsWith('+')) {
      if (!cleanNumber.startsWith('+52') &&
          !cleanNumber.startsWith('+1') &&
          !cleanNumber.startsWith('+34')) {
        suspicionScore += 30;
      }
    }

    if (cleanNumber.length > 13) suspicionScore += 20;
    if (RegExp(r'(\d)\1{5,}').hasMatch(cleanNumber)) suspicionScore += 40;

    if (suspicionScore >= 50) return CallThreatLevel.suspicious;
    if (suspicionScore >= 70) return CallThreatLevel.dangerous;

    return CallThreatLevel.unknown;
  }

  static List<String> detectVishingIndicators(
      String transcription, String phoneNumber) {
    final List<String> indicators = [];
    final lowerText = transcription.toLowerCase();

    for (final pattern in vishingPatterns) {
      for (final keyword in pattern.keywords) {
        if (lowerText.contains(keyword.toLowerCase())) {
          indicators.add('${pattern.name}: "$keyword" detectado');
          break;
        }
      }
    }

    final urgentPhrases = [
      'inmediatamente', 'ahora mismo', 'en este momento',
      'última oportunidad', 'tiempo limitado', 'hoy mismo',
    ];

    for (final phrase in urgentPhrases) {
      if (lowerText.contains(phrase)) {
        indicators.add('Urgencia artificial: "$phrase"');
      }
    }

    final dataRequests = [
      'número de tarjeta', 'contraseña', 'pin', 'código',
      'número de cuenta', 'clabe', 'datos personales',
    ];

    for (final request in dataRequests) {
      if (lowerText.contains(request)) {
        indicators.add('Solicitud de datos: "$request"');
      }
    }

    return indicators;
  }

  static Future<void> saveAlertPreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  static Future<bool> getAlertPreference(String key,
      {bool defaultValue = true}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? defaultValue;
  }

  static bool _isKnownSafeNumber(String number) {
    const safeNumbers = ['800', '080', '900'];
    for (final prefix in safeNumbers) {
      if (number.startsWith(prefix)) return true;
    }
    return false;
  }

  static bool _isKnownDangerousNumber(String number) {
    return false;
  }
}
