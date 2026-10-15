package com.quranapp.quran_app

import android.content.Intent
import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// AudioServiceActivity keeps the Flutter engine shared with the background audio service.
class MainActivity : AudioServiceActivity() {
    private var pending: MethodChannel.Result? = null
    private var preview: Ringtone? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Notification sounds: the phone's own sound picker, and previews.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "siraj/sounds").setMethodCallHandler { call, result ->
            when (call.method) {
                "pick" -> {
                    pending?.success(null)
                    pending = result
                    val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
                        putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE,
                            RingtoneManager.TYPE_NOTIFICATION or RingtoneManager.TYPE_ALARM)
                        putExtra(RingtoneManager.EXTRA_RINGTONE_TITLE, call.argument<String>("title"))
                        putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, false)
                        putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
                        call.argument<String>("current")?.let {
                            putExtra(RingtoneManager.EXTRA_RINGTONE_EXISTING_URI, Uri.parse(it))
                        }
                    }
                    startActivityForResult(intent, PICK_SOUND)
                }
                "preview" -> {
                    stopPreview()
                    val uri = Uri.parse(call.argument<String>("uri"))
                    preview = RingtoneManager.getRingtone(this, uri)?.apply {
                        audioAttributes = AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .build()
                        play()
                    }
                    result.success(preview != null)
                }
                "stop" -> {
                    stopPreview()
                    result.success(null)
                }
                "title" -> {
                    val uri = Uri.parse(call.argument<String>("uri"))
                    result.success(RingtoneManager.getRingtone(this, uri)?.getTitle(this))
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun stopPreview() {
        preview?.stop()
        preview = null
    }

    @Deprecated("Ringtone picker has no Activity Result API equivalent in FlutterActivity")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PICK_SOUND) return
        val result = pending ?: return
        pending = null
        if (resultCode != RESULT_OK) return result.success(null)
        val uri: Uri? = if (Build.VERSION.SDK_INT >= 33) {
            data?.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI, Uri::class.java)
        } else {
            @Suppress("DEPRECATION")
            data?.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
        }
        if (uri == null) return result.success(null)
        val title = RingtoneManager.getRingtone(this, uri)?.getTitle(this) ?: "Phone sound"
        result.success(mapOf("uri" to uri.toString(), "title" to title))
    }

    override fun onDestroy() {
        stopPreview()
        super.onDestroy()
    }

    companion object {
        private const val PICK_SOUND = 4107
    }
}
