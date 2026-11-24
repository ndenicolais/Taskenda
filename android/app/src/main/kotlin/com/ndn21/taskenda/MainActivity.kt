package com.ndn21.taskenda

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// Read by SharedTextLaunchHandler (lib/core/routing/shared_text_launch_handler.dart).
private const val SHARE_CHANNEL = "com.ndn21.taskenda/share"

class MainActivity : FlutterActivity() {

    private var shareChannel: MethodChannel? = null

    /** Text shared from another app that launched the activity, until Dart takes it. */
    private var initialShare: Map<String, String>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        // Only on a real launch: a recreated activity keeps the same intent,
        // which would offer the same text again.
        if (savedInstanceState == null) initialShare = sharedText(intent)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        shareChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "takeInitialShare" -> {
                        result.success(initialShare)
                        initialShare = null
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    // Text shared while the activity is already open (singleTop).
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        sharedText(intent)?.let { shareChannel?.invokeMethod("shared", it) }
    }

    /** Subject and text of an ACTION_SEND of text ("Share" sheet), or null. */
    private fun sharedText(intent: Intent?): Map<String, String>? {
        if (intent?.action != Intent.ACTION_SEND) return null
        if (intent.type?.startsWith("text/") != true) return null
        val text = intent.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString().orEmpty()
        val subject = intent.getStringExtra(Intent.EXTRA_SUBJECT).orEmpty()
        if (text.isBlank() && subject.isBlank()) return null
        return mapOf("subject" to subject, "text" to text)
    }
}
