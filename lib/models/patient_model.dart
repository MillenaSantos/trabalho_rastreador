import 'package:cloud_firestore/cloud_firestore.dart';

class PatientModel {
  final int? id;
  final String name;
  final String date;
  final List<GeoPoint> area;
  String? code;
  String? status;
  List<String>? userId;
  String? photoUrl; // foto do paciente
  int? battery; // nova propriedade
  int? speed; // velocidade atual
  String? movement; // movimento atual

  PatientModel({
    this.id,
    this.userId,
    this.status = 'inactive',
    this.code,
    this.photoUrl,
    this.battery,
    this.speed,
    this.movement,
    required this.name,
    required this.date,
    required this.area,
  });

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "age": date,
      "area": area,
      "code": code,
      "userId": userId,
      "status": status,
      "photoUrl": photoUrl,
      "battery": battery,
      "speed": speed,
      "movement": movement,
    };
  }
}
