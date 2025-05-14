class FormValidators {
  String? required(String? value) {
    if (value == null || value.isEmpty) {
      return 'Campo Obrigatório';
    }

    return null;
  }
}
