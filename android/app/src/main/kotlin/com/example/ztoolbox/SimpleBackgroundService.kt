package com.example.ztoolbox

import android.app.Service
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.os.IBinder

import android.widget.Toast
import kotlinx.coroutines.*
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
import java.util.zip.GZIPInputStream
import org.json.JSONObject

/**
 * 后台数据获取服务
 * 用于在不启动前台应用的情况下获取云剪贴板数据
 */
class SimpleBackgroundService : Service() {
    
    companion object {
        private const val API_URL = "https://api.txttool.cn/netcut/note/info/"
        
        fun startDataFetch(context: Context) {
            val intent = Intent(context, SimpleBackgroundService::class.java)
            context.startService(intent)
        }
    }
    
    private val serviceScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        serviceScope.launch {
            try {
                val result = fetchDataWithRetry()
                if (result != null) {
                    copyToSystemClipboard(result)
                    showToast("云剪贴板已刷新并复制")
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
     * 带重试机制的数据获取
     */
    private suspend fun fetchDataWithRetry(maxRetries: Int = 3): String? {
        repeat(maxRetries) { attempt ->
            val result = fetchDataWithHttpURLConnection()
            if (result != null) {
                return result
            }
            
            // 如果不是最后一次尝试，等待一段时间后重试
            if (attempt < maxRetries - 1) {
                delay(2000)
            }
        }
        
        showToast("多次尝试后仍无法获取数据")
        return null
    }
    
    /**
     * 使用HttpURLConnection获取数据
     */
    private suspend fun fetchDataWithHttpURLConnection(): String? = withContext(Dispatchers.IO) {
        try {
            val url = URL(API_URL)
            val connection = url.openConnection() as HttpURLConnection
            
            // 设置请求方法和属性
            connection.requestMethod = "POST"
            connection.doOutput = true
            connection.doInput = true
            connection.connectTimeout = 10000
            connection.readTimeout = 10000
            
            // 设置请求头 - 完全匹配Flutter版本
            connection.setRequestProperty("Accept", "application/json, text/javascript, */*; q=0.01")
            connection.setRequestProperty("Accept-Encoding", "gzip, deflate, br, zstd")
            connection.setRequestProperty("Accept-Language", "zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6")
            connection.setRequestProperty("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8")
            connection.setRequestProperty("Origin", "https://netcut.cn")
            connection.setRequestProperty("Referer", "https://netcut.cn/")
            connection.setRequestProperty("Sec-Ch-Ua", "\"Chromium\";v=\"140\", \"Not=A?Brand\";v=\"24\", \"Microsoft Edge\";v=\"140\"")
            connection.setRequestProperty("Sec-Ch-Ua-Mobile", "?0")
            connection.setRequestProperty("Sec-Ch-Ua-Platform", "\"Windows\"")
            connection.setRequestProperty("Sec-Fetch-Dest", "empty")
            connection.setRequestProperty("Sec-Fetch-Mode", "cors")
            connection.setRequestProperty("Sec-Fetch-Site", "cross-site")
            connection.setRequestProperty("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36 Edg/140.0.0.0")
            
            // 构建POST数据
            val postData = "note_name=${URLEncoder.encode("1j4i6jp0n", "UTF-8")}&note_pwd=${URLEncoder.encode("1234", "UTF-8")}"
            
            // 发送POST数据
            val outputWriter = OutputStreamWriter(connection.outputStream)
            outputWriter.write(postData)
            outputWriter.flush()
            outputWriter.close()
            
            val responseCode = connection.responseCode
            
            if (responseCode == HttpURLConnection.HTTP_OK) {
                // 读取响应，处理可能的gzip压缩
                val inputStream = connection.inputStream
                val encoding = connection.contentEncoding
                
                val reader = if (encoding != null && encoding.equals("gzip", ignoreCase = true)) {
                    BufferedReader(InputStreamReader(java.util.zip.GZIPInputStream(inputStream), "UTF-8"))
                } else {
                    BufferedReader(InputStreamReader(inputStream, "UTF-8"))
                }
                
                val response = StringBuilder()
                var line: String?
                
                while (reader.readLine().also { line = it } != null) {
                    response.append(line)
                }
                reader.close()
                
                val responseBody = response.toString()
                
                // 解析JSON
                val jsonObject = JSONObject(responseBody)
                val status = jsonObject.getInt("status")
                
                if (status == 1) {
                    val data = jsonObject.getJSONObject("data")
                    val noteContent = data.getString("note_content")
                    return@withContext noteContent
                } else {
                    val errorMessage = jsonObject.optString("error", "未知错误")
                    
                    // 根据错误类型返回不同的提示
                    when {
                        errorMessage.contains("服务器负载过高") -> {
                            showToast("服务器繁忙，请稍后重试")
                        }
                        errorMessage.contains("失效") -> {
                            showToast("访问凭证已失效")
                        }
                        else -> {
                            showToast("获取数据失败: $errorMessage")
                        }
                    }
                    return@withContext null
                }
            }
            
            connection.disconnect()
        } catch (e: Exception) {
            // 网络请求异常，静默处理
        }
        return@withContext null
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