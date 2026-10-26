package com.lucentdread.stash_android

import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.app.RemoteAction
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.res.Configuration
import android.graphics.drawable.Icon
import android.os.Build
import android.os.Bundle
import android.util.Rational
import android.view.WindowManager
import androidx.core.content.FileProvider
import androidx.lifecycle.Lifecycle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/// Native side of lib/services/system_bridge.dart.
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null

    // Picture in picture, as configured by the player.
    private var pipEnabled = false
    private var pipPlaying = false
    private var pipAspect = Rational(16, 9)
    private var pipPlayLabel = "Play"
    private var pipPauseLabel = "Pause"

    private val pipReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            channel?.invokeMethod("pipPlayPause", null)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        // Applied before the first frame so the content never shows in
        // recent apps; same preference as AppState.hideInRecents.
        val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        setSecure(prefs.getBoolean("flutter.hide_recents", true))
        super.onCreate(savedInstanceState)
        val filter = IntentFilter(ACTION_PLAY_PAUSE)
        if (Build.VERSION.SDK_INT >= 33) {
            registerReceiver(pipReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(pipReceiver, filter)
        }
    }

    override fun onDestroy() {
        unregisterReceiver(pipReceiver)
        super.onDestroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "stash/system").apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "setSecure" -> {
                        setSecure(call.arguments as Boolean)
                        result.success(null)
                    }
                    "setPip" -> {
                        pipEnabled = call.argument<Boolean>("enabled") ?: false
                        pipPlaying = call.argument<Boolean>("playing") ?: false
                        val w = call.argument<Int>("width") ?: 16
                        val h = call.argument<Int>("height") ?: 9
                        pipPlayLabel = call.argument<String>("playLabel") ?: pipPlayLabel
                        pipPauseLabel = call.argument<String>("pauseLabel") ?: pipPauseLabel
                        pipAspect = clampAspect(w, h)
                        updatePipParams()
                        result.success(null)
                    }
                    "installApk" -> {
                        try {
                            installApk(call.arguments as String)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("install", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    private fun setSecure(secure: Boolean) {
        if (secure) {
            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
    }

    /// Android only accepts ratios between 1:2.39 and 2.39:1.
    private fun clampAspect(w: Int, h: Int): Rational {
        if (w <= 0 || h <= 0) return Rational(16, 9)
        val r = w.toDouble() / h
        return when {
            r > 2.39 -> Rational(239, 100)
            r < 1 / 2.39 -> Rational(100, 239)
            else -> Rational(w, h)
        }
    }

    private fun pipParams(): PictureInPictureParams? {
        if (Build.VERSION.SDK_INT < 26) return null
        val intent = PendingIntent.getBroadcast(
            this,
            0,
            Intent(ACTION_PLAY_PAUSE).setPackage(packageName),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val action = RemoteAction(
            Icon.createWithResource(
                this,
                if (pipPlaying) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play,
            ),
            if (pipPlaying) pipPauseLabel else pipPlayLabel,
            if (pipPlaying) pipPauseLabel else pipPlayLabel,
            intent,
        )
        val builder = PictureInPictureParams.Builder()
            .setAspectRatio(pipAspect)
            .setActions(listOf(action))
        if (Build.VERSION.SDK_INT >= 31) {
            // Android 12+: enters the small window smoothly on its own.
            builder.setAutoEnterEnabled(pipEnabled && pipPlaying)
            builder.setSeamlessResizeEnabled(true)
        }
        return builder.build()
    }

    private fun updatePipParams() {
        val params = pipParams() ?: return
        try {
            setPictureInPictureParams(params)
        } catch (_: IllegalStateException) {
            // Picture in picture disabled for this app in the settings.
        }
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        // Android 8 to 11: no automatic entry, do it on "home"/"recents".
        if (Build.VERSION.SDK_INT in 26..30 && pipEnabled && pipPlaying) {
            try {
                enterPictureInPictureMode(pipParams()!!)
            } catch (_: IllegalStateException) {
            }
        }
    }

    override fun onPictureInPictureModeChanged(active: Boolean, newConfig: Configuration) {
        super.onPictureInPictureModeChanged(active, newConfig)
        // Leaving the mode while stopped means the window was closed
        // (rather than expanded back to full screen).
        val closed = !active && lifecycle.currentState == Lifecycle.State.CREATED
        channel?.invokeMethod("pipChanged", mapOf("active" to active, "closed" to closed))
    }

    private fun installApk(path: String) {
        val uri = FileProvider.getUriForFile(this, "$packageName.updates", File(path))
        val intent = Intent(Intent.ACTION_VIEW)
            .setDataAndType(uri, "application/vnd.android.package-archive")
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    companion object {
        private const val ACTION_PLAY_PAUSE = "com.lucentdread.stash_android.PIP_PLAY_PAUSE"
    }
}
