import 'package:flutter/material.dart';
import 'package:trabalho_rastreador/utils/form/validators.dart';

class MyTextField extends StatelessWidget {
  final controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool required;

  const MyTextField({
    super.key,
    this.keyboardType = TextInputType.text,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    required this.required,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      validator: required ? FormValidators().required : null,
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.grey.shade400,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.blue.shade400,
          ),
        ),
        fillColor: Colors.grey.shade200,
        filled: true,
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey.shade500,
        ),
      ),
    );
  }
}
