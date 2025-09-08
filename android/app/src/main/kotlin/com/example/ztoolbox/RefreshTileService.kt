package com.example.ztoolbox

import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.service.quicksettings.TileService
import android.service.quicksettings.Tile


/**
 * 下拉控制栏快捷方式服务
 * 用于在Android下拉控制栏中添加刷新功能的快捷方式
 */
class RefreshTileService : TileService() {



    override fun onStartListening() {
        super.onStartListening()
        updateTileState()
    }

    override fun onStopListening() {
        super.onStopListening()
    }

    override fun onClick() {
        super.onClick()
        
        try {
            // 更新磁贴状态为活跃，表示正在处理
            updateTileState(isActive = true)
            
            // 启动后台服务获取数据
            SimpleBackgroundService.startDataFetch(this)
            
            // 延迟恢复磁贴状态
            android.os.Handler(mainLooper).postDelayed({
                updateTileState(isActive = false)
            }, 3000) // 3秒后恢复非活跃状态
            
        } catch (e: Exception) {
            updateTileState(isActive = false)
        }
    }

    private fun updateTileState(isActive: Boolean = false) {
        qsTile?.apply {
            label = if (isActive) "正在刷新..." else "云剪贴板刷新"
            contentDescription = if (isActive) "正在刷新云剪贴板内容" else "点击刷新云剪贴板内容"
            state = if (isActive) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
            updateTile()
        }
    }
}