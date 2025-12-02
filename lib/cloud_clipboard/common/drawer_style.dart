import 'package:flutter/material.dart';
import 'package:ztoolbox/cloud_clipboard/history_record/data/clipboard_history_service.dart';
import 'package:ztoolbox/cloud_clipboard/history_record/data/model.dart';
import 'package:ztoolbox/cloud_clipboard/common/prompt.dart';

/// 通用抽屉样式组件
/// 固定样式：底部弹出，圆角12，顶部有小白灰条，左侧为标题
class CommonDrawer extends StatelessWidget {
  /// 抽屉标题
  final String title;

  /// 抽屉内容Widget
  final Widget content;

  const CommonDrawer({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minHeight = constraints.maxHeight * 0.8;
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
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              //const Divider(height: 1, thickness: 1),
              // 内容区域
              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: content,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 统一收藏夹抽屉工具类（用于创建和编辑收藏夹）
class FavoriteFolderDrawer {
  /// 显示收藏夹抽屉
  ///
  /// [context] BuildContext
  /// [onConfirm] 确认回调，返回收藏夹名称
  /// [service] ClipboardHistoryService 服务实例
  /// [folder] 可选参数，要编辑的收藏夹模型（如果为null则表示创建新收藏夹）
  static Future<void> show({
    required BuildContext context,
    required Function(String folderName) onConfirm,
    required ClipboardHistoryService service,
    FavoriteFolderModel? folder,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FavoriteFolderDrawerContent(
        onConfirm: onConfirm,
        service: service,
        folder: folder,
      ),
    ).then((result) {
      // 调用回调函数
      if (result != null && context.mounted) {
        onConfirm(result as String);
      }
    });
  }
}

class _FavoriteFolderDrawerContent extends StatefulWidget {
  final Function(String folderName) onConfirm;
  final ClipboardHistoryService service;
  final FavoriteFolderModel? folder;

  const _FavoriteFolderDrawerContent({
    required this.onConfirm,
    required this.service,
    this.folder,
  });

  @override
  State<_FavoriteFolderDrawerContent> createState() =>
      _FavoriteFolderDrawerContentState();
}

class _FavoriteFolderDrawerContentState
    extends State<_FavoriteFolderDrawerContent> {
  late final TextEditingController _controller;
  late final bool _isEditing; // 是否为编辑模式

  // 统一消息显示 - 使用ToastUtil
  void _showMessage(String message) {
    ToastUtil.showMessage(context, message);
  }

  @override
  void initState() {
    super.initState();
    _isEditing = widget.folder != null;
    _controller = TextEditingController(
      text: _isEditing ? widget.folder!.folderName : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
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
                Text(
                  _isEditing ? '编辑收藏夹' : '新建收藏夹',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 内容区域 - 可以滚动
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: '输入收藏夹名称...',
                  border: OutlineInputBorder(),
                ),
                expands: true,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 底部按钮区域 - 固定在底部
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 取消按钮（第一行，无背景灰色文字）
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      '取消',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // 确认按钮（第二行，黑圆角背景白色字体）
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final folderName = _controller.text.trim();
                      if (folderName.isEmpty) {
                        _showMessage('收藏夹名称不能为空');
                        return;
                      }

                      // 如果是编辑模式且名称没有变化，则直接关闭
                      if (_isEditing &&
                          folderName == widget.folder!.folderName) {
                        Navigator.pop(context);
                        return;
                      }

                      try {
                        if (_isEditing) {
                          // 编辑模式 - 更新收藏夹
                          final result = await widget.service
                              .updateFavoriteFolder(
                                widget.folder!.folderId!,
                                folderName: folderName,
                              );

                          if (result == -1) {
                            // 默认收藏夹不能被重命名
                            if (context.mounted) {
                              _showMessage('默认收藏夹不能被重命名');
                            }
                            return;
                          }
                        } else {
                          // 创建模式 - 插入新收藏夹
                          await widget.service.insertFavoriteFolder(
                            folderName: folderName,
                          );
                        }

                        if (context.mounted) {
                          Navigator.pop(context, folderName);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          _showMessage('${_isEditing ? '编辑' : '创建'}失败：$e');
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '确定',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 编辑记录抽屉工具类
class EditRecordDrawer {
  /// 显示编辑记录抽屉
  ///
  /// [context] BuildContext
  /// [initialContent] 初始内容
  /// [onConfirm] 确认回调，返回编辑后的内容
  /// [service] ClipboardHistoryService 服务实例（用于获取收藏夹列表）
  /// [itemId] 项目ID（用于移动收藏夹）
  /// [currentFolder] 当前所在的收藏夹
  static Future<void> show({
    required BuildContext context,
    required String initialContent,
    required Function(String content) onConfirm,
    String title = '编辑记录',
    ClipboardHistoryService? service,
    int? itemId,
    String? currentFolder,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _EditRecordDrawerContent(
        initialContent: initialContent,
        onConfirm: onConfirm,
        title: title,
        service: service,
        itemId: itemId,
        currentFolder: currentFolder,
      ),
    ).then((result) {
      // 调用回调函数
      if (result != null && context.mounted) {
        onConfirm(result as String);
      }
    });
  }
}

class _EditRecordDrawerContent extends StatefulWidget {
  final String initialContent;
  final Function(String content) onConfirm;
  final String title;
  final ClipboardHistoryService? service;
  final int? itemId;
  final String? currentFolder;

  const _EditRecordDrawerContent({
    required this.initialContent,
    required this.onConfirm,
    required this.title,
    this.service,
    this.itemId,
    this.currentFolder,
  });

  @override
  State<_EditRecordDrawerContent> createState() =>
      _EditRecordDrawerContentState();
}

class _EditRecordDrawerContentState extends State<_EditRecordDrawerContent> {
  late final TextEditingController _controller;

  // 统一消息显示 - 使用ToastUtil
  void _showMessage(String message) {
    ToastUtil.showMessage(context, message);
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
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
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 内容区域 - 可以滚动
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                maxLines: null,
                maxLength: 20000,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '请输入内容...',
                ),
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 移动收藏夹按钮（如果有service和itemId）
          if (widget.service != null && widget.itemId != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    // 获取所有收藏夹
                    try {
                      final folders = await widget.service!
                          .getAllFavoriteFolders();

                      // 过滤掉当前文件夹
                      final filteredFolders = folders
                          .where(
                            (folder) =>
                                folder.folderName != widget.currentFolder,
                          )
                          .toList();

                      // 检查context是否仍然有效
                      if (!context.mounted) return;

                      // 显示收藏夹选择对话框
                      final selectedFolder = await showDialog<String>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('移动到收藏夹'),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 无收藏夹选项
                                  ListTile(
                                    title: const Text('无收藏夹'),
                                    onTap: () => Navigator.pop(context, ''),
                                  ),
                                  // 分隔线
                                  const Divider(),
                                  // 收藏夹列表（排除当前文件夹）
                                  ...filteredFolders.map(
                                    (folder) => ListTile(
                                      title: Text(folder.folderName),
                                      onTap: () => Navigator.pop(
                                        context,
                                        folder.folderName,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );

                      // 如果选择了收藏夹，则更新记录
                      if (selectedFolder != null) {
                        try {
                          await widget.service!.updateHistory(
                            widget.itemId!,
                            favoriteType: selectedFolder.isEmpty
                                ? null
                                : selectedFolder,
                          );

                          // 显示成功消息
                          if (context.mounted) {
                            _showMessage(
                              selectedFolder.isEmpty
                                  ? '已移出收藏夹'
                                  : '已移动到 $selectedFolder',
                            );
                          }
                        } catch (e) {
                          // 显示错误消息
                          if (context.mounted) {
                            _showMessage('移动失败: $e');
                          }
                        }
                      }
                    } catch (e) {
                      // 显示错误消息
                      if (context.mounted) {
                        _showMessage('获取收藏夹失败: $e');
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '移动收藏夹',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // 底部按钮区域 - 固定在底部
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 取消按钮（第一行，无背景灰色文字）
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      '取消',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // 确认按钮（第二行，黑圆角背景白色字体）
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final content = _controller.text.trim();
                      if (content.isEmpty) {
                        _showMessage('内容不能为空');
                        return;
                      }
                      Navigator.pop(context, content);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '保存',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 新增记录抽屉工具类
class AddRecordDrawer {
  /// 显示新增记录抽屉
  ///
  /// [context] BuildContext
  /// [onConfirm] 确认回调，返回输入的内容
  static Future<void> show({
    required BuildContext context,
    required Function(String content) onConfirm,
    String title = '新增记录',
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          _AddRecordDrawerContent(onConfirm: onConfirm, title: title),
    ).then((result) {
      // 调用回调函数
      if (result != null && context.mounted) {
        onConfirm(result as String);
      }
    });
  }
}

class _AddRecordDrawerContent extends StatefulWidget {
  final Function(String content) onConfirm;
  final String title;

  const _AddRecordDrawerContent({required this.onConfirm, required this.title});

  @override
  State<_AddRecordDrawerContent> createState() =>
      _AddRecordDrawerContentState();
}

class _AddRecordDrawerContentState extends State<_AddRecordDrawerContent> {
  late final TextEditingController _controller;

  // 统一消息显示 - 使用ToastUtil
  void _showMessage(String message) {
    ToastUtil.showMessage(context, message);
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
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
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 内容区域 - 可以滚动
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                maxLines: null,
                maxLength: 20000,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '请输入内容...',
                ),
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 底部按钮区域 - 固定在底部
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 取消按钮（第一行，无背景灰色文字）
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      '取消',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // 确认按钮（第二行，黑圆角背景白色字体）
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final content = _controller.text.trim();
                      if (content.isEmpty) {
                        _showMessage('内容不能为空');
                        return;
                      }
                      Navigator.pop(context, content);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '确定',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
