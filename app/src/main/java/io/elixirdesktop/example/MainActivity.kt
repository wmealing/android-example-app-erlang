package io.elixirdesktop.example

import android.app.Activity
import android.os.Bundle
import android.system.Os
import android.view.KeyEvent
import android.view.View
import io.elixirdesktop.example.databinding.ActivityMainBinding
import java.io.*
import java.util.*
import android.webkit.WebView

import android.webkit.WebViewClient




class MainActivity : Activity() {
    private lateinit var binding: ActivityMainBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)
        binding.browser.webViewClient = object : WebViewClient() {
            override fun onPageFinished(view: WebView, url: String) {
                if (binding.browser.visibility != View.VISIBLE) {
                    binding.browser.visibility = View.VISIBLE
                    binding.splash.visibility = View.GONE
                    reportFullyDrawn()
                }
            }

            @Deprecated("Deprecated in Java")
            override fun onReceivedError(view: WebView, errorCode: Int, description: String, failingUrl: String) {
                // If the connection was refused, it's likely the server hasn't started yet.
                // Retry loading the page after 500ms.
                if (errorCode == ERROR_CONNECT || errorCode == ERROR_HOST_LOOKUP) {
                    if (failingUrl.contains("127.0.0.1:8080")) {
                        view.postDelayed({ view.reload() }, 500)
                    }
                }
            }
        }

        if (bridge != null) {
            // This happens on re-creation of the activity e.g. after rotating the screen
            bridge!!.setWebView(binding.browser)
        } else {
            // This happens only on the first time when starting the app
            bridge = Bridge(applicationContext, binding.browser)
        }
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent): Boolean {
        if (event.action == KeyEvent.ACTION_DOWN) {
            when (keyCode) {
                KeyEvent.KEYCODE_BACK -> {
                    if (binding.browser.canGoBack()) {
                        binding.browser.goBack()
                    } else {
                        finish()
                    }
                    return true
                }
            }
        }
        return super.onKeyDown(keyCode, event)
    }

    companion object {
        var bridge: Bridge? = null
    }
}
