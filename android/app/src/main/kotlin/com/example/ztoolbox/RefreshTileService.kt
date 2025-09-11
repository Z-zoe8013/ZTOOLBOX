package com.example.ztoolbox

import android.content.Intent
import android.service.quicksettings.TileService
import android.service.quicksettings.Tile

/**
 * 云剪贴板快捷磁贴服务
 * 基于textdb.online的加密云剪贴板快捷方式
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
            // 更新磁贴状态为活跃
            updateTileState(isActive = true)
            
            // 直接使用后台服务获取数据
            SimpleBackgroundService.startDataFetch(this)
            
            // 延迟恢复磁贴状态
            android.os.Handler(mainLooper).postDelayed({
                updateTileState(isActive = false)
            }, 3000)
            
        } catch (e: Exception) {
            updateTileState(isActive = false)
        }
    }

    private fun updateTileState(isActive: Boolean = false) {
        qsTile?.apply {
            label = if (isActive) "正在获取..." else "云剪贴板"
            contentDescription = if (isActive) "正在后台获取加密云剪贴板数据" else "点击后台获取加密云剪贴板数据"
            state = if (isActive) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
            updateTile()
        }
    }
}