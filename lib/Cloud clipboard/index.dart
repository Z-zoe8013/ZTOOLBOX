import 'package:flutter/material.dart';
import 'Access service/visit.dart';
import 'Access service/save.dart';
import 'clipboard_utils.dart';
import 'prompt.dart';

/// 剪贴板页面
/// 简化版 - 保留核心功能
class ClipboardPage extends StatefulWidget {
  const ClipboardPage({super.key});

  @override
  State<ClipboardPage> createState() => _ClipboardPageState();
}

class _ClipboardPageState extends State<ClipboardPage> {
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false; // 控制刷新按钮状态
  bool _isSaving = false; // 控制保存按钮状态

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // 复制文本到剪贴板
  Future<void> _copyToClipboard() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      if (mounted) ToastUtil.showMessage(context, '请输入要复制的文本');
      return;
    }
    await ClipboardUtils.setClipboardText(text);
    if (mounted) ToastUtil.showMessage(context, '已复制到剪贴板');
  }

  // 从剪贴板粘贴文本
  Future<void> _pasteFromClipboard() async {
    final clipboardText = await ClipboardUtils.getClipboardText();
    if (clipboardText != null && clipboardText.trim().isNotEmpty) {
      setState(() {
        _textController.text = clipboardText;
      });
      if (mounted) ToastUtil.showMessage(context, '已粘贴文本');
    } else {
      if (mounted) ToastUtil.showMessage(context, '剪贴板为空或无文本');
    }
  }

  // 刷新：访问服务并填充数据
  Future<void> _refreshData() async {
    setState(() => _isLoading = true);

    try {
      final service = NetcutService();
      final result = await service.fetchNoteInfo();

      if (!mounted) return;

      setState(() {
        _textController.text = result.toString();
        _isLoading = false;
      });

      if (mounted) ToastUtil.showMessage(context, '已刷新并复制');
      await ClipboardUtils.setClipboardText(result.toString());
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) ToastUtil.showMessage(context, '刷新失败: $e');
    }
  }

  // 保存文本内容
  Future<void> _saveText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      if (mounted) ToastUtil.showMessage(context, '请输入要保存的内容');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final saveService = SaveService();
      final result = await saveService.saveNote(noteContent: text);

      if (!mounted) return;

      if (result != null && !result.toString().contains('失效')) {
        if (mounted) ToastUtil.showMessage(context, '保存成功');
      } else {
        if (mounted) ToastUtil.showMessage(context, '保存失败：服务返回异常');
      }
    } catch (e) {
      if (mounted) ToastUtil.showMessage(context, '保存出错: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 获取屏幕宽度，用于响应式布局
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 360;

    // 主题颜色
    const primaryColor = Color(0xFFBB86FC); // 紫色点缀
    const secondaryColor = Color(0xFF03DAC6); // 青色点缀
    const accentColor = Color(0xFFFF4081); // 粉色点缀
    const successColor = Color(0xFF00E676); // 绿色点缀

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('云剪贴板'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          // 保存按钮
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveText,
            tooltip: '保存',
            color: successColor,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 简化的文本编辑区域
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: '输入或粘贴文本...',
                  hintStyle: TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: Colors.black87,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white12),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: const TextStyle(fontSize: 16, color: Colors.white),
                textAlignVertical: TextAlignVertical.top,
                maxLines: null, // 允许多行输入
              ),
            ),
            const SizedBox(height: 20),

            // 简化的按钮区域
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 复制按钮
                _buildSimpleButton(
                  icon: Icons.copy,
                  label: '复制',
                  onPressed: _copyToClipboard,
                  color: primaryColor,
                  isSmallScreen: isSmallScreen,
                ),
                const SizedBox(width: 12),

                // 粘贴按钮
                _buildSimpleButton(
                  icon: Icons.paste,
                  label: '粘贴',
                  onPressed: _pasteFromClipboard,
                  color: secondaryColor,
                  isSmallScreen: isSmallScreen,
                ),
                const SizedBox(width: 12),

                // 刷新按钮
                _buildSimpleButton(
                  icon: Icons.refresh,
                  label: '刷新',
                  onPressed: _isLoading ? null : _refreshData,
                  color: accentColor,
                  isSmallScreen: isSmallScreen,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 简化的按钮构建方法
  Widget _buildSimpleButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
    required bool isSmallScreen,
    bool isLoading = false,
  }) {
    final fontSize = isSmallScreen ? 14.0 : 16.0;

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icon, size: 16),
      label: Text(label, style: TextStyle(fontSize: fontSize)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
