import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ztoolbox/cloud_clipboard/history_record/provider/clipboard_provider.dart';
import 'package:ztoolbox/cloud_clipboard/history_record/data/clipboard_history_service.dart';
import 'package:ztoolbox/cloud_clipboard/history_record/data/model.dart';
import 'favorites_management_drawer.dart';
import 'package:ztoolbox/cloud_clipboard/common/prompt.dart';
import 'package:ztoolbox/cloud_clipboard/common/drawer_style.dart';

class FolderContentPage extends StatefulWidget {
  const FolderContentPage({super.key, required this.folderName, this.service});

  final String folderName;
  final ClipboardHistoryService? service;

  @override
  State<FolderContentPage> createState() => _FolderContentPageState();
}

class _FolderContentPageState extends State<FolderContentPage> {
  late final ClipboardHistoryService _service;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? ClipboardHistoryService();
    _loadData();
  }

  @override
  void didUpdateWidget(FolderContentPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当文件夹名称发生变化时，重新加载数据
    if (oldWidget.folderName != widget.folderName) {
      _loadData();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // 统一消息显示 - 使用ToastUtil
  void _showMessage(String message) {
    ToastUtil.showMessage(context, message);
  }

  // 加载数据
  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      final provider = Provider.of<ClipboardProvider>(context, listen: false);

      // 使用provider来管理历史记录列表
      await provider.refreshHistoryList();
    } catch (e) {
      _showMessage('加载失败：$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 编辑记录
  Future<void> _editRecord(ClipboardHistoryModel item) async {
    await EditRecordDrawer.show(
      context: context,
      initialContent: item.content,
      title: '编辑记录',
      service: _service,
      itemId: item.id,
      currentFolder: widget.folderName,
      onConfirm: (content) async {
        try {
          await _service.updateHistory(
            item.id!,
            content: content,
            favoriteType: item.favoriteType,
          );
          await _loadData();
          _showMessage('保存成功');
        } catch (e) {
          _showMessage('保存失败：$e');
        }
      },
    );
  }

  // 保存编辑
  // 切换收藏状态
  Future<void> _toggleFavorite(ClipboardHistoryModel item) async {
    try {
      final newFavoriteType = item.favoriteType == null ? '默认收藏夹' : null;
      await _service.updateHistory(item.id!, favoriteType: newFavoriteType);
      await _loadData();
      _showMessage(item.favoriteType == null ? '已收藏' : '已取消收藏');
    } catch (e) {
      _showMessage('操作失败：$e');
    }
  }

  // 删除项目
  Future<void> _deleteItem(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('是否确定删除这条记录？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteHistory(id);
        await _loadData();
        _showMessage('删除成功');
      } catch (e) {
        _showMessage('删除失败：$e');
      }
    }
  }

  // 复制到剪贴板
  void _copyToClipboard(String content) {
    Clipboard.setData(ClipboardData(text: content));
    _showMessage('已复制到剪贴板');
  }

  // 新增数据
  Future<void> _addNewItem() async {
    await AddRecordDrawer.show(
      context: context,
      title: '新增记录',
      onConfirm: (content) async {
        try {
          await _service.insertHistory(content: content);
          await _loadData();
          _showMessage('新增成功');
        } catch (e) {
          _showMessage('新增失败：$e');
        }
      },
    );
  }

  // 显示收藏夹管理
  void _showFavoritesManagement(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FavoritesManagementDrawer(service: _service),
    );
  }

  // 构建统计信息和操作栏
  Widget _buildStatsRow() {
    return Consumer<ClipboardProvider>(
      builder: (context, provider, child) {
        return Container(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // 左侧：文件夹图标和统计信息
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(51), // 20% 透明度的白色背景
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.folder_special,
                          color: Colors.orange, // 橙色图标，在黑色背景下更显眼
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.folderName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${provider.historyList.length} 条记录',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withAlpha(204), // 80% opacity
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 右侧：操作按钮组
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 收藏夹管理按钮
                    _buildActionButton(
                      icon: Icons.folder_outlined,
                      tooltip: '收藏夹管理',
                      onPressed: () => _showFavoritesManagement(context),
                      backgroundColor: Colors.white24, // 浅色背景
                      iconColor: Colors.white, // 白色图标
                    ),
                    const SizedBox(width: 8),
                    // 新增按钮
                    _buildActionButton(
                      icon: Icons.add,
                      tooltip: '新增记录',
                      onPressed: _addNewItem,
                      backgroundColor: Colors.white24, // 浅色背景
                      iconColor: Colors.white, // 白色图标
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 构建操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor, // 使用浅色背景
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        tooltip: tooltip,
        iconSize: 22,
        color: iconColor,
        style: IconButton.styleFrom(padding: const EdgeInsets.all(8)),
      ),
    );
  }

  // 构建列表项
  Widget _buildListItem(ClipboardHistoryModel item) {
    final briefContent = item.content.length > 50
        ? '${item.content.substring(0, 50)}...'
        : item.content;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 主内容区域 - 整个区域可点击展开
            GestureDetector(
              onTap: () => _editRecord(item),
              child: Row(
                children: [
                  // 收藏按钮 - 增大点击区域
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            item.favoriteType != null
                                ? Icons.star
                                : Icons.star_border,
                            color: item.favoriteType != null
                                ? Colors.yellow
                                : null,
                            size: 24,
                          ),
                          onPressed: () => _toggleFavorite(item),
                          tooltip: item.favoriteType != null ? '取消收藏' : '加入收藏',
                          padding: EdgeInsets.zero,
                        ),
                        if (item.favoriteType != null)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              alignment: Alignment.center,
                              child: Text(
                                item.favoriteType!,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        briefContent,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 操作按钮区域
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 更新时间
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 8),
                  child: Text(
                    '更新时间：${item.updateTime.toString().substring(0, 19)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                // 操作按钮 - 增大点击区域
                Row(
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: IconButton(
                        icon: const Icon(Icons.copy, size: 22),
                        onPressed: () => _copyToClipboard(item.content),
                        tooltip: '复制',
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: IconButton(
                        icon: const Icon(
                          Icons.delete,
                          size: 22,
                          color: Colors.red,
                        ),
                        onPressed: () => _deleteItem(item.id!),
                        tooltip: '删除',
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Consumer<ClipboardProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            _buildStatsRow(),
            provider.historyList.isEmpty
                ? Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: 64,
                            color: Colors.grey.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '暂无${widget.folderName}记录',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: provider.historyList.length,
                      itemBuilder: (context, index) =>
                          _buildListItem(provider.historyList[index]),
                    ),
                  ),
          ],
        );
      },
    );
  }
}
