import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

class NoteTokenFetcher {
  // 固定参数
  final String _noteName = "1j4i6jp0n";
  final String _notePwd = "1234";
  final String _infoApiUrl = "https://api.txttool.cn/netcut/note/info/";

  // 请求头
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

  // 获取最新 note_token 的方法
  Future<String?> fetchLatestToken() async {
    try {
      final uri = Uri.parse(_infoApiUrl);
      final payload = {"note_name": _noteName, "note_pwd": _notePwd};

      print("正在从 $_infoApiUrl 获取 token...");

      final response = await http
          .post(uri, headers: _headers, body: payload)
          .timeout(const Duration(seconds: 10));

      print("服务器响应状态码: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>?;

        if (data == null) {
          throw Exception("响应数据为空");
        }

        // 提取 token（根据实际响应结构调整字段路径）
        if (data['status'] == 1 && data['data'] is Map) {
          final token = data['data']['note_token'] as String?;
          return token;
        } else {
          throw Exception("响应状态异常或数据结构不符，status: ${data['status']}");
        }
      } else {
        throw Exception("请求失败，状态码: ${response.statusCode}");
      }
    } on TimeoutException {
      throw Exception("请求超时（10秒）");
    } on http.ClientException catch (e) {
      throw Exception("网络错误: ${e.message}");
    } catch (e) {
      throw Exception("处理过程出错: ${e.toString()}");
    }
  }
}
