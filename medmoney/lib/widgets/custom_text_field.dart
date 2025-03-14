import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/theme.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool obscureText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final bool readOnly;
  final VoidCallback? onTap;
  final int? maxLines;
  final int? minLines;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? initialValue;
  final bool enabled;
  final EdgeInsetsGeometry? contentPadding;
  final TextCapitalization textCapitalization;
  final String? errorText;
  final String? helperText;
  final bool isDense;

  const CustomTextField({
    Key? key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    this.minLines,
    this.inputFormatters,
    this.onChanged,
    this.focusNode,
    this.autofocus = false,
    this.initialValue,
    this.enabled = true,
    this.contentPadding,
    this.textCapitalization = TextCapitalization.none,
    this.errorText,
    this.helperText,
    this.isDense = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: maxLines,
          minLines: minLines,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          focusNode: focusNode,
          autofocus: autofocus,
          enabled: enabled,
          textCapitalization: textCapitalization,
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textPrimaryColor,
          ),
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            helperText: helperText,
            isDense: isDense,
            contentPadding: contentPadding ?? 
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            prefixIcon: prefixIcon != null 
                ? Icon(
                    prefixIcon,
                    color: AppTheme.textSecondaryColor,
                  ) 
                : null,
            suffixIcon: suffixIcon != null
                ? IconButton(
                    icon: Icon(
                      suffixIcon,
                      color: AppTheme.primaryColor,
                    ),
                    onPressed: onSuffixIconPressed,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.errorColor, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.errorColor, width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFF1A1A4F), // Um pouco mais claro que o fundo principal
            hintStyle: TextStyle(
              color: AppTheme.textSecondaryColor.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
} 