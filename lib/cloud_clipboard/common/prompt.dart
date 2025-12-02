import 'package:flutter/material.dart';
import 'glass_container.dart';

/// 消息提示工具类 - 玻璃质感优化版
/// 功能特点：
/// 1. 真正的玻璃质感设计，使用高级模糊和边框效果
/// 2. 未满3秒时，新提示会立即替换旧提示
/// 3. 自动适应内容大小，垂直居中显示
/// 4. 3秒后自动消失
/// 5. 优雅的动画效果
class ToastUtil {
  static OverlayEntry? _overlayEntry;
  static Future<void>? _delayRemoveTask;
  static bool _isShowing = false;

  /// 显示提示消息
  /// [context] 上下文
  /// [message] 要显示的消息内容
  static void showMessage(BuildContext context, String message) {
    // 检查上下文是否有效
    if (!context.mounted) return;

    // 移除已存在的提示（无论是否到期）
    _removeOverlay();

    // 创建新的提示层
    _overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(message: message),
    );

    // 将提示层插入到页面中
    Overlay.of(context).insert(_overlayEntry!);
    _isShowing = true;

    // 设置3秒后自动移除 - 修复：移除对context.mounted的依赖
    _delayRemoveTask = Future.delayed(const Duration(seconds: 3), () {
      // 直接移除覆盖层，不再检查原始上下文
      _removeOverlay();
    });
  }

  /// 移除提示层
  static void _removeOverlay() {
    // 取消延迟任务
    if (_delayRemoveTask != null) {
      _delayRemoveTask!.timeout(const Duration(seconds: 0), onTimeout: () {});
      _delayRemoveTask = null;
    }

    // 移除覆盖层
    if (_overlayEntry != null && _overlayEntry!.mounted) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    _isShowing = false;
  }

  /// 检查Toast是否正在显示
  static bool get isShowing => _isShowing;
}

/// 自定义Toast Widget，实现玻璃质感效果
class _ToastWidget extends StatefulWidget {
  final String message;

  const _ToastWidget({required this.message});

  @override
  __ToastWidgetState createState() => __ToastWidgetState();
}

class __ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: Padding(
            // 左右边距，限制最大宽度
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: GlassContainer(
              blur: 15.0,
              opacity: 0.2,
              borderOpacity: 0.3,
              borderRadius: 16.0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Text(
                widget.message,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.none,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
