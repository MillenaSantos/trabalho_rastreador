import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:trabalho_rastreador/models/patient_model.dart';
import 'package:trabalho_rastreador/service/auth_service.dart';
import 'package:trabalho_rastreador/utils/toastMessages.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PatientService {
  final _db = FirebaseFirestore.instance;

  Future<void> deletePatient(String docId) async {
    try {
      await _db.collection('Patient').doc(docId).delete();
      ToastMessage().success(message: 'Monitorado deletado com sucesso!');
    } catch (e) {
      ToastMessage().warning(message: 'Erro ao deletar monitorado!');
    }
  }

  createPatient(PatientModel patient) async {
    try {
      String? userId = await AuthService().getUserId();

      if (userId != null) {
        patient.userId = [userId]; // Salva como array
      }

      await _db.collection("Patient").add(patient.toJson());

      ToastMessage().success(message: 'Monitorado criado com sucesso!');
    } catch (error) {
      ToastMessage().warning(
        message: 'Algo deu errado! Por favor tente novamente!',
      );
    }
  }

  updatePatient(String docId, Map<String, dynamic> data) async {
    try {
      await _db.collection("Patient").doc(docId).update(data);
      ToastMessage().success(message: 'Atualização realizada com sucesso!');
    } catch (error) {
      ToastMessage().warning(
        message: 'Algo deu errado! Por favor tente novamente!',
      );
    }
  }

  // Stream<QuerySnapshot<Map<String, dynamic>>> getPatients(userId) {
  //   Stream<QuerySnapshot<Map<String, dynamic>>> patientSnapShot =
  //       _db
  //           .collection('Patient')
  //           .where('userId', isEqualTo: userId)
  //           .snapshots();

  //   return patientSnapShot;
  // }

  Stream<QuerySnapshot<Map<String, dynamic>>> getPatients(String userId) {
    return _db
        .collection('Patient')
        .where('userId', arrayContains: userId) // <-- mudar aqui
        .snapshots();
  }

  Stream<Map<String, dynamic>?> getRealtimeData(String codePaciente) {
    final ref = FirebaseDatabase.instance.ref('locations/$codePaciente');
    return ref.onValue.map((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return null;
    });
  }

  Future<Map<String, dynamic>?> getLocationFromRealtime(
    String codigoPaciente,
  ) async {
    final snapshot =
        await FirebaseDatabase.instance.ref('locations/$codigoPaciente').get();

    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    } else {
      return null;
    }
  }

  Future<Map<String, dynamic>> buscarAreaDoPaciente(String code) async {
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('Patient')
            .where('code', isEqualTo: code)
            .limit(1)
            .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception('Monitorado com código $code não encontrado');
    }

    final doc = querySnapshot.docs.first;
    final area = doc['area'] as List<dynamic>?;

    if (area == null || area.length != 2) {
      throw Exception('Área inválida ou incompleta');
    }

    final GeoPoint center = area[0];
    final GeoPoint edge = area[1];

    final double distanceInMeters = Geolocator.distanceBetween(
      center.latitude,
      center.longitude,
      edge.latitude,
      edge.longitude,
    );

    return {
      'center': LatLng(center.latitude, center.longitude),
      'edge': distanceInMeters, // <- agora é um double
    };
  }
}
