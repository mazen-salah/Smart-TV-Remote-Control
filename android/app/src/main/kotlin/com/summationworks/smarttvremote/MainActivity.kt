package com.summationworks.smarttvremote

import android.content.Context
import android.media.VolumeProvider
import android.media.session.MediaSession
import android.media.session.PlaybackState
import android.net.wifi.WifiManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var multicastLock: WifiManager.MulticastLock? = null
    private var mediaSession: MediaSession? = null
    private var volumeKeysChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MULTICAST_CHANNEL)
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

        volumeKeysChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VOLUME_KEYS_CHANNEL)
            .apply {
                setMethodCallHandler { call, result ->
                    when (call.method) {
                        "start" -> {
                            startVolumeKeys()
                            result.success(null)
                        }
                        "stop" -> {
                            stopVolumeKeys()
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
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

    /**
     * Routes the phone's volume keys into the app instead of the phone's own
     * volume.
     *
     * A playing media session with a remote volume provider takes ownership of
     * the volume keys: the system neither changes its own volume nor shows the
     * volume panel, and every press arrives in [onAdjustVolume], which forwards
     * it to Dart. Nothing is played; the session exists only for that.
     *
     * The session is deliberately process-local and never started from the
     * background: leaving the remote screen releases it again, so the keys go
     * back to the phone.
     */
    private fun startVolumeKeys() {
        if (mediaSession != null) return
        val channel = volumeKeysChannel ?: return

        val provider = object : VolumeProvider(VOLUME_CONTROL_RELATIVE, MAX_VOLUME, MAX_VOLUME / 2) {
            override fun onAdjustVolume(direction: Int) {
                if (direction == 0) return
                channel.invokeMethod("onVolumeKey", if (direction > 0) "up" else "down")
            }
        }

        val session = MediaSession(this, "smart-tv-remote-volume")
        // The callback is what gives the session a handler to dispatch volume
        // changes through: `MediaSession.postToCallback` drops the adjustment
        // when there is none, so without this the provider never fires.
        session.setCallback(object : MediaSession.Callback() {})
        session.setPlaybackState(
            PlaybackState.Builder()
                .setActions(PlaybackState.ACTION_PLAY_PAUSE)
                .setState(PlaybackState.STATE_PLAYING, PlaybackState.PLAYBACK_POSITION_UNKNOWN, 1.0f)
                .build(),
        )
        session.setPlaybackToRemote(provider)
        session.isActive = true
        mediaSession = session
    }

    private fun stopVolumeKeys() {
        mediaSession?.isActive = false
        mediaSession?.release()
        mediaSession = null
    }

    override fun onDestroy() {
        releaseLock()
        stopVolumeKeys()
        super.onDestroy()
    }

    companion object {
        private const val MULTICAST_CHANNEL = "com.summationworks.smarttvremote/multicast"
        private const val VOLUME_KEYS_CHANNEL = "com.summationworks.smarttvremote/volume_keys"
        private const val MAX_VOLUME = 100
    }
}
