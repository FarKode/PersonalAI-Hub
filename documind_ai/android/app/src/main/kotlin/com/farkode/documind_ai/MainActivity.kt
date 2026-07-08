package com.farkode.documind_ai

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle

class MainActivity : FlutterActivity() {
    // Override onBackPressed so that pressing Back on the root screen
    // moves the task to the background (minimize) instead of finishing
    // (destroying) the Activity. This is the definitive fix for the
    // black screen on warm start: the Activity is never destroyed,
    // so Flutter never has to re-initialize from scratch.
    @Suppress("DEPRECATION")
    override fun onBackPressed() {
        moveTaskToBack(true)
    }
}
