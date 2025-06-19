import 'package:cloud_firestore/cloud_firestore.dart';

class PatientModel {
  final int? id;
  final String name;
  final String date;
  final List<GeoPoint> area;
  String? code;
  String? status;
  String? userId;

  PatientModel({
    this.id,
    this.userId,
    this.status = 'inactive',
    this.code,
    required this.name,
    required this.date,
    required this.area,
  });

  toJson() {
    return {
      "name": name,
      "age": date,
      "area": area,
      "code": code,
      "userId": userId,
      "status": status,
    };
  }
}
