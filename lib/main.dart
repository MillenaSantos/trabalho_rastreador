import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:trabalho_rastreador/pages/login.dart';

// 🔔 Instância global de notificações
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // ✅ Inicializa notificações locais antes do runApp
  const AndroidInitializationSettings initSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings = InitializationSettings(
    android: initSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // 🔧 Cria os canais necessários
  final androidPlugin =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  // 🔔 Canal padrão (usado pelo Firebase Messaging)
  const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
    'default_channel', // deve ser igual ao que está no AndroidManifest.xml
    'Notificações padrão',
    description: 'Canal usado para notificações gerais e do Firebase',
    importance: Importance.defaultImportance,
  );
  await androidPlugin?.createNotificationChannel(defaultChannel);

  // 🚨 Canal de emergência (alertas locais personalizados)
  const AndroidNotificationChannel emergencyChannel = AndroidNotificationChannel(
    'emergency_channel',
    'Emergência',
    description: 'Canal para alertas de emergência',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('alerta'),
  );
  await androidPlugin?.createNotificationChannel(emergencyChannel);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
