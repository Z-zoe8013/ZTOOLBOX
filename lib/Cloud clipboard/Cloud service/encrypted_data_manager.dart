import 'encryption.dart' as encrypt_lib;
import 'key_management.dart' as key_lib;
import 'cloud_service.dart';

/// 加密数据管理类，处理云端加密数据的获取解密和加密上传
class EncryptedDataManager {
  /// 尝试修复损坏的Base64数据
  static String _repairBase64Data(String data) {
    // 移除所有空白字符
    String cleaned = data.replaceAll(RegExp(r'\s+'), '');

    // 如果包含冒号，分别处理IV和数据部分
    if (cleaned.contains(':')) {
      final parts = cleaned.split(':');
      if (parts.length == 2) {
        String ivPart = parts[0].trim();
        String dataPart = parts[1].trim();

        // 修复Base64填充
        ivPart = _fixBase64Padding(ivPart);
        dataPart = _fixBase64Padding(dataPart);

        return '$ivPart:$dataPart';
      }
    }

    return _fixBase64Padding(cleaned);
  }

  /// 修复Base64字符串的填充
  static String _fixBase64Padding(String base64) {
    // 移除无效字符，只保留Base64字符集
    String cleaned = base64.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');

    // 确保长度是4的倍数
    while (cleaned.length % 4 != 0) {
      cleaned += '=';
    }

    return cleaned;
  }

  /// 从云端获取数据并解密
  /// 返回包含解密后的数据和错误信息的对象（二选一）
  static Future<({String? data, String? error})> fetchAndDecryptData() async {
    try {
      // 检查是否设置了用户ID
      final bool hasUserId = await UseIdManager.hasUseId();
      if (!hasUserId) {
        return (data: null, error: '没有设置用户ID，请先在用户ID管理中设置');
      }

      // 检查是否存在密钥
      final bool hasEncryptionKey = await key_lib.KeyManager.hasKey();
      if (!hasEncryptionKey) {
        return (data: null, error: '没有可用的加密密钥，请先在密钥管理中设置密钥');
      }

      // 获取保存的密钥
      final String? encryptionKey = await key_lib.KeyManager.getSavedKey();
      if (encryptionKey == null || encryptionKey.isEmpty) {
        return (data: null, error: '密钥获取失败，可能已被删除');
      }

      // 从云端获取加密数据
      final String? encryptedData = await TextDbService.getData();
      if (encryptedData == null) {
        return (data: null, error: '云端数据获取失败，可能是网络问题或服务不可用');
      }
      if (encryptedData.isEmpty) {
        return (data: '', error: null); // 云端无数据时返回空字符串
      }

      // 解密数据
      try {
        final decryptedData = encrypt_lib.EncryptionUtils.decrypt(
          encryptedData,
          encryptionKey,
        );
        return (data: decryptedData, error: null);
      } catch (e) {
        // 尝试修复数据后再次解密
        try {
          final repairedData = _repairBase64Data(encryptedData);
          final decryptedData = encrypt_lib.EncryptionUtils.decrypt(
            repairedData,
            encryptionKey,
          );
          return (data: decryptedData, error: null);
        } catch (repairError) {
          String errorMsg = e.toString().replaceAll('Exception: ', '');

          if (errorMsg.contains('FormatException')) {
            errorMsg = '数据格式错误，可能是云端数据被损坏或使用了不同的加密方式';
          } else if (errorMsg.contains('密钥')) {
            errorMsg = '密钥错误，请检查密钥是否正确';
          } else if (errorMsg.contains('Base64')) {
            errorMsg = '数据编码错误，云端数据可能已损坏';
          }

          return (data: null, error: '解密失败：$errorMsg。建议重新上传数据。');
        }
      }
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      return (data: null, error: '处理数据时出错：$errorMsg');
    }
  }

  /// 加密数据并上传到云端
  /// [plainData] 待加密的明文数据
  /// 返回上传状态信息
  static Future<String> encryptAndUploadData(String plainData) async {
    try {
      // 检查是否设置了用户ID
      final bool hasUserId = await UseIdManager.hasUseId();
      if (!hasUserId) {
        return '上传失败：没有设置用户ID，请先设置用户ID';
      }

      // 检查是否存在密钥
      final bool hasEncryptionKey = await key_lib.KeyManager.hasKey();
      if (!hasEncryptionKey) {
        return '上传失败：没有可用的加密密钥，请先设置密钥';
      }

      // 获取保存的密钥
      final String? encryptionKey = await key_lib.KeyManager.getSavedKey();
      if (encryptionKey == null || encryptionKey.isEmpty) {
        return '上传失败：密钥获取失败';
      }

      // 加密数据
      String encryptedData;
      try {
        encryptedData = encrypt_lib.EncryptionUtils.encrypt(
          plainData,
          encryptionKey,
        );
      } catch (e) {
        return '上传失败：加密过程出错 - ${e.toString().replaceAll('Exception: ', '')}';
      }

      // 上传加密后的数据
      final bool uploadSuccess = await TextDbService.updateData(encryptedData);
      return uploadSuccess ? '上传成功：数据已加密并保存到云端' : '上传失败：云端服务响应异常，请检查网络';
    } catch (e) {
      return '上传失败：${e.toString()}';
    }
  }
}
