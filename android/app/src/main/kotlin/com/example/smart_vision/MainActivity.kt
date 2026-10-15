package com.example.smart_vision

import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val frameExecutor = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.smartvision/video_frames",
        ).setMethodCallHandler { call, result ->
            if (call.method != "getFrame") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val path = call.argument<String>("path")
            val timeMs = call.argument<Number>("timeMs")?.toLong()
            val maxWidth = call.argument<Number>("maxWidth")?.toInt() ?: 640
            val quality = call.argument<Number>("quality")?.toInt() ?: 75
            if (path.isNullOrBlank() || timeMs == null || maxWidth <= 0 ||
                quality !in 0..100
            ) {
                result.error("invalid_arguments", "Invalid video frame request.", null)
                return@setMethodCallHandler
            }

            frameExecutor.execute {
                val retriever = MediaMetadataRetriever()
                try {
                    retriever.setDataSource(path)
                    val frame = retriever.getFrameAtTime(
                        timeMs * 1000,
                        MediaMetadataRetriever.OPTION_CLOSEST,
                    )
                    if (frame == null) {
                        runOnUiThread { result.success(null) }
                        return@execute
                    }
                    val resized = resizeFrame(frame, maxWidth)
                    val output = ByteArrayOutputStream()
                    resized.compress(Bitmap.CompressFormat.JPEG, quality, output)
                    if (resized !== frame) resized.recycle()
                    frame.recycle()
                    runOnUiThread { result.success(output.toByteArray()) }
                } catch (error: Exception) {
                    runOnUiThread {
                        result.error(
                            "video_frame_error",
                            "Could not extract video frame: ${error.message}",
                            null,
                        )
                    }
                } finally {
                    retriever.release()
                }
            }
        }
    }

    private fun resizeFrame(frame: Bitmap, maxWidth: Int): Bitmap {
        if (frame.width <= maxWidth) return frame
        val maxHeight = (frame.height * maxWidth.toFloat() / frame.width).toInt()
        return Bitmap.createScaledBitmap(frame, maxWidth, maxHeight, true)
    }

    override fun onDestroy() {
        frameExecutor.shutdown()
        super.onDestroy()
    }
}
