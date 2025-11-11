// import 'package:cloud_firestore/cloud_firestore.dart';

// class EmergencyListenerService {
//   final String userId;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   Stream<QuerySnapshot>? _stream;

//   EmergencyListenerService({required this.userId});

//   Future<void> init() async {
//     // Listener do Firestore: pacientes ligados ao userId (array)
//     _stream =
//         _firestore
//             .collection('Patient')
//             .where('userId', arrayContains: userId)
//             .snapshots();

//     _stream!.listen((snapshot) {
//       for (var doc in snapshot.docs) {
//         bool emergency = doc['emergency'] ?? false;
//         String patientName = doc['name'] ?? 'Monitorado';

//         if (emergency) {
//           print("🚨 $patientName acionou o alerta de emergência!");
//         } else {
//           print("✅ $patientName saiu do estado de emergência.");
//         }
//       }
//     });
//   }
// }
