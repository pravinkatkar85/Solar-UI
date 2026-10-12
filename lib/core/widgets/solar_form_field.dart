import 'package:flutter/material.dart';
import 'package:solar_ui/core/theme/app_layout.dart';

class SolarTextField extends StatelessWidget {
  const SolarTextField({
    required this.label,
    this.hint,
    this.helperText,
    this.controller,
    this.keyboardType,
    this.prefixIcon,
    this.onChanged,
    this.enabled = true,
    this.obscureText = false,
    this.maxLength,
    super.key,
  });

  final String label;
  final String? hint;
  final String? helperText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool obscureText;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      enabled: enabled,
      obscureText: obscureText,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        counterText: maxLength == null ? null : '',
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, size: AppSizes.iconMedium),
      ),
    );
  }
}
