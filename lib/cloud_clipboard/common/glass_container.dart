import 'dart:ui';
import 'package:flutter/material.dart';

/// 通用玻璃质感容器
class GlassContainer extends StatelessWidget {
  final Widget child; // 容器内部内容
  final double blur; // 模糊程度（默认15）
  final double opacity; // 底色不透明度（默认0.2）
  final double borderOpacity; // 边框不透明度（默认0.3）
  final double borderRadius; // 圆角（默认16）
  final EdgeInsetsGeometry padding; // 内边距（默认16）

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 15.0,
    this.opacity = 0.2,
    this.borderOpacity = 0.3,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacity),
            border: Border.all(
              color: Colors.white.withValues(alpha: borderOpacity),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: opacity + 0.1),
                Colors.white.withValues(alpha: opacity - 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: child,
        ),
      ),
    );
  }
}