import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/digests/sha256.dart'; // 仅保留SHA-256相关导入
// 移除所有冗余/错误导入：aes_fast.dart、padded_block_cipher_impl.dart、cbc.dart等

/// 加密解密工具类，使用AES-256-CBC算法（适配encrypt 5.0.3 + pointycastle 3.9.1）
class EncryptionUtils {
  /// 加密方法
  /// [plainText] 需要加密的明文（支持中文、特殊符号）
  /// [key] 加密密钥，长度至少为8位
  /// 返回加密后的Base64字符串（格式：IV的Base64:加密数据的Base64）
  static String encrypt(String plainText, String key) {
    try {
      // 1. 输入验证
      if (plainText.isEmpty) return '';
      if (key.length < 8) {
        throw ArgumentError('密钥长度不能少于8位，请使用更复杂的密钥');
      }

      // 2. 处理密钥：用SHA-256生成32字节密钥（适配AES-256）
      final keyBytes = Uint8List.fromList(utf8.encode(key));
      final sha256Digest = SHA256Digest();
      final keyHash = sha256Digest.process(keyBytes); // 32字节密钥

      // 3. 生成16字节随机IV（初始向量，每次加密不同，提高安全性）
      final iv = IV.fromLength(16);

      // 4. 配置AES加密器：padding参数传字符串"PKCS7"（关键修复）
      final encrypter = Encrypter(
        AES(
          Key(keyHash),
          mode: AESMode.cbc,
          padding: "PKCS7", // 修复：替换PKCS7Padding实例为字符串
        ),
      );

      // 5. 加密并组合IV和结果（方便解密时提取IV）
      final encryptedData = encrypter.encrypt(plainText, iv: iv);
      return '${base64.encode(iv.bytes)}:${encryptedData.base64}';
    } catch (e) {
      throw Exception('加密失败：${e.toString()}');
    }
  }

  /// 解密方法
  /// [encryptedText] 加密后的字符串（必须是encrypt方法返回的格式）
  /// [key] 解密密钥（必须与加密时完全一致）
  /// 返回解密后的明文
  static String decrypt(String encryptedText, String key) {
    try {
      // 1. 输入验证
      if (encryptedText.isEmpty) return '';
      if (key.length < 8) {
        throw ArgumentError('密钥长度不能少于8位，且需与加密密钥一致');
      }

      // 2. 清理可能的空白字符和换行符
      final cleanedText = encryptedText.trim().replaceAll(RegExp(r'\s+'), '');

      // 3. 分割IV和加密数据（加密结果格式：IV:加密数据）
      final parts = cleanedText.split(':');
      if (parts.length != 2) {
        throw FormatException('加密字符串格式错误，需为"IV:加密数据"格式，当前格式：$cleanedText');
      }

      // 4. 验证Base64格式
      final ivPart = parts[0].trim();
      final dataPart = parts[1].trim();

      if (!_isValidBase64(ivPart)) {
        throw FormatException('IV部分不是有效的Base64格式：$ivPart');
      }
      if (!_isValidBase64(dataPart)) {
        throw FormatException('数据部分不是有效的Base64格式：$dataPart');
      }

      // 5. 解析IV（从Base64转成IV对象）
      final iv = IV.fromBase64(ivPart);

      // 6. 处理密钥（与加密逻辑完全一致）
      final keyBytes = Uint8List.fromList(utf8.encode(key));
      final sha256Digest = SHA256Digest();
      final keyHash = sha256Digest.process(keyBytes);

      // 7. 配置AES解密器：padding参数同样传"PKCS7"
      final encrypter = Encrypter(
        AES(
          Key(keyHash),
          mode: AESMode.cbc,
          padding: "PKCS7", // 修复：替换PKCS7Padding实例为字符串
        ),
      );

      // 8. 解密并返回明文
      final encryptedData = Encrypted.fromBase64(dataPart);
      return encrypter.decrypt(encryptedData, iv: iv);
    } catch (e) {
      throw Exception('解密失败：${e.toString()}'); // 常见错误：密钥不匹配、加密串被篡改
    }
  }

  /// 验证字符串是否为有效的Base64格式
  static bool _isValidBase64(String str) {
    if (str.isEmpty) return false;

    // Base64字符集：A-Z, a-z, 0-9, +, /, =
    final base64Pattern = RegExp(r'^[A-Za-z0-9+/]*={0,2}$');

    // 检查字符集
    if (!base64Pattern.hasMatch(str)) return false;

    // 检查长度（Base64字符串长度必须是4的倍数）
    if (str.length % 4 != 0) return false;

    return true;
  }
}
