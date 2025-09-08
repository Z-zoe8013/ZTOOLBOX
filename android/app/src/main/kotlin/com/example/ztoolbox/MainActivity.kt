package com.example.ztoolbox

import android.content.Intent
import android.os.Bundle

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.ztoolbox/tile"
    private var methodChannel: MethodChannel? = null



    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getTileAction" -> {
                    val action = intent?.getStringExtra("action")
                    result.success(action)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        // 在onResume中也检查Intent，确保不会错过
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        val action = intent?.getStringExtra("action")
        
        if (action == "refresh") {
            // 延迟执行，确保Flutter已经准备好
            android.os.Handler(mainLooper).postDelayed({
                methodChannel?.invokeMethod("performRefresh", null, object : MethodChannel.Result {
                    override fun success(result: Any?) {
                        // 调用成功
                    }
                    
                    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                        // 调用失败
                    }
                    
                    override fun notImplemented() {
                        // 方法未实现
                    }
                })
            }, 500)
        }
    }
}
