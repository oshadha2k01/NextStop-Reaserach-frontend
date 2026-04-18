import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.maxLength,
    super.key,
  });

  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        hintText: hint,
        counterText: maxLength == null ? null : '',
        prefixIcon: Icon(prefixIcon, color: AppColors.primary),
      ),
    );
  }
}
