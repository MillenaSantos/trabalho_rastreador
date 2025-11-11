import 'package:flutter/material.dart';
import 'package:trabalho_rastreador/components/customButton.dart';
import 'package:trabalho_rastreador/components/customTextfield.dart';
import 'package:trabalho_rastreador/models/user_model.dart';
import 'package:trabalho_rastreador/pages/login.dart';
import 'package:trabalho_rastreador/service/auth_service.dart';
import 'package:trabalho_rastreador/utils/toastMessages.dart';

class RegisterPage extends StatelessWidget {
  RegisterPage({super.key});

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _rePasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final Color mainColor = const Color(0xFF26A69A);
  final Color backgroundColor = const Color.fromARGB(
    255,
    255,
    255,
    255,
  ); // verde suave

  Future<void> registerUser(BuildContext context) async {
    try {
      UserModel userModel = UserModel(
        name: _usernameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        rePassword: _rePasswordController.text,
      );

      await AuthService().signUp(userModel);
      await Future.delayed(const Duration(seconds: 1));

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } catch (error) {
      ToastMessage().error(message: error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 223, 223, 223),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 50),
                Text(
                  'Crie sua conta',
                  style: TextStyle(color: Colors.black87, fontSize: 24),
                ),
                const SizedBox(height: 15),
                Icon(Icons.group_add, size: 100, color: mainColor),
                const SizedBox(height: 25),
                MyTextField(
                  controller: _usernameController,
                  hintText: 'Nome de usuário',
                  obscureText: false,
                  required: true,
                ),
                const SizedBox(height: 10),
                MyTextField(
                  controller: _emailController,
                  hintText: 'E-mail',
                  obscureText: false,
                  required: true,
                ),
                const SizedBox(height: 10),
                MyTextField(
                  controller: _passwordController,
                  hintText: 'Senha',
                  obscureText: true,
                  required: true,
                ),

                const SizedBox(height: 10),
                MyTextField(
                  controller: _rePasswordController,
                  hintText: 'Digite a senha novamente',
                  obscureText: true,
                  required: true,
                ),
                const SizedBox(height: 25),
                MyButton(
                  onTap: () async {
                    if (_formKey.currentState!.validate()) {
                      await registerUser(context);
                    }
                  },
                  text: 'Cadastrar-se',
                  color: mainColor,
                  textColor: Colors.white,
                ),
                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
