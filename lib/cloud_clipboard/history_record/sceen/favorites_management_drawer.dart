import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ztoolbox/cloud_clipboard/history_record/provider/clipboard_provider.dart';
import 'package:ztoolbox/cloud_clipboard/history_record/data/clipboard_history_service.dart';
import 'package:ztoolbox/cloud_clipboard/history_record/data/model.dart';

import 'package:ztoolbox/cloud_clipboard/common/prompt.dart';
import 'package:ztoolbox/cloud_clipboard/common/drawer_style.dart';

class FavoritesManagementDrawer extends StatefulWidget {
  const FavoritesManagementDrawer({super.key, required this.service});

  final ClipboardHistoryService service;

  @override
  State<FavoritesManagementDrawer> createState() =>
      _FavoritesManagementDrawerState();
}

class _FavoritesManagementDrawerState extends State<FavoritesManagementDrawer> {
  // 统一消息显示 - 使用ToastUtil
  void _showMessage(String message) {
    ToastUtil.showMessage(context, message);
  }

  // 构建收藏夹管理抽屉
  Widget _buildFavoritesManagementSheet() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minHeight = constraints.maxHeight * 0.5;
        return Container(
          constraints: BoxConstraints(minHeight: minHeight),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 顶部小白灰条
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 标题区域
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text(
                      '收藏夹管理',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // 内容区域
              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 视图选择器
                        _buildFavoritesViewSelector(),
                        const SizedBox(height: 16),
                        // 文件夹列表
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: _buildFavoritesFolderList(),
                        ),
                        const SizedBox(height: 16),
                        // 创建新文件夹按钮
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _showCreateFolderDialog(),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              '新建收藏夹',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 清理未收藏历史记录按钮
                        _buildClearUnfavoritedHistoryButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 构建收藏夹视图选择器
  Widget _buildFavoritesViewSelector() {
    return Consumer<ClipboardProvider>(
      builder: (context, provider, child) {
        final currentFolder = provider.currentFolderName;
        return Row(
          children: [
            _buildFavoritesViewOption('全部', Icons.all_inclusive, currentFolder),
            const SizedBox(width: 8),
            _buildFavoritesViewOption('未收藏', Icons.star_border, currentFolder),
          ],
        );
      },
    );
  }

  // 构建收藏夹视图选项
  Widget _buildFavoritesViewOption(
    String title,
    IconData icon,
    String currentFolder,
  ) {
    return Expanded(
      child: InkWell(
        onTap: () {
          final provider = Provider.of<ClipboardProvider>(
            context,
            listen: false,
          );
          provider.selectFolder(title);
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: currentFolder == title
                ? Theme.of(context).colorScheme.primary.withAlpha(10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: currentFolder == title
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).dividerColor,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: currentFolder == title
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withAlpha(153),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: currentFolder == title
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withAlpha(153),
                  fontWeight: currentFolder == title
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建收藏夹文件夹列表
  Widget _buildFavoritesFolderList() {
    return FutureBuilder<List<FavoriteFolderModel>>(
      future: widget.service.getAllFavoriteFolders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              '加载失败: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final folders = snapshot.data ?? [];

        if (folders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_open,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(77),
                ),
                const SizedBox(height: 16),
                Text(
                  '暂无收藏夹',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(128),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: folders.length,
          itemBuilder: (context, index) =>
              _buildFavoritesFolderItem(folders[index]),
        );
      },
    );
  }

  // 构建收藏夹文件夹项
  Widget _buildFavoritesFolderItem(FavoriteFolderModel folder) {
    return Consumer<ClipboardProvider>(
      builder: (context, provider, child) {
        final currentFolder = provider.currentFolderName;
        return GestureDetector(
          onLongPress: () => _editFavoriteFolder(folder),
          child: ListTile(
            leading: Icon(
              Icons.folder,
              color: currentFolder == folder.folderName
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withAlpha(153),
            ),
            title: Text(
              folder.folderName,
              style: TextStyle(
                fontWeight: currentFolder == folder.folderName
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _editFavoriteFolder(folder),
                  tooltip: '编辑文件夹',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18),
                  onPressed: () => _deleteFavoriteFolder(folder),
                  tooltip: '删除文件夹',
                ),
              ],
            ),
            onTap: () {
              provider.selectFolder(folder.folderName, folderId: folder.folderId);
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  // 构建清理未收藏历史记录按钮
  Widget _buildClearUnfavoritedHistoryButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _clearUnfavoritedHistory,
        icon: const Icon(
          Icons.cleaning_services,
          size: 20,
          color: Colors.white,
        ),
        label: const Text(
          '清理非收藏历史（留 100 条）',
          style: TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // 删除收藏夹
  Future<void> _deleteFavoriteFolder(FavoriteFolderModel folder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('是否确定删除收藏夹"${folder.folderName}"？'),
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
        if (folder.folderId != null) {
          final result = await widget.service.deleteFavoriteFolder(
            folder.folderId!,
          );
          if (result == -1) {
            // 默认收藏夹不能被删除
            _showMessage('默认收藏夹不能被删除');
          } else if (result > 0) {
            _showMessage('删除成功');
            setState(() {}); // 刷新UI
          } else {
            _showMessage('删除失败');
          }
        } else {
          _showMessage('无法删除：文件夹ID为空');
        }
      } catch (e) {
        _showMessage('删除失败：$e');
      }
    }
  }

  // 编辑收藏夹
  Future<void> _editFavoriteFolder(FavoriteFolderModel folder) async {
    final currentContext = context; // 保存当前context
    await FavoriteFolderDrawer.show(
      context: context,
      folder: folder,
      service: widget.service,
      onConfirm: (newFolderName) {
        _showMessage('编辑成功');
        setState(() {}); // 刷新UI
      },
    ).then((_) {
      // 在then回调中也移除焦点
      if (currentContext.mounted) {
        FocusScope.of(currentContext).unfocus();
      }
    });
  }

  // 清理未收藏的历史记录
  Future<void> _clearUnfavoritedHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清理'),
        content: const Text('此操作将删除未收藏的历史记录，只保留最新的100条。是否继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await widget.service.clearUnfavoritedHistoryExcess();
        _showMessage('清理完成');
        // 刷新UI
        setState(() {});
      } catch (e) {
        _showMessage('清理失败：$e');
      }
    }
  }

  // 显示创建收藏夹对话框
  Future<void> _showCreateFolderDialog() async {
    final currentContext = context; // 保存当前context
    await FavoriteFolderDrawer.show(
      context: context,
      service: widget.service,
      onConfirm: (folderName) {
        _showMessage('创建成功');
        setState(() {}); // 刷新UI
      },
    ).then((_) {
      // 在then回调中也移除焦点
      if (currentContext.mounted) {
        FocusScope.of(currentContext).unfocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildFavoritesManagementSheet();
  }
}
