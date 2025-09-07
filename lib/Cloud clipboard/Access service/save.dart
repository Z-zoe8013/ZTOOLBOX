import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'token.dart'; // 添加token.dart导入

class SaveService {
  // 保存笔记的API地址
  final String _apiUrl = "https://api.txttool.cn/netcut/note/save/";

  // 请求头配置
  final Map<String, String> _headers = {
    "Accept": "application/json, text/javascript, */*; q=0.01",
    "Accept-Encoding": "gzip, deflate, br, zstd",
    "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6",
    "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
    "Origin": "https://netcut.cn",
    "Referer": "https://netcut.cn/",
    "Sec-Ch-Ua":
        '"Chromium";v="140", "Not=A?Brand";v="24", "Microsoft Edge";v="140"',
    "Sec-Ch-Ua-Mobile": "?0",
    "Sec-Ch-Ua-Platform": '"Windows"',
    "Sec-Fetch-Dest": "empty",
    "Sec-Fetch-Mode": "cors",
    "Sec-Fetch-Site": "cross-site",
    "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36 Edg/140.0.0.0",
    "X-Requested-With": "XMLHttpRequest",
  };

  // 固定的请求参数（除了note_content之外的所有字段）
  final String _noteName = "1j4i6jp0n";
  final String _noteId = "bf00bee32f8c67cd";
  final String _expireTime = "94608000";
  final String _notePwd = "1234";
  final NoteTokenFetcher _tokenFetcher = NoteTokenFetcher(); // 添加token获取器实例

  // 简化的保存笔记方法，只需传入note_content
  Future<Map<String, dynamic>?> saveNote({required String noteContent}) async {
    try {
      final uri = Uri.parse(_apiUrl);
      print('发送保存请求到: $uri');

      // 获取最新的note_token
      final token = await _tokenFetcher.fetchLatestToken();
      if (token == null) {
        throw NetcutException('无法获取note_token');
      }

      // 构建请求体，使用固定参数 + 传入的note_content
      final Map<String, String> payload = {
        "note_name": _noteName,
        "note_id": _noteId,
        "note_content": noteContent,
        "note_token": token, // 使用动态获取的token
        "expire_time": _expireTime,
        "note_pwd": _notePwd,
      };

      final response = await http
          .post(uri, headers: _headers, body: payload)
          .timeout(const Duration(seconds: 10));

      print('保存请求返回状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
        // 解析响应体
        final data = json.decode(response.body) as Map<String, dynamic>?;

        if (data == null) {
          print('响应数据为空');
          return null;
        }

        return data;
      } else {
        throw NetcutException('保存失败，状态码: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      print('网络请求异常: $e');
      throw NetcutException('网络连接错误: ${e.message}');
    } on TimeoutException catch (_) {
      print('请求超时');
      throw NetcutException('请求超时，请稍后重试');
    } catch (e) {
      print('保存发生错误: $e');
      throw NetcutException('保存笔记失败: ${e.toString()}');
    }
  }
}

// 自定义异常类
class NetcutException implements Exception {
  final String message;

  NetcutException(this.message);

  @override
  String toString() => message;
}
