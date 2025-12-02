import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ztoolbox/cloud_clipboard/cloud_service/index.dart';
import 'package:ztoolbox/cloud_clipboard/history_record/sceen/folder_content_page.dart';
import 'package:ztoolbox/cloud_clipboard/history_record/provider/clipboard_provider.dart';

/// 简化后的底部导航栏组件
/// 移除了顶部状态栏和收藏夹管理功能
class ClipboardNavigationBar extends StatefulWidget {
  const ClipboardNavigationBar({super.key});

  @override
  State<ClipboardNavigationBar> createState() => _ClipboardNavigationBarState();
}

class _ClipboardNavigationBarState extends State<ClipboardNavigationBar> {
  // 当前选中的索引（默认选中云剪贴板页面）
  int _selectedIndex = 0;

  /// 处理底部导航栏点击
  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// 构建底部导航栏
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      onTap: _onTabTapped,
      selectedItemColor: Colors.lightBlue,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.black87,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.cloud),
          activeIcon: Icon(Icons.cloud_done),
          label: '云剪贴板',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          activeIcon: Icon(Icons.history_toggle_off),
          label: '历史记录',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _selectedIndex == 0
          ? const TextDbPage()
          : Consumer<ClipboardProvider>(
              builder: (context, provider, child) {
                return FolderContentPage(
                  folderName: provider.currentFolderName,
                  service: provider.service,
                );
              },
            ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}
