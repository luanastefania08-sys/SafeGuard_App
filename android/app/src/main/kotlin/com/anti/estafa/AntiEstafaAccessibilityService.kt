package com.anti.estafa

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.telephony.TelephonyManager
import android.view.accessibility.AccessibilityEvent

// ============================================================
// Anti-Estafa Accessibility Service
// Detecta la app en primer plano para triangulación de riesgo:
// Si el usuario está en llamada Y abre una app bancaria → ALERTA
// Si detecta app de acceso remoto → ALERTA CRÍTICA
// ============================================================
class AntiEstafaAccessibilityService : AccessibilityService() {

    companion object {
        // ── Apps bancarias / fintech — 20 apps argentinas + México ──
        val BANKING_PACKAGES = setOf(
            // Argentina
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
            // México
            "com.bbva.bbvacontigo",
            "com.citibanamex.citi",
            "com.banorte.wellmex",
            "com.santander.personal",
            "com.hsbc.hsbcmexicomobile",
            "mx.bancomer.movil",
            "com.nu.production",
            "com.clip.clipmpos",
        )

        // ── Apps de control remoto — acceso total al dispositivo ──
        val REMOTE_ACCESS_PACKAGES = setOf(
            "com.anydesk.anydeskandroid",
            "com.anydesk.anydeskandroid.partner",
            "com.teamviewer.teamviewer",
            "com.teamviewer.host",
            "com.rustdesk.rustdesk",
            "com.realvnc.viewer.android",
            "org.uvnc.bvnc",
            "net.christianbeier.droidvnc_ng",
        )

        // Variables estáticas accesibles desde ForegroundService
        @Volatile var currentForegroundPackage: String? = null
        @Volatile var isBankingAppInForeground: Boolean = false
        @Volatile var isRemoteAppInForeground: Boolean = false
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        event ?: return
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val packageName = event.packageName?.toString() ?: return
        currentForegroundPackage = packageName

        val wasInBanking = isBankingAppInForeground
        val wasInRemote  = isRemoteAppInForeground

        isBankingAppInForeground = BANKING_PACKAGES.contains(packageName)
        isRemoteAppInForeground  = REMOTE_ACCESS_PACKAGES.contains(packageName)

        // Solo actuar en el cambio (no repetir en cada evento)
        if (isBankingAppInForeground && !wasInBanking) {
            checkCallStateAndAlert(packageName, "banking")
        }
        if (isRemoteAppInForeground && !wasInRemote) {
            checkCallStateAndAlert(packageName, "remote_access")
        }
    }

    private fun checkCallStateAndAlert(packageName: String, riskType: String) {
        try {
            val telephony = getSystemService(TELEPHONY_SERVICE) as TelephonyManager
            val isInCall  = telephony.callState == TelephonyManager.CALL_STATE_OFFHOOK

            if (isInCall || riskType == "remote_access") {
                val intent = Intent("com.anti.estafa.RISK_DETECTED").apply {
                    putExtra("risk_type", riskType)
                    putExtra("package", packageName)
                    putExtra("in_call", isInCall)
                }
                sendBroadcast(intent)
            }
        } catch (_: Exception) {}
    }

    override fun onInterrupt() {}

    override fun onServiceConnected() {
        super.onServiceConnected()
    }
}
