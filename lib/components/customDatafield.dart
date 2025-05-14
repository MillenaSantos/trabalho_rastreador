import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trabalho_rastreador/utils/form/validators.dart';

class MyDateField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool required;

  const MyDateField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.required,
  });

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Selecione a data',
      locale: const Locale("pt", "BR"),
    );

    if (pickedDate != null) {
      final formatted = DateFormat('dd/MM/yyyy').format(pickedDate);
      controller.text = formatted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      validator: required ? FormValidators().required : null,
      onTap: () async {
        try {
          _selectDate(context);
        } catch (e, stackTrace) {
          print('Erro ao salvar: $e');
          print('StackTrace: $stackTrace');
        }
      },
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade500),
        filled: true,
        fillColor: Colors.grey.shade200,
        suffixIcon: const Icon(Icons.calendar_today),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue.shade400),
        ),
      ),
    );
  }
}
