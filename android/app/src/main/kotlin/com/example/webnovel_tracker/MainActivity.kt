package com.example.webnovel_tracker

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Receives URLs shared into the app from the Android share sheet.
 *
 * Replaces the receive_sharing_intent plugin: we only need shared text/URLs,
 * so this reads Intent.EXTRA_TEXT directly and bridges it to Dart over two
 * channels — a MethodChannel for the cold-start link and an EventChannel for
 * links that arrive while the app is already running.
 */
class MainActivity : FlutterActivity() {
    private val methodChannelName = "app.webnovel_tracker/share"
    private val eventChannelName = "app.webnovel_tracker/share/events"

    private var initialLink: String? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // The intent that launched the activity (cold start), if it was a share.
        initialLink = extractSharedUrl(intent)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialLink" -> result.success(initialLink)
                    "reset" -> {
                        initialLink = null
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
    }

    // App already running (launchMode=singleTop): a fresh share lands here.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        extractSharedUrl(intent)?.let { url -> eventSink?.success(url) }
    }

    /** Pulls a URL out of a SEND (text) or VIEW intent; null if there's none. */
    private fun extractSharedUrl(intent: Intent?): String? {
        if (intent == null) return null
        return when (intent.action) {
            Intent.ACTION_SEND ->
                if (intent.type?.startsWith("text") == true) {
                    intent.getStringExtra(Intent.EXTRA_TEXT)
                } else {
                    null
                }
            Intent.ACTION_VIEW -> intent.dataString
            else -> null
        }
    }
}
