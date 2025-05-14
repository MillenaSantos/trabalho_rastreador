import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> handleBackgroundMessage(RemoteMessage message) async {
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Payload: ${message.data}');
}

class NotificationService {
  final FirebaseMessaging _notificationAPI = FirebaseMessaging.instance;

  Future<void> initNotification() async {
    await _notificationAPI.requestPermission();
    final fCMToken = await _notificationAPI.getToken();

    print("Token: $fCMToken");
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
  }

  FirebaseMessaging getNotificationAPI() {
    return _notificationAPI;
  }
}
