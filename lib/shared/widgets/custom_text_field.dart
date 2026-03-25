import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';

enum ValidatorType { text, email, password, confirmPassword, name, phone }

class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final TextEditingController? passwordController;
  final AutovalidateMode autovalidateMode;
  final String? label;
  final String? hint;
  final ValidatorType validatorType;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool isPasswordField;
  final TextInputAction textInputAction;
  final FocusNode? focusNode;
  final VoidCallback? onEditingComplete;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final bool isOptional;
  final int maxLines;
  final Iterable<String>? autofillHints;

  const CustomTextField({
    super.key,
    this.controller,
    this.passwordController,
    this.label,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.isPasswordField = false,
    this.textInputAction = TextInputAction.next,
    this.focusNode,
    this.onEditingComplete,
    this.prefixIcon,
    this.suffixIcon,
    this.validatorType = ValidatorType.text,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.onChanged,
    this.isOptional = false,
    this.maxLines = 1,
    this.autofillHints,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

  String? _validate(String? value) {
    if (widget.isOptional && (value == null || value.trim().isEmpty)) {
      return null;
    }
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }

    return switch (widget.validatorType) {
      ValidatorType.email => _validateEmail(value),
      ValidatorType.password => _validatePassword(value),
      ValidatorType.confirmPassword => _validateConfirmPassword(value),
      ValidatorType.name => _validateName(value),
      ValidatorType.phone => _validatePhone(value),
      ValidatorType.text => null,
    };
  }

  String? _validateEmail(String value) {
    final regex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(value.trim()) ? null : 'Enter a valid email';
  }

  String? _validatePassword(String value) {
    return value.length < 8 ? 'Password must be at least 8 characters' : null;
  }

  String? _validateConfirmPassword(String value) {
    if (widget.passwordController == null) return null;
    return value != widget.passwordController!.text
        ? 'Passwords do not match'
        : null;
  }

  String? _validateName(String value) {
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
      return 'Name must contain only letters';
    }
    return null;
  }

  String? _validatePhone(String value) {
    final regex = RegExp(r'^\+?[0-9]{10,15}$');
    return regex.hasMatch(value.trim()) ? null : 'Enter a valid phone number';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6.h),
        ],
        TextFormField(
          controller: widget.controller,
          validator: _validate,
          autovalidateMode: widget.autovalidateMode,
          keyboardType: widget.keyboardType,
          obscureText: _isObscured,
          textInputAction: widget.textInputAction,
          focusNode: widget.focusNode,
          onEditingComplete: widget.onEditingComplete,
          onChanged: widget.onChanged,
          maxLines: widget.maxLines,
          autofillHints: widget.autofillHints,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.isPasswordField
                ? IconButton(
                    icon: Icon(
                      _isObscured ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => setState(() => _isObscured = !_isObscured),
                  )
                : widget.suffixIcon,
          ),
        ),
      ],
    );
  }
}
