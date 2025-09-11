import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'encrypted_data_manager.dart';
import 'key_management.dart';
import '../prompt.dart';
import '../glass_container.dart'; // 导入玻璃容器组件

class TextDbPage extends StatefulWidget {
  const TextDbPage({super.key});

  @override
  State<TextDbPage> createState() => _TextDbPageState();
}

class _TextDbPageState extends State<TextDbPage> {
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getData(); // 页面初始化时加载数据
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

    String result = await EncryptedDataManager.encryptAndUploadData(
      _textController.text,
    );

    setState(() {
      _isLoading = false;
    });

    _showSnackBar(result);

    if (result.startsWith("上传成功")) {
      _getData(); // 上传成功后刷新显示
    }
  }

  // 获取并解密数据
  void _getData() async {
    setState(() {
      _isLoading = true;
    });

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
          _showSnackBar("数据刷新成功");
        }
      }
    });
  }

  // 获取数据并自动复制到剪贴板
  void _getDataAndCopy() async {
    setState(() {
      _isLoading = true;
    });

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
          // 自动复制到剪贴板
          Clipboard.setData(ClipboardData(text: result.data!));
          _showSnackBar("数据已获取并复制");
        }
      }
    });
  }

  // 一键粘贴并保存
  void _pasteAndSave() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null &&
        clipboardData.text != null &&
        clipboardData.text!.isNotEmpty) {
      setState(() {
        _textController.text = clipboardData.text!;
        _isLoading = true;
      });

      String result = await EncryptedDataManager.encryptAndUploadData(
        clipboardData.text!,
      );

      setState(() {
        _isLoading = false;
      });

      _showSnackBar(result);

      if (result.startsWith("上传成功")) {
        _getData();
      }
    } else {
      _showSnackBar("剪贴板为空，无法保存");
    }
  }

  // 显示提示信息
  void _showSnackBar(String message) {
    ToastUtil.showMessage(context, message);
  }

  @override
  void dispose() {
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
                            onPressed: _isLoading ? null : _updateData,
                            icon: const Icon(
                              Icons.upload,
                              color: Colors.lightBlue,
                            ),
                            label: const Text(
                              "加密并更新",
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
                            onPressed: _isLoading ? null : _getDataAndCopy,
                            icon: const Icon(
                              Icons.download,
                              color: Colors.lightGreen,
                            ),
                            label: const Text(
                              "获取并复制",
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

                  const SizedBox(height: 10),

                  // 一键粘贴保存按钮 - 玻璃质感
                  GlassContainer(
                    padding: const EdgeInsets.all(2),
                    blur: 15,
                    opacity: 0.15,
                    borderOpacity: 0.2,
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _pasteAndSave,
                        icon: const Icon(
                          Icons.save_alt,
                          color: Colors.lightGreen,
                        ),
                        label: const Text(
                          "粘贴并上传",
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
