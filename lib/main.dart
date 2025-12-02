import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'navigation_bar/navigation_bar.dart';
import 'cloud_clipboard/history_record/provider/clipboard_provider.dart';

// 应用程序入口点
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider(
      create: (context) => ClipboardProvider(),
      child: const MyApp(),
    ),
  );
}

/// 主应用组件
/// 配置应用程序的主题和初始页面
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ztoolbox', // 适配业务场景修改标题
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const ClipboardNavigationBar(), // 使用导航栏作为主页面
    );
  }
}
