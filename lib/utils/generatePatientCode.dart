import 'dart:math';

Future<String> generateCode() async {
  const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  Random random = Random();
  String code = '';

  for (int i = 0; i < 6; i++) {
    int randomIndex = random.nextInt(characters.length);
    code += characters[randomIndex];
  }

  return code;
}
