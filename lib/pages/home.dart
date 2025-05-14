import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:trabalho_rastreador/pages/login.dart';
import 'package:trabalho_rastreador/pages/patient_maps.dart';
import 'package:trabalho_rastreador/pages/register_patient.dart';
import 'package:trabalho_rastreador/service/auth_service.dart';
import 'package:trabalho_rastreador/service/patient_service.dart';
import 'package:trabalho_rastreador/utils/toastMessages.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //verifica se tem algum usuario autenticado
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
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
        ModalRoute.withName('/login'),
      );
    }

    if (userId == null) {
      return const Center(child: CircularProgressIndicator());
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
          //busca os pacientes
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
              padding: EdgeInsets.all(10),
              itemCount: patients.length,
              itemBuilder: (context, index) {
                final paciente = patients[index].data() as Map<String, dynamic>;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: GestureDetector(
                    onTap: () async {
                      final String? codigoPaciente = paciente['code'];
                      if (codigoPaciente != null) {
                        final locationData = await _pacienteService
                            .getLocationFromRealtime(codigoPaciente);

                        if (locationData != null &&
                            locationData.containsKey('latitude') &&
                            locationData.containsKey('longitude')) {
                          double lat = locationData['latitude'] as double;
                          double lng = locationData['longitude'] as double;

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      PatientMap(latitude: lat, longitude: lng),
                            ),
                          );
                        } else {
                          ToastMessage().error(
                            message: 'Localização não encontrada no Realtime.',
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
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  //função para definir a cor do status
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
                          const SizedBox(height: 10),
                          Text('Endereço: ${paciente['address'] ?? ''}'),
                          Text('Idade: ${paciente['age'] ?? ''}'),
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
