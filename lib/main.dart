import 'package:flutter/material.dart';
import 'Cloud clipboard/Cloud service/index.dart';

// 应用程序入口点
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

/// 主应用组件
/// 配置应用程序的主题和初始页面
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: TextDbPage(), // 更改主页为ClipboardPage
    );
  }
}
