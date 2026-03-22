package com.anti.estafa

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.IBinder
import android.telephony.TelephonyManager
import androidx.core.app.NotificationCompat

// ============================================================
// Anti-Estafa Foreground Service
// Mantiene el Escudo Activo en segundo plano.
// Usa BroadcastReceiver para monitorear llamadas sin polling.
// Impacto estimado en batería: < 1% diario.
// ============================================================
class AntiEstafaForegroundService : Service() {

    companion object {
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "anti_estafa_shield"
        private const val CHANNEL_NAME = "Escudo Anti-Estafa"
        private const val THREAT_NOTIFICATION_ID = 1002
    }

    private val phoneStateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE) ?: return
            if (state == TelephonyManager.EXTRA_STATE_OFFHOOK) {
                // Llamada activa — verificar si hay app bancaria o remota en primer plano
                checkRiskOnCallStart()
            }
        }
    }

    private val appInstallReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val packageName = intent.data?.schemeSpecificPart ?: return
            val riskyApps = listOf(
                "com.anydesk.anydeskandroid", "com.teamviewer.teamviewer",
                "com.rustdesk.rustdesk", "com.realvnc.viewer.android",
                "org.uvnc.bvnc", "net.christianbeier.droidvnc_ng",
                "com.anydesk.anydeskandroid.partner", "com.teamviewer.host"
            )
            if (riskyApps.contains(packageName)) {
                showThreatNotification(
                    title = "⚠️ App Peligrosa Instalada",
                    body = "Se instaló $packageName, usada por estafadores para control remoto. Desinstálala ahora."
                )
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildPersistentNotification())
        registerPhoneReceiver()
        registerAppInstallReceiver()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        try { unregisterReceiver(phoneStateReceiver) } catch (_: Exception) {}
        try { unregisterReceiver(appInstallReceiver) } catch (_: Exception) {}
        // Auto-restart si el sistema mata el servicio
        val restartIntent = Intent(this, AntiEstafaForegroundService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(restartIntent)
        } else {
            startService(restartIntent)
        }
    }

    // ── Registro de receivers ────────────────────────────────
    private fun registerPhoneReceiver() {
        val filter = IntentFilter(TelephonyManager.ACTION_PHONE_STATE_CHANGED)
        registerReceiver(phoneStateReceiver, filter)
    }

    private fun registerAppInstallReceiver() {
        val filter = IntentFilter(Intent.ACTION_PACKAGE_ADDED).apply {
            addDataScheme("package")
        }
        registerReceiver(appInstallReceiver, filter)
    }

    // ── Verificación de riesgo al detectar llamada activa ────
    private fun checkRiskOnCallStart() {
        val foregroundPkg = AntiEstafaAccessibilityService.currentForegroundPackage
        val isBankingOpen = AntiEstafaAccessibilityService.isBankingAppInForeground
        val isRemoteOpen  = AntiEstafaAccessibilityService.isRemoteAppInForeground

        when {
            isRemoteOpen -> showThreatNotification(
                title = "🚨 PELIGRO CRÍTICO",
                body = "App de control remoto activa durante una llamada. ¡CORTE LA LLAMADA AHORA!"
            )
            isBankingOpen -> showThreatNotification(
                title = "⚠️ POSIBLE ESTAFA",
                body = "Llamada activa mientras usa una app bancaria. Los bancos reales NUNCA llaman así."
            )
        }
    }

    // ── Notificación persistente del escudo ─────────────────
    private fun buildPersistentNotification(): Notification {
        val openIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("🛡 Escudo Anti-Estafa Activo")
            .setContentText("Monitoreando llamadas y apps. Toque para abrir.")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()
    }

    // ── Notificación de alerta de amenaza ────────────────────
    private fun showThreatNotification(title: String, body: String) {
        val openIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this, THREAT_NOTIFICATION_ID, openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVibrate(longArrayOf(0, 400, 200, 400, 200, 800))
            .build()

        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(THREAT_NOTIFICATION_ID, notification)
    }

    // ── Canal de notificaciones ──────────────────────────────
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Canal de servicio del Escudo Anti-Estafa"
                setShowBadge(false)
            }
            val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }
}
