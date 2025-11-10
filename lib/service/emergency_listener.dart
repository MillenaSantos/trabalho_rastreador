import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

class EmergencyListenerService {
  final String userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _player = AudioPlayer();

  Stream<QuerySnapshot>? _stream;
  bool _isAlarmPlaying = false;

  EmergencyListenerService({required this.userId});

  Future<void> init() async {
    // Inicializa notificações locais
    const AndroidInitializationSettings initSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(
      android: initSettingsAndroid,
    );
    await _notifications.initialize(initSettings);

    // Listener do Firestore: pacientes ligados ao userId (array)
    _stream =
        _firestore
            .collection('Patient')
            .where('userId', arrayContains: userId)
            .snapshots();

    _stream!.listen((snapshot) {
      print("Snapshot recebido: ${snapshot.docs.length} documentos");
      for (var doc in snapshot.docs) {
        bool emergency = doc['emergency'] ?? false;
        String patientName = doc['name'] ?? 'Monitorado';

        if (emergency) {
          _triggerAlarm(
            patientDocId: doc.id,
            patientName: patientName,
            durationSeconds: 15,
          );
        } else {
          _stopAlarm();
        }
      }
    });
  }

  Future<void> _triggerAlarm({
    required String patientDocId,
    required String patientName,
    int durationSeconds = 10,
  }) async {
    if (_isAlarmPlaying) return;
    _isAlarmPlaying = true;

    // Notificação local
    await _notifications.show(
      0,
      'Emergência detectada!',
      '$patientName acionou o alerta!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'emergency_channel',
          'Emergência',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
      ),
    );

    // Vibração
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 1000);
    }

    // Som em loop
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(AssetSource('sounds/alerta.mp3'));

    // Para depois de X segundos e atualiza Firestore
    Future.delayed(Duration(seconds: durationSeconds), () async {
      try {
        await _firestore.collection('Patient').doc(patientDocId).update({
          'emergency': false,
        });
      } catch (e) {
        print("Erro ao atualizar emergency: $e");
      }
      _stopAlarm();
    });
  }

  Future<void> _stopAlarm() async {
    if (!_isAlarmPlaying) return;
    _isAlarmPlaying = false;

    await _player.stop();
    await _notifications.cancelAll();
  }

  // Para parar manualmente o alarme
  void stopAlarm() => _stopAlarm();

  // Liberar recursos
  void dispose() {
    _player.dispose();
  }
}
