package com.finora.finora

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Build
import android.os.Bundle
import android.view.Display
import android.view.WindowManager

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.finora.display/refresh_rate"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestSmoothDisplay()
    }

    override fun onPostResume() {
        super.onPostResume()
        requestSmoothDisplay()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enable120Hz" -> {
                    val appliedRate = requestSmoothDisplay()
                    result.success(appliedRate)
                }
                "getRefreshRate" -> {
                    val rate = getActiveRefreshRate()
                    result.success(rate)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        requestSmoothDisplay()
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        requestSmoothDisplay()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) requestSmoothDisplay()
    }

    @Suppress("DEPRECATION")
    private fun getActiveRefreshRate(): Float {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val display = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                this.display ?: windowManager.defaultDisplay
            } else {
                windowManager.defaultDisplay
            }
            display?.mode?.refreshRate ?: 60.0f
        } else {
            60.0f
        }
    }

    @Suppress("DEPRECATION")
    private fun requestSmoothDisplay(): Float {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return 60.0f
        try {
            val display = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                this.display ?: windowManager.defaultDisplay
            } else {
                windowManager.defaultDisplay
            } ?: return 60.0f

            val currentMode = display.mode
            val modes = display.supportedModes

            // Find best mode with highest refresh rate up to 144Hz (preferring 120Hz)
            var bestMode: Display.Mode? = null
            var maxRate = currentMode.refreshRate

            for (m in modes) {
                if (m.physicalWidth == currentMode.physicalWidth && m.physicalHeight == currentMode.physicalHeight) {
                    if (m.refreshRate > maxRate && m.refreshRate <= 144.5f) {
                        maxRate = m.refreshRate
                        bestMode = m
                    }
                }
            }

            if (bestMode != null) {
                val params = window.attributes
                params.preferredDisplayModeId = bestMode.modeId
                params.preferredRefreshRate = bestMode.refreshRate
                window.attributes = params
                return bestMode.refreshRate
            } else {
                val params = window.attributes
                params.preferredRefreshRate = maxRate
                window.attributes = params
                return maxRate
            }
        } catch (e: Exception) {
            return 60.0f
        }
    }
}
