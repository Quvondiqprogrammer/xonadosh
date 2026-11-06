package com.zargo.customer

import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            enableEdgeToEdge()
        } catch (_: Throwable) {
            // Guard for older OEM ROMs / MIUI on Android 9/10/Redmi Note 8
        }
        try {
            WindowCompat.setDecorFitsSystemWindows(window, false)
        } catch (_: Throwable) {}
    }
}
