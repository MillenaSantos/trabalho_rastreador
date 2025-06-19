import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:trabalho_rastreador/models/user_model.dart';

class AuthService {
  Future<void> signUp(UserModel user) async {
    try {
      if (user.email.trim().isEmpty ||
          user.name.trim().isEmpty ||
          user.password.trim().isEmpty ||
          (user.rePassword != null && user.rePassword!.isEmpty)) {
        throw ErrorDescription('Campos obrigatórios não preenchidos!');
      }

      if (user.password != user.rePassword) {
        throw ErrorDescription('As senhas devem ser iguais!');
      }

      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: user.email,
            password: user.password,
          );

      if (userCredential.user?.uid != null) {
        user.firebase_id = userCredential.user!.uid;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.firebase_id)
            .set({
              'name': user.name,
              'email': user.email,
              'firebase_id': user.firebase_id,
            });
      }
    } on FirebaseAuthException catch (e) {
      String message =
          'Ocorreu um problema! por favor tenta novamente mais tarde.';
      if (e.code == 'weak-password') {
        message = "A senha é fraca de mais. tente outra por favor!";
      } else if (e.code == 'email-already-in-use') {
        message = "Já existe uma conta com esse email";
      } else if (e.code == 'invalid-email') {
        message = "Formato do email está incorreto";
      }
      throw ErrorDescription(message);
    } catch (e) {
      throw ErrorDescription(e.toString());
    }
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Tentar fazer o login com e-mail e senha
      print("ENTREI");
      UserCredential userCredentials = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      final FirebaseMessaging notificationAPI = FirebaseMessaging.instance;
      // Obter o token de notificação
      String? notificationToken = await notificationAPI.getToken();

      print(notificationToken);
      // Se o token de notificação existir, salvar no Firestore
      if (notificationToken != null) {
        await FirebaseFirestore.instance
            .collection('users_notifications')
            .doc(userCredentials.user!.uid)
            .set({
              "id": userCredentials.user!.uid,
              "notification_token": notificationToken,
            });
      }
      print(userCredentials);
      // Retornar as credenciais do usuário
      return userCredentials;
    } on FirebaseAuthException catch (e) {
      // Lidar com erros específicos do FirebaseAuth
      print(e.code);
      String message = 'Ocorreu um problema! Tente novamente mais tarde.';
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        message = "Ocorreu um problema! Verifique o email e a senha.";
      }
      throw ErrorDescription(message);
    }
  }

  Future<String?> getUserId() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      print("PRINT CURRENT ${currentUser?.uid}");

      if (currentUser != null) {
        DocumentSnapshot userSnapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .get();

        if (userSnapshot.exists) {
          Map<String, dynamic> userData =
              userSnapshot.data() as Map<String, dynamic>;
          print("PRINT USERDATA ${userData}");
          return userData['firebase_id'] ?? ''; // Retorna apenas o ID
        }
      }
      return null;
    } catch (e) {
      print("Erro ao buscar ID do usuário: $e");
      return null;
    }
  }

  Future<bool> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      return FirebaseAuth.instance.currentUser == null;
    } catch (e) {
      print("Erro ao fazer logout: $e");
      return false;
    }
  }
}
