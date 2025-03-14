import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/responsive.dart';

enum ButtonType { primary, secondary, outline, text }
enum ButtonSize { small, medium, large }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final ButtonType type;
  final ButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.padding,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Definir cores com base no tipo
    Color backgroundColor;
    Color textColor;
    Color borderColor;

    switch (type) {
      case ButtonType.primary:
        backgroundColor = AppTheme.primaryColor;
        textColor = Colors.white;
        borderColor = AppTheme.primaryColor;
        break;
      case ButtonType.secondary:
        backgroundColor = AppTheme.secondaryColor;
        textColor = Colors.white;
        borderColor = AppTheme.secondaryColor;
        break;
      case ButtonType.outline:
        backgroundColor = Colors.transparent;
        textColor = AppTheme.primaryColor;
        borderColor = AppTheme.primaryColor;
        break;
      case ButtonType.text:
        backgroundColor = Colors.transparent;
        textColor = AppTheme.primaryColor;
        borderColor = Colors.transparent;
        break;
    }

    // Definir tamanho com base no parâmetro
    EdgeInsetsGeometry buttonPadding;
    double fontSize;
    double iconSize;

    switch (size) {
      case ButtonSize.small:
        buttonPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
        fontSize = 14;
        iconSize = 18;
        break;
      case ButtonSize.medium:
        buttonPadding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14);
        fontSize = 16;
        iconSize = 20;
        break;
      case ButtonSize.large:
        buttonPadding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
        fontSize = 18;
        iconSize = 24;
        break;
    }

    // Ajustar para dispositivos móveis
    if (Responsive.isMobile(context)) {
      buttonPadding = EdgeInsets.symmetric(
        horizontal: buttonPadding.horizontal * 0.8,
        vertical: buttonPadding.vertical * 0.8,
      );
      fontSize *= 0.9;
      iconSize *= 0.9;
    }

    // Substituir padding se fornecido
    buttonPadding = padding ?? buttonPadding;

    // Construir o botão
    Widget buttonChild;
    if (isLoading) {
      buttonChild = SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    } else if (icon != null) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: textColor),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      );
    } else {
      buttonChild = Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: 0.5,
        ),
      );
    }

    // Construir o botão com base no tipo
    Widget button;
    final double radius = borderRadius ?? 12.0;

    if (type == ButtonType.text) {
      button = TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          padding: buttonPadding,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        child: buttonChild,
      );
    } else if (type == ButtonType.outline) {
      button = OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          padding: buttonPadding,
          foregroundColor: textColor,
          side: BorderSide(color: borderColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        child: buttonChild,
      );
    } else {
      button = ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          padding: buttonPadding,
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        child: buttonChild,
      );
    }

    // Aplicar largura total se necessário
    if (fullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }
} 