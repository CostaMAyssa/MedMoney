import 'package:flutter/material.dart';
import '../utils/responsive.dart';

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final double maxWidth;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.backgroundColor,
    this.padding,
    this.maxWidth = 1200,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      padding: padding,
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.isMobile(context) ? 16 : 24,
          ),
          child: child,
        ),
      ),
    );
  }
} 