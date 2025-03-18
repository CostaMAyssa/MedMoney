import 'package:flutter/material.dart';

class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 768;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 768 &&
      MediaQuery.of(context).size.width < 1024;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  static double getScreenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double getScreenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static Widget whenMobile(BuildContext context, Widget widget) {
    return isMobile(context) ? widget : const SizedBox.shrink();
  }

  static Widget whenTablet(BuildContext context, Widget widget) {
    return isTablet(context) ? widget : const SizedBox.shrink();
  }

  static Widget whenDesktop(BuildContext context, Widget widget) {
    return isDesktop(context) ? widget : const SizedBox.shrink();
  }

  static Widget whenNotMobile(BuildContext context, Widget widget) {
    return !isMobile(context) ? widget : const SizedBox.shrink();
  }

  static T valueBasedOnSize<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet ?? desktop;
    return desktop;
  }
}

// Extensão para facilitar o uso de valores responsivos
extension ResponsiveExtension on BuildContext {
  bool get isMobile => Responsive.isMobile(this);
  bool get isTablet => Responsive.isTablet(this);
  bool get isDesktop => Responsive.isDesktop(this);
  double get screenWidth => Responsive.getScreenWidth(this);
  double get screenHeight => Responsive.getScreenHeight(this);
  
  // Valores de espaçamento responsivos
  double get spacingXS => isMobile ? 4 : 8;
  double get spacingS => isMobile ? 8 : 16;
  double get spacingM => isMobile ? 16 : 24;
  double get spacingL => isMobile ? 24 : 32;
  double get spacingXL => isMobile ? 32 : 48;
  
  // Tamanhos de fonte responsivos
  double get fontSizeS => isMobile ? 12 : 14;
  double get fontSizeM => isMobile ? 14 : 16;
  double get fontSizeL => isMobile ? 16 : 18;
  double get fontSizeXL => isMobile ? 20 : 24;
  double get fontSizeXXL => isMobile ? 24 : 32;
} 