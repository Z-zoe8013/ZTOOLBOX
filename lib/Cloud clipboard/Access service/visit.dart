import 'dart:convert';
import 'package:http/http.dart' as http;

class NetcutService {
  // 固定的API地址
  final String _apiUrl = "https://api.txttool.cn/netcut/note/info/";

  // 固定的请求负载
  final Map<String, String> _fixedPayload = {
    "note_name": "1j4i6jp0n",
    "note_pwd": "1234",
  };

  // 固定的请求头
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
  };

  // 发送请求的方法
  Future<dynamic> fetchNoteInfo() async {
    try {
      final uri = Uri.parse(_apiUrl);
      final response = await http
          .post(uri, headers: _headers, body: _fixedPayload)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // 解析响应体
        final data = json.decode(response.body);

        // 检查返回数据结构并提取所需字段
        if (data != null && data is Map<String, dynamic>) {
          // 检查是否有status字段且为成功状态
          if (data['status'] == 1 && data['data'] != null) {
            // 从data字段中提取内容
            final noteData = data['data'];
            if (noteData is Map<String, dynamic>) {
              // 只返回note_content
              return noteData['note_content'];
            }
          }
        }
        return data;
      } else {
        throw Exception('请求失败，状态码: ${response.statusCode}');
      }
    } catch (e) {
      print('请求发生错误: $e');
      return null;
    }
  }
}
