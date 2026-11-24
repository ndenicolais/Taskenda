package com.ndn21.taskenda

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// Read by SharedTextLaunchHandler (lib/core/routing/shared_text_launch_handler.dart).
private const val SHARE_CHANNEL = "com.ndn21.taskenda/share"

/** Calendar files bigger than this are ignored (a year of events is far smaller). */
private const val MAX_ICS_BYTES = 5 * 1024 * 1024

private val CALENDAR_MIME_TYPES = setOf("text/calendar", "text/x-vcalendar", "application/ics")

class MainActivity : FlutterActivity() {

    private var shareChannel: MethodChannel? = null

    /** Text or calendar shared from another app that launched the activity, until Dart takes it. */
    private var initialShare: Map<String, String>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        // Only on a real launch: a recreated activity keeps the same intent,
        // which would offer the same text again.
        if (savedInstanceState == null) initialShare = sharedContent(intent)
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

    // Shared while the activity is already open (singleTop).
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        sharedContent(intent)?.let { shareChannel?.invokeMethod("shared", it) }
    }

    private fun sharedContent(intent: Intent?): Map<String, String>? =
        sharedCalendar(intent) ?: sharedText(intent)

    /** Subject and text of an ACTION_SEND of text ("Share" sheet), or null. */
    private fun sharedText(intent: Intent?): Map<String, String>? {
        if (intent?.action != Intent.ACTION_SEND) return null
        if (intent.type?.startsWith("text/") != true) return null
        val text = intent.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString().orEmpty()
        val subject = intent.getStringExtra(Intent.EXTRA_SUBJECT).orEmpty()
        if (text.isBlank() && subject.isBlank()) return null
        return mapOf("subject" to subject, "text" to text)
    }

    /** Content of an .ics file shared (ACTION_SEND) or opened (ACTION_VIEW), or null. */
    private fun sharedCalendar(intent: Intent?): Map<String, String>? {
        if (intent == null) return null
        val uri = when (intent.action) {
            Intent.ACTION_VIEW -> intent.data
            Intent.ACTION_SEND -> streamExtra(intent)
            else -> null
        } ?: return null
        val type = (intent.type ?: runCatching { contentResolver.getType(uri) }.getOrNull())
            ?.substringBefore(';')?.trim()?.lowercase()
        val isIcsName = uri.lastPathSegment?.lowercase()?.endsWith(".ics") == true
        if (type !in CALENDAR_MIME_TYPES && !isIcsName) return null
        val ics = readText(uri) ?: return null
        if (!ics.contains("BEGIN:VCALENDAR", ignoreCase = true)) return null
        return mapOf("ics" to ics)
    }

    private fun streamExtra(intent: Intent): Uri? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(Intent.EXTRA_STREAM)
        }

    /** UTF-8 text of [uri], or null if unreadable or over [MAX_ICS_BYTES]. */
    private fun readText(uri: Uri): String? = runCatching {
        contentResolver.openInputStream(uri)?.use { input ->
            val bytes = input.readNBytesCompat(MAX_ICS_BYTES + 1)
            if (bytes.size > MAX_ICS_BYTES) null else String(bytes, Charsets.UTF_8)
        }
    }.getOrNull()

    private fun java.io.InputStream.readNBytesCompat(limit: Int): ByteArray {
        val out = java.io.ByteArrayOutputStream()
        val buffer = ByteArray(8192)
        while (out.size() < limit) {
            val read = read(buffer, 0, minOf(buffer.size, limit - out.size()))
            if (read < 0) break
            out.write(buffer, 0, read)
        }
        return out.toByteArray()
    }
}
