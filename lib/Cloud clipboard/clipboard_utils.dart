import 'package:flutter/services.dart';

class ClipboardUtils {
  /// 读取剪贴板内容
  static Future<String?> getClipboardText() async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }

  /// 写入内容到剪贴板
  static Future<void> setClipboardText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// 检查剪贴板是否有内容
  static Future<bool> hasClipboardContent() async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text != null && data!.text!.isNotEmpty;
  }
}
