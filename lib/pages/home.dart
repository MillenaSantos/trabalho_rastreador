import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:trabalho_rastreador/pages/login.dart';
import 'package:trabalho_rastreador/pages/patient_maps.dart';
import 'package:trabalho_rastreador/pages/register_patient.dart';
import 'package:trabalho_rastreador/service/auth_service.dart';
import 'package:trabalho_rastreador/service/patient_service.dart';
import 'package:trabalho_rastreador/utils/toastMessages.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? userCredential = FirebaseAuth.instance.currentUser;

  final PatientService _pacienteService = PatientService();
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    userId = await AuthService().getUserId();
    setState(() {});
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'outOfArea':
        return Colors.red;
      case 'active':
        return Colors.green;
      default:
        return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userCredential == null) {
      Future.microtask(() {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
        );
      });
    }

    if (userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              bool loggedOut = await AuthService().logout();

              if (loggedOut) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              } else {
                ToastMessage().error(
                  message: "Algo deu errado. Tente novamente!",
                );
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder(
          stream: _pacienteService.getPatients(userId),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'Não há pacientes cadastrados',
                  style: TextStyle(fontSize: 18),
                ),
              );
            }

            List<DocumentSnapshot> patients = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: patients.length,
              itemBuilder: (context, index) {
                final paciente = patients[index].data() as Map<String, dynamic>;
                print(paciente);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: GestureDetector(
                    onTap: () async {
                      final String? codigoPaciente = paciente['code'];
                      if (codigoPaciente != null) {
                        final area = await _pacienteService
                            .buscarAreaDoPaciente(codigoPaciente);
                        final location = await _pacienteService
                            .getLocationFromRealtime(codigoPaciente);

                        if (area != null &&
                            area.containsKey('center') &&
                            area.containsKey('edge')) {
                          final LatLng areaCenter = area['center'] as LatLng;
                          final double areaEdge = area['edge'] as double;

                          if (location != null &&
                              location.containsKey('latitude') &&
                              location.containsKey('longitude')) {
                            final LatLng currentLocation = LatLng(
                              location['latitude'],
                              location['longitude'],
                            );

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => PatientMap(
                                      areaCenter: areaCenter,
                                      areaEdge: areaEdge,
                                      currentLocation: currentLocation,
                                    ),
                              ),
                            );
                          } else {
                            ToastMessage().error(
                              message: 'Localização atual não encontrada.',
                            );
                          }
                        } else {
                          ToastMessage().error(
                            message: 'Área do paciente não encontrada.',
                          );
                        }
                      } else {
                        ToastMessage().error(
                          message: 'Código do paciente não disponível.',
                        );
                      }
                    },

                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _getStatusColor(
                                        paciente.containsKey('status')
                                            ? paciente['status']
                                            : 'indefinido',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    paciente['name'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                tooltip: 'Deletar paciente',
                                onPressed: () async {
                                  final docId = patients[index].id;
                                  await _pacienteService.deletePatient(docId);
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),
                          Text('Data de nascimento: ${paciente['age'] ?? ''}'),
                          Text('Código do paciente: ${paciente['code'] ?? ''}'),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RegisterPatientPage()),
          );
        },
        backgroundColor: Colors.blue.shade100,
        tooltip: 'Adicionar Paciente',
        child: Icon(Icons.add, color: Colors.blue.shade800),
      ),
    );
  }
}
