import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// 存储工具类：管理useID的本地存储
class UseIdManager {
  // 存储键名
  static const String _kUseIdKey = 'textdb_use_id';

  // 保存useID到本地
  static Future<void> saveUseId(String useId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUseIdKey, useId);
  }

  // 从本地获取useID
  static Future<String?> getUseId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kUseIdKey);
  }

  // 检查是否已设置用户ID
  static Future<bool> hasUseId() async {
    final userId = await getUseId();
    return userId != null && userId.isNotEmpty;
  }

  // 清除本地存储的useID
  static Future<void> clearUseId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUseIdKey);
  }
}

class TextDbService {
  // 基础URL
  static const String _baseUrl = "https://textdb.online";

  /// 更新数据到textdb.online
  /// [value] - 要更新的值
  /// 返回是否更新成功
  static Future<bool> updateData(String value) async {
    try {
      final useId = await UseIdManager.getUseId();
      if (useId == null || useId.isEmpty) return false;

      // 对整个字符串进行Base64编码，避免URL特殊字符问题
      final encodedValue = _base64UrlSafeEncode(value);
      final url = Uri.parse('$_baseUrl/update/?key=$useId&value=$encodedValue');

      final response = await http.get(url);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Base64 URL安全编码
  static String _base64UrlSafeEncode(String input) {
    final bytes = input.codeUnits;
    final base64 = base64Encode(bytes);
    // 替换URL不安全字符
    return base64.replaceAll('+', '-').replaceAll('/', '_').replaceAll('=', '');
  }

  /// Base64 URL安全解码
  static String _base64UrlSafeDecode(String input) {
    // 恢复标准Base64格式
    String base64 = input.replaceAll('-', '+').replaceAll('_', '/');

    // 补充填充字符
    while (base64.length % 4 != 0) {
      base64 += '=';
    }

    final bytes = base64Decode(base64);
    return String.fromCharCodes(bytes);
  }

  /// 从textdb.online获取数据
  /// 返回获取到的值，如果失败则返回null
  static Future<String?> getData() async {
    try {
      final useId = await UseIdManager.getUseId();
      if (useId == null || useId.isEmpty) return null;

      // 构建完整的URL
      final url = Uri.parse('$_baseUrl/$useId');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final rawData = response.body.trim();

        if (rawData.isEmpty) return '';

        try {
          return _base64UrlSafeDecode(rawData);
        } catch (decodeError) {
          return rawData;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
