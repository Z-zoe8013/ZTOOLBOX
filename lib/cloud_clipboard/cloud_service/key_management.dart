import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ztoolbox/cloud_clipboard/common/prompt.dart';
import 'cloud_service.dart';
import 'package:ztoolbox/cloud_clipboard/common/glass_container.dart'; // 导入玻璃容器组件

// 加密工具类
class EncryptionUtils {
  static String generateSecureKey() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*()_+-=';
    final random = Random.secure();
    return List.generate(16, (_) => chars[random.nextInt(chars.length)]).join();
  }
}

// 密钥管理工具类 - 提供给外部使用
class KeyManager {
  static const String _keyName = 'encryption_key';

  // 获取密钥
  static Future<String?> getSavedKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName);
  }

  // 检查是否存在密钥
  static Future<bool> hasKey() async {
    final key = await getSavedKey();
    return key != null && key.isNotEmpty;
  }

  // 保存密钥
  static Future<void> saveKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, key);
  }

  // 清除密钥
  static Future<void> clearKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyName);
  }
}

/// 集成设置抽屉，包含密钥管理和用户ID管理
class SettingsDrawer extends StatefulWidget {
  const SettingsDrawer({super.key});

  @override
  State<SettingsDrawer> createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.grey[900], // 比纯黑稍灰一点的背景
      child: SafeArea(
        child: Column(
          children: [
            // 标题栏 - 玻璃质感
            GlassContainer(
              padding: const EdgeInsets.all(16.0),
              blur: 15,
              opacity: 0.15,
              borderOpacity: 0.2,
              borderRadius: 0,
              child: const Center(
                child: Text(
                  '设置管理',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // 选项卡 - 玻璃质感
            GlassContainer(
              padding: EdgeInsets.zero,
              blur: 15,
              opacity: 0.15,
              borderOpacity: 0.2,
              borderRadius: 0,
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.blue,
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(icon: Icon(Icons.key), text: '密钥管理'),
                  Tab(icon: Icon(Icons.cloud), text: '用户ID'),
                ],
              ),
            ),
            // 选项卡内容
            Expanded(
              child: Container(
                color: Colors.grey[900], // 内容区域背景色
                child: TabBarView(
                  controller: _tabController,
                  children: const [KeyManagerContent(), UserIdContent()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 密钥管理内容组件
class KeyManagerContent extends StatefulWidget {
  const KeyManagerContent({super.key});

  @override
  State<KeyManagerContent> createState() => _KeyManagerContentState();
}

class _KeyManagerContentState extends State<KeyManagerContent> {
  final _keyController = TextEditingController();
  bool _isLoading = true;
  final _prefsKey = 'encryption_key';

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _loadKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = prefs.getString(_prefsKey);
      if (savedKey != null) {
        _keyController.text = savedKey;
      }
    } catch (e) {
      _showMessage('加载密钥失败');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keyValue = _keyController.text.trim();

      if (keyValue.isEmpty) {
        await prefs.remove(_prefsKey);
        _showMessage('已清除密钥');
      } else {
        await prefs.setString(_prefsKey, keyValue);
        _showMessage('密钥已保存');
      }
    } catch (e) {
      _showMessage('保存失败: $e');
    }
  }

  void _generateKey() {
    _keyController.text = EncryptionUtils.generateSecureKey();
  }

  void _showMessage(String msg) {
    ToastUtil.showMessage(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.blue));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 密钥输入框 - 玻璃质感
          GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            blur: 15,
            opacity: 0.15,
            borderOpacity: 0.2,
            child: TextField(
              controller: _keyController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: '密钥值',
                labelStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
              maxLines: 2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GlassContainer(
                  padding: const EdgeInsets.all(2),
                  blur: 15,
                  opacity: 0.15,
                  borderOpacity: 0.2,
                  child: ElevatedButton.icon(
                    onPressed: _generateKey,
                    icon: const Icon(Icons.lock, color: Colors.lightBlue),
                    label: const Text(
                      '生成密钥',
                      style: TextStyle(color: Colors.lightBlue),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.lightBlue,
                      shadowColor: Colors.transparent,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GlassContainer(
                  padding: const EdgeInsets.all(2),
                  blur: 15,
                  opacity: 0.15,
                  borderOpacity: 0.2,
                  child: ElevatedButton.icon(
                    onPressed: _saveKey,
                    icon: const Icon(Icons.save, color: Colors.lightGreen),
                    label: const Text(
                      '保存',
                      style: TextStyle(color: Colors.lightGreen),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.lightGreen,
                      shadowColor: Colors.transparent,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 用户ID管理内容组件
class UserIdContent extends StatefulWidget {
  const UserIdContent({super.key});

  @override
  State<UserIdContent> createState() => _UserIdContentState();
}

class _UserIdContentState extends State<UserIdContent> {
  final _userIdController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _loadUserId() async {
    try {
      final userId = await UseIdManager.getUseId();
      _userIdController.text = userId ?? '';
    } catch (e) {
      _showMessage('加载用户ID失败');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveUserId() async {
    try {
      final userIdValue = _userIdController.text.trim();

      if (userIdValue.isEmpty) {
        _showMessage('用户ID不能为空');
        return;
      }

      await UseIdManager.saveUseId(userIdValue);
      _showMessage('用户ID已保存');
    } catch (e) {
      _showMessage('保存失败: $e');
    }
  }

  void _generateUserId() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    final randomId = List.generate(
      8,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
    _userIdController.text = 'User_$randomId';
  }

  Future<void> _clearUserId() async {
    try {
      await UseIdManager.clearUseId();
      _userIdController.text = '';
      _showMessage('用户ID已清除');
    } catch (e) {
      _showMessage('清除失败: $e');
    }
  }

  void _showMessage(String msg) {
    ToastUtil.showMessage(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.blue));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 用户ID输入框 - 玻璃质感
          GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            blur: 15,
            opacity: 0.15,
            borderOpacity: 0.2,
            child: TextField(
              controller: _userIdController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: '用户ID',
                labelStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GlassContainer(
                  padding: const EdgeInsets.all(2),
                  blur: 15,
                  opacity: 0.15,
                  borderOpacity: 0.2,
                  child: ElevatedButton.icon(
                    onPressed: _generateUserId,
                    icon: const Icon(Icons.refresh, color: Colors.lightBlue),
                    label: const Text(
                      '生成ID',
                      style: TextStyle(color: Colors.lightBlue),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.lightBlue,
                      shadowColor: Colors.transparent,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GlassContainer(
                  padding: const EdgeInsets.all(2),
                  blur: 15,
                  opacity: 0.15,
                  borderOpacity: 0.2,
                  child: ElevatedButton.icon(
                    onPressed: _saveUserId,
                    icon: const Icon(Icons.save, color: Colors.lightGreen),
                    label: const Text(
                      '保存',
                      style: TextStyle(color: Colors.lightGreen),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.lightGreen,
                      shadowColor: Colors.transparent,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 清除按钮 - 玻璃质感
          GlassContainer(
            padding: const EdgeInsets.all(2),
            blur: 15,
            opacity: 0.15,
            borderOpacity: 0.2,
            child: ElevatedButton.icon(
              onPressed: _clearUserId,
              icon: const Icon(Icons.clear, color: Colors.red),
              label: const Text('清除ID', style: TextStyle(color: Colors.red)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.red,
                shadowColor: Colors.transparent,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
