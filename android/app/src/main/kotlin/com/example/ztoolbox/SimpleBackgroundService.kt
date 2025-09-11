package com.example.ztoolbox

import android.app.Service
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.IBinder
import android.util.Base64
import android.widget.Toast
import kotlinx.coroutines.*
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest
import javax.crypto.Cipher
import javax.crypto.spec.IvParameterSpec
import javax.crypto.spec.SecretKeySpec

/**
 * 云剪贴板后台服务
 * 基于textdb.online的加密云剪贴板服务
 */
class SimpleBackgroundService : Service() {
    
    companion object {
        private const val BASE_URL = "https://textdb.online"
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val KEY_USER_ID = "flutter.textdb_use_id"
        private const val KEY_ENCRYPTION_KEY = "flutter.encryption_key"
        
        fun startDataFetch(context: Context) {
            val intent = Intent(context, SimpleBackgroundService::class.java)
            context.startService(intent)
        }
    }
    
    private val serviceScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private lateinit var sharedPrefs: SharedPreferences
    
    override fun onCreate() {
        super.onCreate()
        sharedPrefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        serviceScope.launch {
            try {
                showToast("正在获取云剪贴板数据...")
                
                val result = fetchAndDecryptData()
                if (result != null) {
                    copyToSystemClipboard(result)
                    val preview = if (result.length > 20) "${result.take(20)}..." else result
                    showToast("云剪贴板已刷新: $preview")
                } else {
                    showToast("获取数据失败，请检查网络和密钥设置")
                }
            } catch (e: Exception) {
                showToast("获取数据时发生错误: ${e.message}")
            } finally {
                stopSelf()
            }
        }
        
        return START_NOT_STICKY
    }
    
    /**
     * 获取并解密云端数据（带重试机制）
     */
    private suspend fun fetchAndDecryptData(): String? = withContext(Dispatchers.IO) {
        try {
            // 检查加密密钥
            val encryptionKey = sharedPrefs.getString(KEY_ENCRYPTION_KEY, null)
                ?: sharedPrefs.getString("encryption_key", null)
            
            if (encryptionKey.isNullOrEmpty()) {
                showToast("未设置加密密钥，请先在应用中设置")
                return@withContext null
            }
            
            // 获取用户ID
            val userId = getUserIdFromPreferences()
            if (userId == null) {
                showToast("未设置用户ID，请先在应用中设置")
                return@withContext null
            }
            
            return@withContext fetchAndDecryptWithUserIdAndKey(userId, encryptionKey)
        } catch (e: Exception) {
            showToast("处理数据时出错：${e.message}")
            return@withContext null
        }
    }
    
    /**
     * 从SharedPreferences获取用户ID
     */
    private fun getUserIdFromPreferences(): String? {
        return sharedPrefs.getString(KEY_USER_ID, null)
            ?: sharedPrefs.getString("textdb_use_id", null)
    }


    
    /**
     * 使用指定的用户ID和密钥获取和解密数据
     */
    private suspend fun fetchAndDecryptWithUserIdAndKey(userId: String, encryptionKey: String): String? {
        val encryptedData = fetchDataWithRetry(userId)
        return if (encryptedData.isNullOrEmpty()) null else decryptData(encryptedData, encryptionKey)
    }
    
    /**
     * 带重试机制的数据获取
     */
    private suspend fun fetchDataWithRetry(userId: String, maxRetries: Int = 3): String? {
        repeat(maxRetries) { attempt ->
            val result = fetchDataFromCloud(userId)
            if (result != null) return result
            
            if (attempt < maxRetries - 1) {
                delay(1000)
            }
        }
        
        showToast("网络连接失败，请检查网络")
        return null
    }
    
    /**
     * 从textdb.online获取数据
     */
    private suspend fun fetchDataFromCloud(userId: String): String? = withContext(Dispatchers.IO) {
        try {
            val url = URL("$BASE_URL/$userId")
            val connection = url.openConnection() as HttpURLConnection
            
            connection.requestMethod = "GET"
            connection.connectTimeout = 10000
            connection.readTimeout = 10000
            
            if (connection.responseCode == HttpURLConnection.HTTP_OK) {
                val reader = BufferedReader(InputStreamReader(connection.inputStream))
                val response = StringBuilder()
                var line: String?
                
                while (reader.readLine().also { line = it } != null) {
                    response.append(line)
                }
                reader.close()
                
                val rawData = response.toString().trim()
                
                return@withContext try {
                    base64UrlSafeDecode(rawData)
                } catch (e: Exception) {
                    rawData
                }
            }
            
            connection.disconnect()
        } catch (e: Exception) {
            // 网络异常，静默处理
        }
        return@withContext null
    }
    
    /**
     * Base64 URL安全解码
     */
    private fun base64UrlSafeDecode(input: String): String {
        // 恢复标准Base64格式
        var base64 = input.replace('-', '+').replace('_', '/')
        
        // 补充填充字符
        while (base64.length % 4 != 0) {
            base64 += '='
        }
        
        val bytes = Base64.decode(base64, Base64.DEFAULT)
        return String(bytes)
    }
    
    /**
     * 解密数据
     */
    private fun decryptData(encryptedText: String, key: String): String? {
        try {
            if (encryptedText.isEmpty()) return ""
            
            val cleanedText = encryptedText.trim().replace(Regex("\\s+"), "")
            val parts = cleanedText.split(":")
            
            if (parts.size != 2 || !isValidBase64(parts[0]) || !isValidBase64(parts[1])) {
                throw Exception("数据格式错误")
            }
            
            val iv = Base64.decode(parts[0], Base64.DEFAULT)
            val encryptedData = Base64.decode(parts[1], Base64.DEFAULT)
            
            val keyBytes = key.toByteArray(Charsets.UTF_8)
            val keyHash = MessageDigest.getInstance("SHA-256").digest(keyBytes)
            
            val cipher = Cipher.getInstance("AES/CBC/PKCS5Padding")
            cipher.init(Cipher.DECRYPT_MODE, SecretKeySpec(keyHash, "AES"), IvParameterSpec(iv))
            
            return String(cipher.doFinal(encryptedData), Charsets.UTF_8)
        } catch (e: Exception) {
            showToast("解密失败：${e.message}")
            return null
        }
    }
    
    /**
     * 验证Base64格式
     */
    private fun isValidBase64(str: String): Boolean {
        if (str.isEmpty()) return false
        
        // Base64字符集检查
        val base64Pattern = Regex("^[A-Za-z0-9+/]*={0,2}$")
        if (!base64Pattern.matches(str)) return false
        
        // 长度检查
        return str.length % 4 == 0
    }
    
    private fun copyToSystemClipboard(text: String) {
        try {
            val clipboardManager = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
            val clipData = ClipData.newPlainText("云剪贴板", text)
            clipboardManager.setPrimaryClip(clipData)
        } catch (e: Exception) {
            // 复制失败，静默处理
        }
    }
    
    private fun showToast(message: String) {
        CoroutineScope(Dispatchers.Main).launch {
            Toast.makeText(this@SimpleBackgroundService, message, Toast.LENGTH_SHORT).show()
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        serviceScope.cancel()
    }
}