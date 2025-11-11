import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:trabalho_rastreador/models/user_model.dart';
import 'package:trabalho_rastreador/service/emergency_listener.dart';

class AuthService {
  // CADASTRO
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

        // REGISTRAR TOKEN FCM AO CADASTRAR
        final FirebaseMessaging messaging = FirebaseMessaging.instance;

        // Obter token atual
        String? token = await messaging.getToken();
        if (token != null) {
          await FirebaseFirestore.instance
              .collection('users_notifications')
              .doc(user.firebase_id)
              .set({"notification_token": token}, SetOptions(merge: true));
        }

        // Atualizar token quando mudar
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
          await FirebaseFirestore.instance
              .collection('users_notifications')
              .doc(user.firebase_id)
              .set({"notification_token": newToken}, SetOptions(merge: true));
        });
      }
    } on FirebaseAuthException catch (e) {
      String message =
          'Ocorreu um problema! por favor tente novamente mais tarde.';
      if (e.code == 'weak-password') {
        message = "A senha deve ter no mínimo 6 caracteres e deve conter letras e números. Tente outra por favor!";
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

  // LOGIN
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredentials = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // REGISTRAR TOKEN FCM AO LOGAR
      final FirebaseMessaging messaging = FirebaseMessaging.instance;

      String? token = await messaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users_notifications')
            .doc(userCredentials.user!.uid)
            .set({"notification_token": token}, SetOptions(merge: true));
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        await FirebaseFirestore.instance
            .collection('users_notifications')
            .doc(userCredentials.user!.uid)
            .set({"notification_token": newToken}, SetOptions(merge: true));
      });

      return userCredentials;
    } on FirebaseAuthException catch (e) {
      String message = 'Ocorreu um problema! Tente novamente mais tarde.';
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        message = "Ocorreu um problema! Verifique o email e a senha.";
      }
      throw ErrorDescription(message);
    }
  }

  // OBTER ID DO USUÁRIO
  Future<String?> getUserId() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userSnapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .get();

        if (userSnapshot.exists) {
          Map<String, dynamic> userData =
              userSnapshot.data() as Map<String, dynamic>;
          return userData['firebase_id'] ?? '';
        }
      }
      return null;
    } catch (e) {
      print("Erro ao buscar ID do usuário: $e");
      return null;
    }
  }

  // LOGOUT
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
