package com.zethyst.arth

import android.content.Context
import android.os.Build
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // A device id that survives reinstalling the app (the free AI allowance
        // is per phone). ANDROID_ID is per app signing key, user and device;
        // it changes only on a factory reset.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "arth/device").setMethodCallHandler { call, result ->
            when (call.method) {
                "stableId" -> result.success(Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID))
                else -> result.notImplemented()
            }
        }
        // The texture under a page being turned (PageHaptics in feel.dart).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "arth/haptics").setMethodCallHandler { call, result ->
            when (call.method) {
                "pageTicks" -> result.success(tick != null)
                "pageTick" -> {
                    pageTick((call.argument<Double>("scale") ?: 0.5).toFloat())
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private val vibrator: Vibrator? by lazy {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            (getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager)?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }

    private val tick: Int? by lazy { tickPrimitive() }

    // The softest tick this phone plays crisply, or null: phones without
    // haptic primitives (older or cheaper motors) would only buzz.
    private fun tickPrimitive(): Int? {
        val v = vibrator ?: return null
        if (!v.hasVibrator()) return null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            v.areAllPrimitivesSupported(VibrationEffect.Composition.PRIMITIVE_LOW_TICK)) {
            return VibrationEffect.Composition.PRIMITIVE_LOW_TICK
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R &&
            v.areAllPrimitivesSupported(VibrationEffect.Composition.PRIMITIVE_TICK)) {
            return VibrationEffect.Composition.PRIMITIVE_TICK
        }
        return null
    }

    private fun pageTick(scale: Float) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return
        val v = vibrator ?: return
        val primitive = tick ?: return
        val effect = VibrationEffect.startComposition().addPrimitive(primitive, scale.coerceIn(0f, 1f)).compose()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // As touch feedback, so the system's "touch vibration" setting applies.
            v.vibrate(effect, VibrationAttributes.createForUsage(VibrationAttributes.USAGE_TOUCH))
        } else {
            v.vibrate(effect)
        }
    }
}
