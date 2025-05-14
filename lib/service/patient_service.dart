import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:trabalho_rastreador/models/patient_model.dart';
import 'package:trabalho_rastreador/service/auth_service.dart';
import 'package:trabalho_rastreador/utils/generatePatientCode.dart';
import 'package:trabalho_rastreador/utils/toastMessages.dart';

class PatientService {
  final _db = FirebaseFirestore.instance;

  inTheArea(String patientRef) async {
    await _db
        .collection('Patient')
        .doc(patientRef)
        .set({"status": 'active'}, SetOptions(merge: true));
  }

  outOfArea(String patientRef) async {
    await _db
        .collection('Patient')
        .doc(patientRef)
        .set({"status": 'outOfArea'}, SetOptions(merge: true));
  }

  createPatient(PatientModel patient) async {
    try {
      patient.code = await generateCode();
      String? userId = await AuthService().getUserId();

      if (userId != null) {
        patient.userId = userId;
      }

      await _db.collection("Patient").add(patient.toJson());
      
      ToastMessage().success(message: 'Paciente criado com sucesso!');
    } catch (error) {
      ToastMessage().warning(
        message: 'Algo deu errado! Por favor tente novamente!',
      );
    }
  }


  Stream<QuerySnapshot<Map<String, dynamic>>> getPatients(userId) {
    Stream<QuerySnapshot<Map<String, dynamic>>> patientSnapShot =
        _db
            .collection('Patient')
            .where('userId', isEqualTo: userId)
            .snapshots();

    return patientSnapShot;
  }

  Future<Map<String, dynamic>?> getLocationFromRealtime(String codigoPaciente) async {
  final snapshot = await FirebaseDatabase.instance.ref('locations/$codigoPaciente').get();

  if (snapshot.exists) {
    return Map<String, dynamic>.from(snapshot.value as Map);
  } else {
    return null;
  }
}

}
