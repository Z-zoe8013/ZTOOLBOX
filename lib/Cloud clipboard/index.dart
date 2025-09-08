import 'package:flutter/material.dart';
import 'Access service/visit.dart';
import 'Access service/save.dart';
import 'clipboard_utils.dart';
import 'prompt.dart';
import 'glass_container.dart';

/// 剪贴板页面
/// 响应式设计，解决移动端按键溢出问题
class ClipboardPage extends StatefulWidget {
  const ClipboardPage({super.key});

  @override
  State<ClipboardPage> createState() => _ClipboardPageState();
}

class _ClipboardPageState extends State<ClipboardPage> {
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false; // 控制刷新按钮状态

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // 📋 复制文本到剪贴板
  Future<void> _copyToClipboard() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      if (mounted) ToastUtil.showMessage(context, '请输入要复制的文本');
      return;
    }
    await ClipboardUtils.setClipboardText(text);
    if (mounted) ToastUtil.showMessage(context, '已复制到剪贴板');
  }

  // 📋 从剪贴板粘贴文本
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

  // 🔄 刷新：访问服务并填充数据
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

  // 💾 保存文本内容
  Future<void> _saveText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      if (mounted) ToastUtil.showMessage(context, '请输入要保存的内容');
      return;
    }

    try {
      final saveService = SaveService();
      final result = await saveService.saveNote(noteContent: text);

      if (result != null && !result.toString().contains('失效')) {
        if (mounted) ToastUtil.showMessage(context, '保存成功');
      } else {
        if (mounted) ToastUtil.showMessage(context, '保存失败：服务返回异常');
      }
    } catch (e) {
      if (mounted) ToastUtil.showMessage(context, '保存出错: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 获取屏幕宽度，用于响应式布局
    final screenWidth = MediaQuery.of(context).size.width;
    // 根据屏幕宽度决定按钮尺寸和图标显示
    final bool isSmallScreen = screenWidth < 360;
    final double buttonPadding = isSmallScreen ? 8.0 : 12.0;
    final double iconSize = isSmallScreen ? 16 : 18;

    // 深色主题颜色
    const primaryColor = Color(0xFFBB86FC); // 紫色点缀
    const secondaryColor = Color(0xFF03DAC6); // 青色点缀
    const accentColor = Color(0xFFFF4081); // 粉色点缀
    const successColor = Color(0xFF00E676); // 绿色点缀

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('云剪贴板'),
        backgroundColor: Colors.black87,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 文本编辑区域
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black87,
                  border: Border.all(color: Colors.white12),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.05),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _textController,
                  autofocus: false,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '输入或粘贴文本...',
                    hintStyle: TextStyle(color: Colors.white30),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  textInputAction: TextInputAction.done,
                  cursorColor: primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 按钮区域 - 使用Wrap替代Row，解决溢出问题
            Wrap(
              spacing: 12.0, // 水平间距
              runSpacing: 12.0, // 垂直间距
              alignment: WrapAlignment.center,
              children: [
                // 复制按钮
                _buildActionButton(
                  icon: Icons.copy,
                  label: '复制',
                  onPressed: _copyToClipboard,
                  color: primaryColor,
                  isLoading: false,
                  buttonPadding: buttonPadding,
                  iconSize: iconSize,
                  isSmallScreen: isSmallScreen,
                ),

                // 粘贴按钮
                _buildActionButton(
                  icon: Icons.paste,
                  label: '粘贴',
                  onPressed: _pasteFromClipboard,
                  color: secondaryColor,
                  isLoading: false,
                  buttonPadding: buttonPadding,
                  iconSize: iconSize,
                  isSmallScreen: isSmallScreen,
                ),

                // 刷新按钮
                _buildActionButton(
                  icon: Icons.refresh,
                  label: '刷新',
                  onPressed: _isLoading ? null : _refreshData,
                  color: accentColor,
                  isLoading: _isLoading,
                  buttonPadding: buttonPadding,
                  iconSize: iconSize,
                  isSmallScreen: isSmallScreen,
                ),

                // 保存按钮
                _buildActionButton(
                  icon: Icons.save,
                  label: '保存',
                  onPressed: _saveText,
                  color: successColor,
                  isLoading: false,
                  buttonPadding: buttonPadding,
                  iconSize: iconSize,
                  isSmallScreen: isSmallScreen,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 构建响应式操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
    bool isLoading = false,
    required double buttonPadding,
    required double iconSize,
    required bool isSmallScreen,
  }) {
    // 小屏幕上按钮宽度占比更大
    final buttonWidth = isSmallScreen
        ? (MediaQuery.of(context).size.width - 60) / 2
        : null;

    final buttonContent = ElevatedButton.icon(
      onPressed: onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icon, size: iconSize),
      label: Padding(
        padding: EdgeInsets.symmetric(vertical: buttonPadding),
        child: Text(label, style: TextStyle(fontSize: isSmallScreen ? 14 : 16)),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withOpacity(0.5)),
        ),
        elevation: 0,
        disabledBackgroundColor: Colors.transparent,
        disabledForegroundColor: Colors.white30,
      ),
    );

    return SizedBox(
      width: buttonWidth,
      child: GlassContainer(
        child: buttonContent,
        blur: 10.0,
        opacity: 0.15,
        borderOpacity: 0.4,
        borderRadius: 8.0,
        padding: const EdgeInsets.all(0),
      ),
    );
  }
}
