import 'package:flutter/material.dart';
import 'Access service/visit.dart';
import 'Access service/save.dart';

/// 剪贴板页面
/// 提供复制和粘贴文本的功能界面
class ClipboardPage extends StatefulWidget {
  const ClipboardPage({super.key});

  @override
  State<ClipboardPage> createState() => _ClipboardPageState();
}

class _ClipboardPageState extends State<ClipboardPage> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clipboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Copy Text',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // 文本输入框，用于输入需要复制的文本
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter text to copy',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 复制按钮
                ElevatedButton(
                  onPressed: () {
                    // 复制文本的逻辑
                  },
                  child: const Text('Copy'),
                ),
                // 粘贴按钮
                ElevatedButton(
                  onPressed: () {
                    // 粘贴文本的逻辑
                  },
                  child: const Text('Paste'),
                ),
                // 刷新按钮
                ElevatedButton(
                  onPressed: () async {
                    // 触发访问网页并输出到控制台
                    final service = NetcutService();
                    final result = await service.fetchNoteInfo();
                    setState(() {
                      // 将 Map<String, dynamic> 转换为 String
                      _textController.text = result.toString();
                    });
                  },
                  child: const Text('Refresh'),
                ),
                // 保存按钮
                ElevatedButton(
                  onPressed: () async {
                    // 保存文本的逻辑
                    try {
                      final saveService = SaveService();
                      final result = await saveService.saveNote(
                        noteContent: _textController.text,
                      );

                      if (result != null && !result.toString().contains('失效')) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text('保存成功')));
                      } else {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text('保存失败')));
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('保存出错: $e')));
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
