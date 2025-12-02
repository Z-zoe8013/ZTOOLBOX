import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async'; // 导入Timer
import 'encrypted_data_manager.dart';
import 'key_management.dart';
import 'package:ztoolbox/cloud_clipboard/common/prompt.dart';
import 'package:ztoolbox/cloud_clipboard/common/glass_container.dart'; // 导入玻璃容器组件
import 'package:ztoolbox/cloud_clipboard/history_record/data/clipboard_history_service.dart'; // 导入历史记录服务

class TextDbPage extends StatefulWidget {
  const TextDbPage({super.key});

  @override
  State<TextDbPage> createState() => _TextDbPageState();
}

class _TextDbPageState extends State<TextDbPage> {
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;
  late SharedPreferences _prefs;

  // 版本历史相关状态
  static const int _maxHistoryVersions = 20; // 最大历史版本数
  List<String> _textHistory = []; // 文本历史记录
  int _currentHistoryIndex = -1; // 当前历史记录索引，-1表示最新版本

  // 添加标志位，用于区分用户输入和程序化操作
  bool _isProgrammaticChange = false; // 是否为程序化更改（如撤销/前进操作）

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
    // 监听文本变化，实时保存
    _textController.addListener(_onTextChanged);
  }

  // 文本变化时的回调
  void _onTextChanged() {
    // 如果是程序化更改（如撤销/前进操作），不触发自动保存
    if (_isProgrammaticChange) {
      _isProgrammaticChange = false; // 重置标志位
      return;
    }

    // 使用防抖机制，避免过于频繁的保存
    _debounceSave();
  }

  Timer? _debounceTimer;

  // 防抖保存机制
  void _debounceSave() {
    // 取消之前的定时器
    _debounceTimer?.cancel();
    // 设置新的定时器，延迟保存
    _debounceTimer = Timer(Duration(milliseconds: 500), () {
      _saveTextToPreferences();
    });
  }

  // 限制历史记录数量
  void _limitHistoryVersions() {
    if (_textHistory.length > _maxHistoryVersions) {
      _textHistory.removeRange(0, _textHistory.length - _maxHistoryVersions);
    }
  }

  // 检查文本是否与历史记录中的最后一个条目不同
  bool _isTextDifferentFromLastHistory(String text) {
    if (text.isEmpty) return false;
    if (_textHistory.isEmpty) return true;
    return text != _textHistory.last;
  }

  // 初始化SharedPreferences
  void _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    // 加载之前保存的文本内容
    final savedText = _prefs.getString('clipboard_text') ?? '';

    // 加载历史记录
    final historyLength = _prefs.getInt('clipboard_text_history_length') ?? 0;
    _textHistory = [];
    for (int i = 0; i < historyLength; i++) {
      final historyText = _prefs.getString('clipboard_text_history_$i') ?? '';
      _textHistory.add(historyText);
    }

    // 确保历史记录数量不超过最大限制
    _limitHistoryVersions();

    // 设置当前历史索引
    _currentHistoryIndex = _prefs.getInt('clipboard_text_current_index') ?? -1;

    setState(() {
      _textController.text = savedText;
    });
  }

  // 保存文本内容到SharedPreferences
  void _saveTextToPreferences() async {
    final currentText = _textController.text;
    await _prefs.setString('clipboard_text', currentText);

    // 如果当前不是在浏览历史记录，则添加到历史记录
    if (_currentHistoryIndex == -1) {
      // 只有当文本不为空且与上一个版本不同时才添加到历史记录
      if (_isTextDifferentFromLastHistory(currentText)) {
        // 添加当前文本到历史记录
        _textHistory.add(currentText);

        // 如果历史记录超过最大数量，移除最旧的记录
        _limitHistoryVersions();
      }
    } else {
      // 如果当前在浏览历史记录，仅当内容不同时才更新当前位置的记录
      if (_currentHistoryIndex >= 0 &&
          _currentHistoryIndex < _textHistory.length &&
          currentText != _textHistory[_currentHistoryIndex]) {
        _textHistory[_currentHistoryIndex] = currentText;
      }
    }

    // 保存历史记录到SharedPreferences
    await _prefs.setInt('clipboard_text_history_length', _textHistory.length);
    for (int i = 0; i < _textHistory.length; i++) {
      await _prefs.setString('clipboard_text_history_$i', _textHistory[i]);
    }

    // 重置当前历史索引为-1（最新版本）
    _currentHistoryIndex = -1;
    await _prefs.setInt('clipboard_text_current_index', _currentHistoryIndex);
  }

  // 更新数据（加密上传）
  void _updateData() async {
    if (_textController.text.isEmpty) {
      _showSnackBar("请输入内容");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // 先存储到历史记录
    try {
      await ClipboardHistoryService().insertHistory(
        content: _textController.text,
      );
    } catch (e) {
      // 历史记录存储失败不影响上传流程
      debugPrint('历史记录存储失败: $e');
    }

    String result = await EncryptedDataManager.encryptAndUploadData(
      _textController.text,
    );

    setState(() {
      _isLoading = false;
    });

    _showSnackBar(result);

    if (result.startsWith("上传成功")) {
      _getData(saveToHistory: false); // 上传成功后刷新显示，不重复保存到历史记录
    }

    // 保存到SharedPreferences
    _saveTextToPreferences();
  }

  // 获取并解密数据
  // [saveToHistory] 是否保存到历史记录，默认为true
  void _getData({bool saveToHistory = true}) async {
    setState(() {
      _isLoading = true;
    });

    // 在获取云端数据之前，先将当前输入框内容保存到历史记录
    if (saveToHistory && _textController.text.isNotEmpty) {
      _saveToHistory(_textController.text);
    }

    final result = await EncryptedDataManager.fetchAndDecryptData();

    setState(() {
      _isLoading = false;
      if (result.error != null) {
        _textController.text = "";
        _showSnackBar("获取数据失败：${result.error}");
      } else {
        _textController.text = result.data ?? "";
        if (result.data?.isEmpty ?? true) {
          _showSnackBar("当前云端无数据");
        } else {
          // 根据参数决定是否存储获取到的数据到历史记录
          if (saveToHistory) {
            _saveToHistory(result.data!);
          }
          _showSnackBar("数据刷新成功");
        }
      }
    });

    // 保存到SharedPreferences
    _saveTextToPreferences();
  }

  // 保存到历史记录
  void _saveToHistory(String content) async {
    try {
      await ClipboardHistoryService().insertHistory(content: content);
    } catch (e) {
      debugPrint('保存历史记录失败: $e');
    }
  }

  // 复制文本框内容到剪贴板
  void _copyToClipboard() {
    if (_textController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _textController.text));
      _showSnackBar("已复制到剪贴板");
    } else {
      _showSnackBar("文本内容为空");
    }
  }

  // 从剪贴板粘贴内容
  void _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null &&
        clipboardData.text != null &&
        clipboardData.text!.isNotEmpty) {
      setState(() {
        _textController.text = clipboardData.text!;
      });

      // 保存到SharedPreferences
      _saveTextToPreferences();

      _showSnackBar("已从剪贴板粘贴内容");
    } else {
      _showSnackBar("剪贴板为空");
    }
  }

  // 后退（撤销）功能
  void _undo() {
    // 如果没有历史记录或已经在最早的历史记录，无法后退
    if (_textHistory.isEmpty || _currentHistoryIndex == 0) {
      _showSnackBar("无法后退");
      return;
    }

    setState(() {
      // 如果当前是最新版本，将当前文本保存到历史记录
      if (_currentHistoryIndex == -1) {
        // 只有当文本不为空且与上一个版本不同时才添加到历史记录
        if (_isTextDifferentFromLastHistory(_textController.text)) {
          _textHistory.add(_textController.text);

          // 如果历史记录超过最大数量，移除最旧的记录
          _limitHistoryVersions();
        }

        _currentHistoryIndex = _textHistory.length <= 1
            ? -1
            : _textHistory.length - 2;
      } else {
        _currentHistoryIndex--; // 指向前一个版本
      }

      // 更新文本框内容
      if (_currentHistoryIndex >= 0 &&
          _currentHistoryIndex < _textHistory.length) {
        _isProgrammaticChange = true; // 设置程序化更改标志
        _textController.text = _textHistory[_currentHistoryIndex];
      }

      // 保存当前索引到SharedPreferences
      _prefs.setInt('clipboard_text_current_index', _currentHistoryIndex);
    });

    _showSnackBar("已后退到版本 ${_currentHistoryIndex + 1}/${_textHistory.length}");
  }

  // 前进功能
  void _redo() {
    // 如果没有历史记录或已经在最新版本，无法前进
    if (_textHistory.isEmpty ||
        _currentHistoryIndex == -1 ||
        _currentHistoryIndex >= _textHistory.length - 1) {
      _showSnackBar("无法前进");
      return;
    }

    setState(() {
      _currentHistoryIndex++; // 指向后一个版本

      // 更新文本框内容
      if (_currentHistoryIndex >= 0 &&
          _currentHistoryIndex < _textHistory.length) {
        _isProgrammaticChange = true; // 设置程序化更改标志
        _textController.text = _textHistory[_currentHistoryIndex];
      } else {
        // 如果超出范围，回到最新版本
        _currentHistoryIndex = -1;
        _isProgrammaticChange = true; // 设置程序化更改标志
        _textController.text = _prefs.getString('clipboard_text') ?? '';
      }

      // 保存当前索引到SharedPreferences
      _prefs.setInt('clipboard_text_current_index', _currentHistoryIndex);
    });

    if (_currentHistoryIndex == -1) {
      _showSnackBar("已前进到最新版本");
    } else {
      _showSnackBar(
        "已前进到版本 ${_currentHistoryIndex + 1}/${_textHistory.length}",
      );
    }
  }

  // 检查是否可以后退
  bool _canUndo() {
    // 如果没有历史记录，则不能后退
    if (_textHistory.isEmpty) return false;

    // 如果当前在最新版本，或者当前不在第一个历史记录，则可以后退
    return _currentHistoryIndex == -1 || _currentHistoryIndex > 0;
  }

  // 检查是否可以前进
  bool _canRedo() {
    // 如果没有历史记录，则不能前进
    if (_textHistory.isEmpty) return false;

    // 如果当前不在最新版本，且还没到历史记录的最后一个版本，则可以前进
    return _currentHistoryIndex != -1 &&
        _currentHistoryIndex < _textHistory.length - 1;
  }

  // 显示提示信息
  void _showSnackBar(String message) {
    ToastUtil.showMessage(context, message);
  }

  @override
  void dispose() {
    // 取消防抖定时器
    _debounceTimer?.cancel();
    // 释放 TextEditingController
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // 设置主背景为纯黑色
      drawer: const SettingsDrawer(), // 使用集成设置抽屉
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 玻璃质感标题栏 - 深色主题
                  GlassContainer(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                    blur: 15, // 增强模糊效果以适应深色背景
                    opacity: 0.15, // 降低透明度以适应深色主题
                    borderOpacity: 0.2, // 边框透明度
                    child: const Center(
                      child: Text(
                        '云剪贴板',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // 文字改为白色
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 玻璃质感输入框 - 深色主题
                  GlassContainer(
                    padding: const EdgeInsets.all(0),
                    blur: 15,
                    opacity: 0.15,
                    borderOpacity: 0.2,
                    child: TextField(
                      controller: _textController,
                      maxLines: 12,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                        contentPadding: EdgeInsets.all(12),
                      ),
                      enabled: !_isLoading,
                      style: const TextStyle(color: Colors.white), // 输入文字白色
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 主要操作按钮行 - 使用玻璃质感
                  Row(
                    children: [
                      Expanded(
                        child: GlassContainer(
                          padding: const EdgeInsets.all(2),
                          blur: 15,
                          opacity: 0.15,
                          borderOpacity: 0.2,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _getData,
                            icon: const Icon(
                              Icons.download,
                              color: Colors.lightGreen,
                            ),
                            label: const Text(
                              "获取",
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
                      const SizedBox(width: 10),
                      Expanded(
                        child: GlassContainer(
                          padding: const EdgeInsets.all(2),
                          blur: 15,
                          opacity: 0.15,
                          borderOpacity: 0.2,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _updateData,
                            icon: const Icon(
                              Icons.upload,
                              color: Colors.lightBlue,
                            ),
                            label: const Text(
                              "更新",
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
                    ],
                  ),

                  const SizedBox(height: 10),

                  // 撤销/前进按钮行 - 玻璃质感
                  Row(
                    children: [
                      Expanded(
                        child: GlassContainer(
                          padding: const EdgeInsets.all(2),
                          blur: 15,
                          opacity: 0.15,
                          borderOpacity: 0.2,
                          child: SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading || !_canUndo()
                                  ? null
                                  : _undo,
                              icon: const Icon(
                                Icons.undo,
                                color: Colors.orange,
                              ),
                              label: const Text(
                                "后退",
                                style: TextStyle(color: Colors.orange),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.orange,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
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
                          child: SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading || !_canRedo()
                                  ? null
                                  : _redo,
                              icon: const Icon(
                                Icons.redo,
                                color: Colors.orange,
                              ),
                              label: const Text(
                                "前进",
                                style: TextStyle(color: Colors.orange),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.orange,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // 复制按钮 - 玻璃质感
                  GlassContainer(
                    padding: const EdgeInsets.all(2),
                    blur: 15,
                    opacity: 0.15,
                    borderOpacity: 0.2,
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _copyToClipboard,
                        icon: const Icon(Icons.copy, color: Colors.purple),
                        label: const Text(
                          "复制",
                          style: TextStyle(color: Colors.purple),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.purple,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 粘贴按钮 - 玻璃质感
                  GlassContainer(
                    padding: const EdgeInsets.all(2),
                    blur: 15,
                    opacity: 0.15,
                    borderOpacity: 0.2,
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _pasteFromClipboard,
                        icon: const Icon(
                          Icons.save_alt,
                          color: Colors.lightGreen,
                        ),
                        label: const Text(
                          "粘贴",
                          style: TextStyle(color: Colors.lightGreen),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.lightGreen,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 设置管理按钮 - 玻璃质感
                  const SizedBox(height: 10),
                  GlassContainer(
                    padding: const EdgeInsets.all(2),
                    blur: 15,
                    opacity: 0.15,
                    borderOpacity: 0.2,
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: Builder(
                        builder: (BuildContext scaffoldContext) {
                          return ElevatedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () =>
                                      Scaffold.of(scaffoldContext).openDrawer(),
                            icon: const Icon(
                              Icons.settings,
                              color: Colors.grey,
                            ),
                            label: const Text(
                              "设置管理",
                              style: TextStyle(color: Colors.grey),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.grey,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 加载指示器 - 使用Stack覆盖在内容之上
            if (_isLoading)
              Container(
                color: Colors.black38, // 半透明黑色背景
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.blue),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
