package com.summationworks.smarttvremote

import android.content.Context
import android.net.wifi.WifiManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var multicastLock: WifiManager.MulticastLock? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "acquire" -> {
                        acquireLock()
                        result.success(null)
                    }
                    "release" -> {
                        releaseLock()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun acquireLock() {
        val lock = multicastLock ?: run {
            val wifi = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            wifi.createMulticastLock("smarttvremote-discovery").also {
                it.setReferenceCounted(false)
                multicastLock = it
            }
        }
        if (!lock.isHeld) lock.acquire()
    }

    private fun releaseLock() {
        multicastLock?.takeIf { it.isHeld }?.release()
    }

    override fun onDestroy() {
        releaseLock()
        super.onDestroy()
    }

    companion object {
        private const val CHANNEL = "com.summationworks.smarttvremote/multicast"
    }
}
