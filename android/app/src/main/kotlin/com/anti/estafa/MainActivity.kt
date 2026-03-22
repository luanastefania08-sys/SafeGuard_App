package com.anti.estafa

import android.app.PendingIntent
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import android.telephony.TelephonyManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        const val CHANNEL_SECURITY    = "com.safeguard.mobile/security"
        const val CHANNEL_APP_MONITOR = "com.safeguard.mobile/app_monitor"
        const val CHANNEL_CALL_MONITOR = "com.safeguard.mobile/call_monitor"
        const val CHANNEL_NFC_CONTROL  = "com.safeguard.mobile/nfc_control"
        const val CHANNEL_NFC_EVENTS   = "com.safeguard.mobile/nfc_events"
        const val CHANNEL_BATTERY      = "com.safeguard.mobile/battery"

        private val BLACKLISTED_PACKAGES = listOf(
            // Acceso remoto — CRÍTICO
            "com.anydesk.anydeskandroid",
            "com.anydesk.anydeskandroid.partner",
            "com.teamviewer.teamviewer",
            "com.teamviewer.host",
            "com.rustdesk.rustdesk",
            "com.realvnc.viewer.android",
            "org.uvnc.bvnc",
            "net.christianbeier.droidvnc_ng",
            // Apps bancarias / fintech Argentina
            "com.mercadopago.wallet",
            "com.modo.app",
            "la.uala.ar",
            "ar.com.bna.cuentadni",
            "ar.com.bna.bnamas",
            "com.naranjadigital.naranjaX",
            "com.telecom.personalPay",
            "com.amx.claropay",
            "com.dolarapp",
            "com.prexcard.app",
            "ar.com.santander.rio.mobileapp",
            "ar.com.bancogalicia.android",
            "ar.com.bbva",
            "ar.com.macro.mobile",
            "ar.com.brubank",
            "com.lemoncash",
            "com.binance.dev",
            "ar.com.belo",
            "ar.com.vibrant",
            "ar.gob.anses",
            // Apps bancarias México (existentes)
            "com.bbva.bbvacontigo",
            "com.citibanamex.citi",
            "com.banorte.wellmex",
            "com.santander.personal",
            "com.hsbc.hsbcmexicomobile",
            "mx.bancomer.movil",
            "com.nu.production",
            "com.clip.clipmpos"
        )
    }

    // ── NFC ──────────────────────────────────────────────────
    private var nfcAdapter: NfcAdapter? = null
    private var nfcEventSink: EventChannel.EventSink? = null
    private var pendingNfcIntent: PendingIntent? = null
    private val nfcFilters = arrayOf(
        IntentFilter(NfcAdapter.ACTION_TAG_DISCOVERED),
        IntentFilter(NfcAdapter.ACTION_NDEF_DISCOVERED),
        IntentFilter(NfcAdapter.ACTION_TECH_DISCOVERED)
    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // ── FLAG_SECURE global — pantalla negra en capturas / acceso remoto ──
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
        // ── Inicializar NFC ──────────────────────────────────
        nfcAdapter = NfcAdapter.getDefaultAdapter(this)
        if (nfcAdapter != null) {
            pendingNfcIntent = PendingIntent.getActivity(
                this, 0,
                Intent(this, javaClass).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
                PendingIntent.FLAG_MUTABLE
            )
        }
        // ── Iniciar Foreground Service ───────────────────────
        startForegroundService()
    }

    override fun onResume() {
        super.onResume()
        nfcAdapter?.enableForegroundDispatch(this, pendingNfcIntent, nfcFilters, null)
    }

    override fun onPause() {
        super.onPause()
        nfcAdapter?.disableForegroundDispatch(this)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val action = intent.action
        if (action == NfcAdapter.ACTION_TAG_DISCOVERED ||
            action == NfcAdapter.ACTION_NDEF_DISCOVERED ||
            action == NfcAdapter.ACTION_TECH_DISCOVERED) {
            nfcEventSink?.success(true)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        setupSecurityChannel(flutterEngine)
        setupAppMonitorChannel(flutterEngine)
        setupCallMonitorChannel(flutterEngine)
        setupNfcChannels(flutterEngine)
        setupBatteryChannel(flutterEngine)
    }

    // ═══════════════════════════════════════════════════════════
    // CANAL 1: Seguridad — FLAG_SECURE, modo developer, SIM
    // ═══════════════════════════════════════════════════════════
    private fun setupSecurityChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_SECURITY)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setSecureFlag" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: true
                        try {
                            if (enabled)
                                window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
                            else
                                window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SECURITY_ERROR", e.message, null)
                        }
                    }
                    "isSecureFlagEnabled" -> {
                        val flags = window.attributes.flags
                        result.success((flags and WindowManager.LayoutParams.FLAG_SECURE) != 0)
                    }
                    "getSimIccid" -> {
                        try {
                            val tm = getSystemService(TELEPHONY_SERVICE) as TelephonyManager
                            result.success(tm.simSerialNumber ?: "UNKNOWN_SIM")
                        } catch (e: SecurityException) {
                            result.success("PERMISSION_DENIED")
                        } catch (e: Exception) {
                            result.error("SIM_ERROR", e.message, null)
                        }
                    }
                    "isDevModeEnabled" -> {
                        try {
                            val adb = Settings.Global.getInt(contentResolver, Settings.Global.ADB_ENABLED, 0)
                            val dev = Settings.Global.getInt(contentResolver, Settings.Global.DEVELOPMENT_SETTINGS_ENABLED, 0)
                            result.success(adb == 1 || dev == 1)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // ═══════════════════════════════════════════════════════════
    // CANAL 2: Monitor de apps instaladas
    // ═══════════════════════════════════════════════════════════
    private fun setupAppMonitorChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_APP_MONITOR)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInstalledApps" -> {
                        try {
                            result.success(getInstalledRiskyApps())
                        } catch (e: Exception) {
                            result.error("APP_MONITOR_ERROR", e.message, null)
                        }
                    }
                    "isAppInstalled" -> {
                        val packageName = call.argument<String>("packageName") ?: ""
                        result.success(isPackageInstalled(packageName))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // ═══════════════════════════════════════════════════════════
    // CANAL 3: Monitor de llamadas + marcador telefónico
    // ═══════════════════════════════════════════════════════════
    private fun setupCallMonitorChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_CALL_MONITOR)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getActiveCallNumber" -> result.success(getCallState())
                    "openDialerWithNumber" -> {
                        val phoneNumber = call.argument<String>("phoneNumber") ?: ""
                        try {
                            openDialerWithNumber(phoneNumber)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("DIALER_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // ═══════════════════════════════════════════════════════════
    // CANAL 4 & 5: NFC — control y eventos
    // ═══════════════════════════════════════════════════════════
    private fun setupNfcChannels(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NFC_CONTROL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isNfcAvailable" -> result.success(nfcAdapter != null)
                    "isNfcEnabled" -> result.success(nfcAdapter?.isEnabled == true)
                    "openNfcSettings" -> {
                        try {
                            startActivity(Intent(Settings.ACTION_NFC_SETTINGS))
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("NFC_SETTINGS_ERROR", e.message, null)
                        }
                    }
                    "openConnectivitySettings" -> {
                        try {
                            startActivity(Intent(Settings.ACTION_WIRELESS_SETTINGS))
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SETTINGS_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NFC_EVENTS)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(args: Any?, sink: EventChannel.EventSink?) {
                    nfcEventSink = sink
                }
                override fun onCancel(args: Any?) {
                    nfcEventSink = null
                }
            })
    }

    // ═══════════════════════════════════════════════════════════
    // CANAL 6: Optimización de batería
    // ═══════════════════════════════════════════════════════════
    private fun setupBatteryChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_BATTERY)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isIgnoringBatteryOptimizations" -> {
                        val pm = getSystemService(POWER_SERVICE) as PowerManager
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    }
                    "requestIgnoreBatteryOptimizations" -> {
                        try {
                            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                data = android.net.Uri.parse("package:$packageName")
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("BATTERY_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // ═══════════════════════════════════════════════════════════
    // Helpers privados
    // ═══════════════════════════════════════════════════════════
    private fun getInstalledRiskyApps(): List<String> =
        BLACKLISTED_PACKAGES.filter { isPackageInstalled(it) }

    private fun isPackageInstalled(packageName: String): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                packageManager.getPackageInfo(packageName, PackageManager.PackageInfoFlags.of(0))
            } else {
                @Suppress("DEPRECATION")
                packageManager.getPackageInfo(packageName, 0)
            }
            true
        } catch (e: PackageManager.NameNotFoundException) { false }
    }

    private fun getCallState(): String? {
        return try {
            val tm = getSystemService(TELEPHONY_SERVICE) as TelephonyManager
            when (tm.callState) {
                TelephonyManager.CALL_STATE_OFFHOOK  -> "LLAMADA_ACTIVA"
                TelephonyManager.CALL_STATE_RINGING  -> "LLAMADA_ENTRANTE"
                else -> null
            }
        } catch (e: Exception) { null }
    }

    private fun openDialerWithNumber(phoneNumber: String) {
        val intent = Intent(Intent.ACTION_DIAL).apply {
            data = android.net.Uri.parse("tel:$phoneNumber")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    private fun startForegroundService() {
        try {
            val serviceIntent = Intent(this, AntiEstafaForegroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(serviceIntent)
            } else {
                startService(serviceIntent)
            }
        } catch (_: Exception) {}
    }
}
