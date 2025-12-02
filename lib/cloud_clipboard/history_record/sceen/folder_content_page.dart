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
            favoriteFolderId: item.favoriteFolderId,
          );
          await _loadData();
          _showMessage('保存成功');
        } catch (e) {
          _showMessage('保存失败：$e');
        }
      },
    );
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

  // 复制到剪贴板
  void _copyToClipboard(String content) {
    Clipboard.setData(ClipboardData(text: content));
    _showMessage('已复制到剪贴板');
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
        final topPadding = MediaQuery.of(context).padding.top;
        return Container(
          margin: EdgeInsets.only(
            left: 16,
            top: 16 + topPadding, // 额外加上系统状态栏高度
            right: 16,
            bottom: 16,
          ),
          child: Row(
            children: [
              // 左侧：文件夹图标和统计信息（点击可管理收藏夹）
              Expanded(
                child: GestureDetector(
                  onTap: () => _showFavoritesManagement(context),
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
                          size: 30,
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
              ),
              // 右侧：操作按钮组
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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

  // 长按弹出菜单
  Future<void> _showItemMenu(
    ClipboardHistoryModel item,
    Offset tapPosition,
  ) async {
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        tapPosition.dx, // 左
        tapPosition.dy, // 上
        tapPosition.dx + 1, // 右
        tapPosition.dy + 1, // 下
      ),
      color: Color(0xFF2c2c2c), // 设置整个弹出菜单的背景颜色
      items: [
        PopupMenuItem<String>(
          value: 'delete',
          child: Text(
            '删除',
            style: TextStyle(color: Color(0xFFd5d5d5), fontSize: 16),
          ),
        ),
        PopupMenuItem<String>(
          value: 'favorite',
          child: Text(
            item.favoriteFolderId != null ? '取消收藏' : '加入收藏',
            style: TextStyle(color: Color(0xFFd5d5d5), fontSize: 16),
          ),
        ),
      ],
    );

    if (selected != null) {
      switch (selected) {
        case 'delete':
          await _deleteItem(item.id!);
          break;
        case 'favorite':
          // 处理收藏/取消收藏逻辑
          try {
            if (item.favoriteFolderId != null) {
              // 取消收藏
              await _service.updateHistory(
                item.id!,
                content: item.content,
                favoriteFolderId: null,
              );
              _showMessage('已取消收藏');
            } else {
              // 加入收藏 - 直接设置收藏夹ID为1
              await _service.updateHistory(
                item.id!,
                content: item.content,
                favoriteFolderId: 1,
              );
              _showMessage('已加入收藏');
            }
            await _loadData(); // 重新加载数据刷新界面
          } catch (e) {
            _showMessage('收藏操作失败：$e');
          }
          break;
      }
    }
  }

  // 构建列表项
  Widget _buildListItem(ClipboardHistoryModel item) {
    final briefContent = item.content.length > 60
        ? '${item.content.substring(0, 60)}...'
        : item.content;

    // 格式化更新时间，只显示日期和时间（不显示秒）
    final formattedTime = item.updateTime
        .toString()
        .substring(0, 16)
        .replaceAll('T', ' ');

    return GestureDetector(
      onLongPressStart: (details) {
        _showItemMenu(item, details.globalPosition);
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF191919), // 背景颜色 #191919
          border: Border(
            bottom: BorderSide(
              color: const Color(0xFF333333), // 分隔线颜色 #333333
              width: 0.5,
            ),
          ),
        ),
        child: InkWell(
          onTap: () => _editRecord(item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 主内容区域
                Text(
                  briefContent,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFFd1d1d1), // 字体颜色 #d1d1d1
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 1),
                // 底部信息行
                Row(
                  children: [
                    // 收藏状态指示器
                    if (item.favoriteFolderId != null) ...[
                      const Icon(Icons.star, size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                    ],
                    // 更新时间
                    Text(
                      formattedTime,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF5e5e5e),
                      ), // 日期字体颜色 #5e5e5e
                    ),
                    const Spacer(),
                    // 复制按钮
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () => _copyToClipboard(item.content),
                      tooltip: '复制',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 26,
                        minHeight: 26,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
            //const SizedBox(height: 16),
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
                      padding: EdgeInsets.zero,
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
