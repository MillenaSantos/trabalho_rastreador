import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:trabalho_rastreador/components/customButton.dart';
import 'package:trabalho_rastreador/components/customTextfield.dart';
import 'package:trabalho_rastreador/pages/home.dart';
import 'package:trabalho_rastreador/pages/register.dart';
import 'package:trabalho_rastreador/service/auth_service.dart';
import 'package:trabalho_rastreador/utils/toastMessages.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController(text: "teste@tes.com");
  final passwordController = TextEditingController(text: "abc123");
  final Color mainColor = const Color(0xFF26A69A); // verde principal
  final Color backgroundColor = const Color(0xFFE0F2F1); // verde suave

  bool isLoading = false;

  void signIn() async {
    setState(() => isLoading = true);
    try {
      await AuthService().signIn(
        email: emailController.text,
        password: passwordController.text,
      );
      // StreamBuilder vai detectar mudança de login e navegar
    } catch (error) {
      ToastMessage().error(message: error.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            // Usuário logado → Home
            if (snapshot.connectionState == ConnectionState.active &&
                snapshot.data != null) {
              // Navega para HomePage removendo todas as rotas
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomePage()),
                  (route) => false,
                );
              });
              return const SizedBox.shrink();
            }

            // Tela de login
            return SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 100),
                      Image.asset(
                        'assets/images/trace.png',
                        width: 220, // ajuste se quiser maior/menor
                      ),
                      const SizedBox(height: 50),
                      Icon(Icons.lock, size: 100, color: mainColor),
                      const SizedBox(height: 20),
                      Text(
                        'Bem vindo de volta!',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 25),
                      MyTextField(
                        controller: emailController,
                        hintText: 'Email',
                        obscureText: false,
                        required: true,
                      ),
                      const SizedBox(height: 10),
                      MyTextField(
                        controller: passwordController,
                        hintText: 'Senha',
                        obscureText: true,
                        required: true,
                      ),
                      const SizedBox(height: 25),
                      isLoading
                          ? const CircularProgressIndicator()
                          : MyButton(
                            onTap: signIn,
                            text: 'Entrar',
                            color: mainColor,
                          ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Não possui conta?"),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RegisterPage(),
                                  ),
                                ),
                            child: Text(
                              'Registre-se',
                              style: TextStyle(
                                color: mainColor,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
