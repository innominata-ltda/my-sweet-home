package br.com.innominata.mysweethome

import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Rect
import android.os.Build
import android.os.CancellationSignal
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.PixelCopy
import android.view.ScrollCaptureCallback
import android.view.ScrollCaptureSession
import android.view.ScrollCaptureTarget
import android.view.View
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.function.Consumer
import kotlin.math.roundToInt

class MainActivity : FlutterActivity() {
    private val BATTERY_CHANNEL = "br.com.innominata.mysweethome/battery"
    private val SCROLL_CAPTURE_CHANNEL = "br.com.innominata.mysweethome/scroll_capture"
    private val APP_UPDATE_CHANNEL = "br.com.innominata.mysweethome/app_update"
    private var scrollCaptureChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BATTERY_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openBatteryOptimizationSettings") {
                try {
                    val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                    startActivity(intent)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("UNAVAILABLE", "Cannot open settings", null)
                }
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_UPDATE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkForUpdate" -> {
                    if (!isInstalledFromPlayStore()) {
                        result.success(
                            mapOf(
                                "updateAvailable" to false,
                                "installedFromPlayStore" to false,
                                "availableVersionCode" to null,
                                "availableVersionLabel" to null
                            )
                        )
                        return@setMethodCallHandler
                    }
                    try {
                        val appUpdateManager = com.google.android.play.core.appupdate.AppUpdateManagerFactory.create(this)
                        val appUpdateInfoTask = appUpdateManager.appUpdateInfo
                        appUpdateInfoTask.addOnSuccessListener { appUpdateInfo ->
                            val isAvailable = appUpdateInfo.updateAvailability() == com.google.android.play.core.install.model.UpdateAvailability.UPDATE_AVAILABLE
                            val response = mapOf(
                                "updateAvailable" to isAvailable,
                                "installedFromPlayStore" to true,
                                "availableVersionCode" to appUpdateInfo.availableVersionCode(),
                                "availableVersionLabel" to null
                            )
                            result.success(response)
                        }.addOnFailureListener { e ->
                            result.error("STORE_UNAVAILABLE", e.message ?: "Play Store unavailable", null)
                        }
                    } catch (e: Exception) {
                        result.error("STORE_UNAVAILABLE", e.message ?: "Play Store unavailable", null)
                    }
                }
                "openExternalUrl" -> {
                    val url = call.argument<String>("url")
                    if (url == null || !url.startsWith("https://")) {
                        result.error("INVALID_URL", "Only https:// URLs are supported", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val intent = Intent(Intent.ACTION_VIEW, android.net.Uri.parse(url))
                        startActivity(intent)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", e.message ?: "Cannot open URL", null)
                    }
                }
                "startUpdate" -> {
                    try {
                        val appUpdateManager = com.google.android.play.core.appupdate.AppUpdateManagerFactory.create(this)
                        val appUpdateInfoTask = appUpdateManager.appUpdateInfo
                        appUpdateInfoTask.addOnSuccessListener { appUpdateInfo ->
                            if (appUpdateInfo.isUpdateTypeAllowed(com.google.android.play.core.install.model.AppUpdateType.FLEXIBLE)) {
                                appUpdateManager.startUpdateFlowForResult(
                                    appUpdateInfo,
                                    com.google.android.play.core.install.model.AppUpdateType.FLEXIBLE,
                                    this,
                                    1001
                                )
                                result.success(null)
                            } else {
                                openPlayStore()
                                result.success(null)
                            }
                        }.addOnFailureListener {
                            openPlayStore()
                            result.success(null)
                        }
                    } catch (e: Exception) {
                        try {
                            openPlayStore()
                            result.success(null)
                        } catch (e2: Exception) {
                            result.error("UPDATE_FAILED", e2.message, null)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }

        scrollCaptureChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SCROLL_CAPTURE_CHANNEL
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            window?.decorView?.post {
                setupScrollCapture()
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.S)
    private fun setupScrollCapture() {
        val decorView = window?.decorView ?: return
        val callback = FlutterScrollCaptureCallback(decorView)
        decorView.setScrollCaptureCallback(callback)
    }

    private fun isInstalledFromPlayStore(): Boolean {
        return try {
            val installer = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                packageManager.getInstallSourceInfo(packageName).installingPackageName
            } else {
                @Suppress("DEPRECATION")
                packageManager.getInstallerPackageName(packageName)
            }
            installer == "com.android.vending"
        } catch (e: Exception) {
            false
        }
    }

    private fun openPlayStore() {
        try {
            val intent = Intent(Intent.ACTION_VIEW, android.net.Uri.parse("market://details?id=$packageName"))
            startActivity(intent)
        } catch (e: Exception) {
            val intent = Intent(Intent.ACTION_VIEW, android.net.Uri.parse("https://play.google.com/store/apps/details?id=$packageName"))
            startActivity(intent)
        }
    }

    @RequiresApi(Build.VERSION_CODES.S)
    private inner class FlutterScrollCaptureCallback(
        private val targetView: View
    ) : ScrollCaptureCallback {
        private val mainHandler = Handler(Looper.getMainLooper())
        private var initialOffsetLogical = 0.0
        private var devicePixelRatio = 1.0

        override fun onScrollCaptureSearch(
            signal: CancellationSignal,
            onReady: Consumer<Rect>
        ) {
            val channel = scrollCaptureChannel
            if (channel == null) {
                onReady.accept(Rect())
                return
            }

            mainHandler.post {
                channel.invokeMethod("getScrollMetrics", null, object : MethodChannel.Result {
                    override fun success(result: Any?) {
                        val map = result as? Map<*, *>
                        val scrollable = map?.get("scrollable") as? Boolean ?: false
                        if (!scrollable) {
                            onReady.accept(Rect())
                            return
                        }
                        initialOffsetLogical = (map?.get("offset") as? Number)?.toDouble() ?: 0.0
                        devicePixelRatio = (map?.get("devicePixelRatio") as? Number)?.toDouble()
                            ?: resources.displayMetrics.density.toDouble()

                        val topInset = (80 * devicePixelRatio).roundToInt()
                        val bottomInset = (88 * devicePixelRatio).roundToInt()
                        val height = targetView.height
                        val width = targetView.width
                        if (height > topInset + bottomInset && width > 0) {
                            onReady.accept(Rect(0, topInset, width, height - bottomInset))
                        } else {
                            onReady.accept(Rect(0, 0, width, height))
                        }
                    }

                    override fun error(code: String, msg: String?, details: Any?) {
                        onReady.accept(Rect())
                    }

                    override fun notImplemented() {
                        onReady.accept(Rect())
                    }
                })
            }
        }

        override fun onScrollCaptureStart(
            session: ScrollCaptureSession,
            signal: CancellationSignal,
            onReady: Runnable
        ) {
            onReady.run()
        }

        override fun onScrollCaptureImageRequest(
            session: ScrollCaptureSession,
            signal: CancellationSignal,
            captureArea: Rect,
            onComplete: Consumer<Rect>
        ) {
            val channel = scrollCaptureChannel
            if (channel == null) {
                onComplete.accept(Rect())
                return
            }

            val deltaLogical = captureArea.top / devicePixelRatio
            val targetLogical = initialOffsetLogical + deltaLogical

            mainHandler.post {
                channel.invokeMethod("scrollToOffset", targetLogical, object : MethodChannel.Result {
                    override fun success(result: Any?) {
                        mainHandler.postDelayed({
                            captureWindowSlice(session, captureArea, onComplete)
                        }, 32)
                    }

                    override fun error(code: String, msg: String?, details: Any?) {
                        onComplete.accept(Rect())
                    }

                    override fun notImplemented() {
                        onComplete.accept(Rect())
                    }
                })
            }
        }

        private fun captureWindowSlice(
            session: ScrollCaptureSession,
            captureArea: Rect,
            onComplete: Consumer<Rect>
        ) {
            val w = captureArea.width().coerceAtLeast(1)
            val h = captureArea.height().coerceAtLeast(1)
            val bounds = session.scrollBounds
            val srcRect = Rect(
                bounds.left,
                bounds.top,
                (bounds.left + w).coerceAtMost(targetView.width),
                (bounds.top + h).coerceAtMost(targetView.height)
            )
            if (srcRect.width() <= 0 || srcRect.height() <= 0) {
                onComplete.accept(Rect())
                return
            }

            val bitmap = Bitmap.createBitmap(srcRect.width(), srcRect.height(), Bitmap.Config.ARGB_8888)
            PixelCopy.request(
                window,
                srcRect,
                bitmap,
                { copyResult ->
                    if (copyResult == PixelCopy.SUCCESS) {
                        val canvas = session.surface.lockHardwareCanvas()
                        try {
                            canvas.drawBitmap(bitmap, 0f, 0f, null)
                        } finally {
                            session.surface.unlockCanvasAndPost(canvas)
                        }
                        onComplete.accept(Rect(captureArea.left, captureArea.top, captureArea.left + srcRect.width(), captureArea.top + srcRect.height()))
                    } else {
                        onComplete.accept(Rect())
                    }
                    bitmap.recycle()
                },
                mainHandler
            )
        }

        override fun onScrollCaptureEnd(onReady: Runnable) {
            val channel = scrollCaptureChannel
            if (channel != null) {
                mainHandler.post {
                    channel.invokeMethod("scrollToOffset", initialOffsetLogical, object : MethodChannel.Result {
                        override fun success(result: Any?) = onReady.run()
                        override fun error(code: String, msg: String?, details: Any?) = onReady.run()
                        override fun notImplemented() = onReady.run()
                    })
                }
            } else {
                onReady.run()
            }
        }
    }
}
