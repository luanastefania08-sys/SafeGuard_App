# ============================================================
# CIBER-ESCUDO — Reglas R8/ProGuard
# Ofuscación completa del código para distribución segura
# ============================================================

# ── Flutter: mantener clases esenciales ─────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-dontwarn io.flutter.**

# ── Clases propias del Escudo ────────────────────────────────
# Mantener para que Android pueda instanciarlas via AndroidManifest
-keep class com.anti.estafa.MainActivity { *; }
-keep class com.anti.estafa.BootReceiver { *; }
-keep class com.anti.estafa.AntiEstafaForegroundService { *; }
-keep class com.anti.estafa.AntiEstafaAccessibilityService { *; }

# ── Kotlin: no romper reflexión ──────────────────────────────
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings { <fields>; }
-keepclassmembers class kotlin.Lazy { *; }

# ── AndroidX / Support ───────────────────────────────────────
-keep class androidx.** { *; }
-keep interface androidx.** { *; }
-dontwarn androidx.**

# ── Anotaciones ──────────────────────────────────────────────
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keep public class * extends java.lang.Exception

# ── Servicio de Accesibilidad ────────────────────────────────
-keep public class * extends android.accessibilityservice.AccessibilityService
-keep class android.accessibilityservice.** { *; }

# ── Foreground Service / BroadcastReceiver ───────────────────
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver

# ── NFC ──────────────────────────────────────────────────────
-keep class android.nfc.** { *; }
-dontwarn android.nfc.**

# ── Telephony ────────────────────────────────────────────────
-keep class android.telephony.** { *; }

# ── Seguridad: encriptación ──────────────────────────────────
-keep class androidx.security.crypto.** { *; }
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**

# ── Eliminación de logs en release ──────────────────────────
-assumenosideeffects class android.util.Log {
    public static int v(...);
    public static int d(...);
    public static int i(...);
    public static int w(...);
}

# ── Atributos para stack traces útiles en crash reports ──────
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# ── Ofuscación agresiva ──────────────────────────────────────
-repackageclasses 'ae'
-allowaccessmodification
-overloadaggressively

# ── Multidex ─────────────────────────────────────────────────
-keep class androidx.multidex.** { *; }
