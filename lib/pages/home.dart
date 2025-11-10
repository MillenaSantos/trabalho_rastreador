import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:trabalho_rastreador/pages/login.dart';
import 'package:trabalho_rastreador/pages/maps.dart';
import 'package:trabalho_rastreador/pages/register_patient.dart';
import 'package:trabalho_rastreador/service/auth_service.dart';
import 'package:trabalho_rastreador/service/emergency_listener.dart';
import 'package:trabalho_rastreador/service/patient_service.dart';
import 'package:trabalho_rastreador/utils/toastMessages.dart';

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

  Future<void> initEmergencyService() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final emergencyService = EmergencyListenerService(userId: user.uid);
      await emergencyService.init();
      print("EmergencyListenerService inicializado para ${user.uid}");
    } else {
      print("Usuário não logado ainda. Serviço não iniciado.");
    }
  }

  Future<void> _loadUser() async {
    await initEmergencyService();
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

  IconData _getSpeedIcon(double speed) {
    if (speed < 7) {
      return Icons.directions_walk; // andando
    } else if (speed < 20) {
      return Icons.pedal_bike; // bicicleta
    } else {
      return Icons.directions_car; // carro
    }
  }

  Color _getSpeedColor(double speed) {
    if (speed < 7) {
      return Colors.green; // devagar, tranquilo
    } else if (speed < 20) {
      return Colors.orange; // média, bicicleta ou corrida
    } else {
      return Colors.red; // rápido, veículo
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
        backgroundColor: const Color.fromARGB(255, 223, 223, 223),
        title: const Text('Monitorados'),
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
          stream: _pacienteService.getPatients(userId!),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'Não há monitorados cadastrados',
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
                final codePaciente = paciente['code']?.toString();

                return StreamBuilder<Map<String, dynamic>?>(
                  stream:
                      codePaciente != null
                          ? _pacienteService.getRealtimeData(codePaciente)
                          : const Stream.empty(),
                  builder: (context, realtimeSnap) {
                    final status = paciente['status'] ?? 'indefinido';
                    final battery = realtimeSnap.data?['battery'] ?? 0;
                    final avgSpeed =
                        (realtimeSnap.data?['speed'] ?? 0).toDouble();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InkWell(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => RegisterPatientPage(
                                      docId: patients[index].id,
                                    ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
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
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _getStatusColor(status),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        paciente['name'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.battery_full,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 4),
                                        Text('$battery%'),
                                      ],
                                    ),
                                    const SizedBox(width: 16),
                                    Row(
                                      children: [
                                        Icon(
                                          _getSpeedIcon(avgSpeed),
                                          size: 18,
                                          color: _getSpeedColor(avgSpeed),
                                        ),
                                        const SizedBox(width: 4),
                                        Text('${avgSpeed.round()} km/h'),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Data de nascimento: ${paciente['age'] ?? ''}',
                                ),
                                Text(
                                  'Código do monitorado: ${paciente['code'] ?? ''}',
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (paciente['area'] != null &&
                            (paciente['area'] as List).isNotEmpty)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                38,
                                166,
                                154,
                              ),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            icon: const Icon(
                              Icons.location_on,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "Ver localização atual",
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () async {
                              List<LatLng> area =
                                  (paciente['area'] as List)
                                      .map(
                                        (p) => LatLng(
                                          (p as GeoPoint).latitude,
                                          p.longitude,
                                        ),
                                      )
                                      .toList();

                              LatLng? currentLocation;
                              if (codePaciente != null &&
                                  codePaciente.isNotEmpty) {
                                final locationData = await _pacienteService
                                    .getLocationFromRealtime(codePaciente);
                                if (locationData != null) {
                                  currentLocation = LatLng(
                                    (locationData['latitude'] as num)
                                        .toDouble(),
                                    (locationData['longitude'] as num)
                                        .toDouble(),
                                  );
                                }
                              }

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => MapScreen(
                                        initialArea: area,
                                        currentLocation: currentLocation,
                                        readonly: true,
                                      ),
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 12),
                      ],
                    );
                  },
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
        backgroundColor: const Color.fromARGB(255, 38, 166, 154),
        tooltip: 'Adicionar Monitorado',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
