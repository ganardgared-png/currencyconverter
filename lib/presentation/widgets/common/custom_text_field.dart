import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? initialValue;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  final bool readOnly;
  final bool formatAsCurrency;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  
  const CustomTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.initialValue,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.readOnly = false,
    this.formatAsCurrency = false,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
  });
  
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      minLines: minLines,
      enabled: enabled,
      readOnly: readOnly,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon != null
            ? IconButton(
                icon: Icon(suffixIcon),
                onPressed: onSuffixTap,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onChanged: (value) {
        if (formatAsCurrency && controller != null) {
          final ctrl = controller!;
          final normalized = value.replaceAll(',', '');
          final parts = normalized.split('.');
          final integerDigits = parts[0].replaceAll(RegExp('[^0-9]'), '');
          if (integerDigits.isEmpty) {
            ctrl.text = '';
            ctrl.selection = const TextSelection.collapsed(offset: 0);
            if (onChanged != null) {
              onChanged!('');
            }
            return;
          }

          final formattedInt = integerDigits.replaceAllMapped(
            RegExp(r'\B(?=(\d{3})+(?!\d))'),
            (match) => ',',
          );
          final formattedValue = parts.length > 1
              ? '$formattedInt.${parts[1].replaceAll(RegExp('[^0-9]'), '')}'
              : formattedInt;

          if (formattedValue != value) {
            final cursorPosition = ctrl.selection.baseOffset;
            ctrl.text = formattedValue;
            ctrl.selection = TextSelection.collapsed(
              offset: (cursorPosition + (formattedValue.length - value.length)).clamp(0, formattedValue.length),
            );
            if (onChanged != null) {
              onChanged!(formattedValue);
            }
            return;
          }
        }

        if (onChanged != null) {
          onChanged!(value);
        }
      }
    );
  }
}