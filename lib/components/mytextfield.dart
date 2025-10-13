import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MyTextFormField extends StatelessWidget {
  const MyTextFormField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    this.leadingIcon,
    this.trailingIcon,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
    this.readOnly = false,
    this.onTap,
  });

  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final bool readOnly;
  final VoidCallback? onTap;

  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    const whiteColor = Colors.white;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(color: whiteColor),
      cursorColor: whiteColor,
      decoration: InputDecoration(
        fillColor: const Color.fromARGB(255, 40, 43, 50),
        filled: true,
        prefixIcon: leadingIcon,
        // iconColor: Colors.,
        prefixIconColor: whiteColor,
        suffixIcon: trailingIcon,
        suffixIconColor: whiteColor,
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white54),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 40, 43, 50),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: whiteColor),
          borderRadius: BorderRadius.circular(12),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
