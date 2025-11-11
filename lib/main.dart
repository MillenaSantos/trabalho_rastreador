import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:trabalho_rastreador/pages/login.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// 🔥 Necessário para receber notificações com app FECHADO
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  _showNotificationFromMessage(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Registrar background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Criar canais manualmente
  final androidPlugin =
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

  await androidPlugin?.createNotificationChannel(
    const AndroidNotificationChannel(
      'general_channel',
      'Alertas Gerais',
      description: 'Notificações de bateria, área, etc',
      importance: Importance.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('alerta_curto'),
      enableVibration: false,
    ),
  );

  await androidPlugin?.createNotificationChannel(
    AndroidNotificationChannel(
      'emergency_channel',
      'Emergência',
      description: 'Alertas críticos com vibração forte e som',
      importance: Importance.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('alerta'),
      vibrationPattern: Int64List.fromList([0, 1500, 800, 1500, 800, 1500]),
      enableVibration: true,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    FirebaseMessaging.onMessage.listen(_showNotificationFromMessage);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
    );
  }
}

/// 🎯 Interpretar as mensagens recebidas e escolher o canal correto
void _showNotificationFromMessage(RemoteMessage message) async {
  final data = message.data;
  final tipo = data['tipo'];

  final title = data['title'] ?? '';
  final body = data['body'] ?? '';
  if (title.isEmpty && body.isEmpty) return;

  // 🚨 Emergência
  if (tipo == 'emergencia') {
    await flutterLocalNotificationsPlugin.show(
      9999,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'emergency_channel',
          'Emergência',
          channelDescription: 'Alertas críticos',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('alerta'),
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 1500, 800, 1500, 800, 1500]),
          autoCancel: true, // ✅ remove quando limpar
          ongoing: false, // ✅ não fica preso
          category: AndroidNotificationCategory.alarm,
        ),
      ),
    );
    return;
  }

  // 🔔 Notificações gerais
  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        'general_channel',
        'Alertas Gerais',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('alerta_curto'),
        enableVibration: false,
        autoCancel: true, // ✅ remove quando limpar
        ongoing: false, // ✅ não fica preso
        category: AndroidNotificationCategory.message,
      ),
    ),
  );
}
