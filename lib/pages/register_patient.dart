import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mt;
import 'package:trabalho_rastreador/components/customButton.dart';
import 'package:trabalho_rastreador/components/customDatafield.dart';
import 'package:trabalho_rastreador/components/customTextfield.dart';
import 'package:trabalho_rastreador/models/patient_model.dart';
import 'package:trabalho_rastreador/pages/maps.dart';
import 'package:trabalho_rastreador/service/patient_service.dart';
import 'package:trabalho_rastreador/utils/toastMessages.dart';
import 'dart:math';


class RegisterPatientPage extends StatefulWidget {
  final String? docId; // null = novo paciente

  const RegisterPatientPage({super.key, this.docId});

  @override
  _RegisterPatientPageState createState() => _RegisterPatientPageState();
}

class _RegisterPatientPageState extends State<RegisterPatientPage> {
  final TextEditingController patientNameController = TextEditingController();
  final TextEditingController patientDateController = TextEditingController();

  List<LatLng> selectedArea = [];
  final PatientService _pacienteService = PatientService();
  PatientModel? currentPatient;

  bool isLoading = false;
  final Color mainColor = const Color.fromARGB(255, 38, 166, 154);

  @override
  void initState() {
    super.initState();
    if (widget.docId != null) {
      _loadPatientData(widget.docId!);
    }
  }

  Future<void> _loadPatientData(String docId) async {
    setState(() => isLoading = true);

    final doc =
        await FirebaseFirestore.instance.collection('Patient').doc(docId).get();

    if (doc.exists) {
      final data = doc.data()!;
      patientNameController.text = data['name'] ?? '';
      patientDateController.text = data['age'] ?? '';

      if (data['area'] != null) {
        selectedArea =
            (data['area'] as List)
                .map((p) => LatLng(p.latitude, p.longitude))
                .toList();
      }

      currentPatient = PatientModel(
        name: data['name'] ?? '',
        date: data['age'] ?? '',
        area:
            data['area'] != null
                ? (data['area'] as List).map((p) => p as GeoPoint).toList()
                : [],
        code: data['code'],
        status: data['status'] ?? 'inactive',
        battery: data['battery'] ?? 0,
        speed: data['speed'] ?? 0,
        userId: data['userId'] != null ? List<String>.from(data['userId']) : [],
      );
    }

    setState(() => isLoading = false);
  }

  void _selecionarArea() async {
    final areaSelecionada = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(initialArea: selectedArea),
      ),
    );

    if (areaSelecionada != null && areaSelecionada is List<LatLng>) {
      setState(() {
        selectedArea = areaSelecionada;
      });
    }
  }

  void _showLinkPatientModal() {
    final TextEditingController _codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Vincular Monitorado'),
          content: TextField(
            controller: _codeController,
            decoration: const InputDecoration(
              labelText: 'Código do monitorado',
              hintText: 'Digite o código do monitorado',
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar', style: TextStyle(color: mainColor)),
            ),
            ElevatedButton(
              onPressed: () async {
                String code = _codeController.text.trim().toUpperCase();
                if (code.isEmpty) {
                  ToastMessage().error(message: 'Insira um código válido!');
                  return;
                }

                try {
                  await FirebaseFirestore.instance
                      .collection('Patient')
                      .doc(widget.docId!)
                      .update({
                        'code': code,
                        'userId': currentPatient?.userId ?? [],
                      });

                  setState(() {
                    currentPatient?.code = code;
                  });

                  ToastMessage().success(
                    message: 'Monitorado vinculado com sucesso!',
                  );
                  Navigator.of(context).pop();
                } catch (e) {
                  ToastMessage().error(message: 'Erro ao vincular monitorado.');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: mainColor),
              child: const Text(
                "Vincular",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _toggleLinkPatient() {
    if (currentPatient?.code != null && currentPatient!.code!.isNotEmpty) {
      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text("Desvincular monitorado "),
              content: Text(
                "Deseja realmente desvincular o monitorado código ${currentPatient!.code}?",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text("Cancelar", style: TextStyle(color: mainColor)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await FirebaseFirestore.instance
                          .collection('Patient')
                          .doc(widget.docId!)
                          .update({'code': ''});

                      setState(() {
                        currentPatient?.code = '';
                      });

                      ToastMessage().success(
                        message: 'Monitorado desvinculado com sucesso!',
                      );
                    } catch (e) {
                      ToastMessage().error(
                        message: 'Erro ao desvincular monitorado.',
                      );
                    }
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: mainColor),
                  child: const Text(
                    "Desvincular",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
      );
    } else {
      _showLinkPatientModal();
    }
  }

  num _getArea(List<LatLng> points) {
    if (points.length < 2) return 0;

    // Caso 2 pontos → área circular com raio
    if (points.length == 2) {
      double radius = Geolocator.distanceBetween(
        points[0].latitude,
        points[0].longitude,
        points[1].latitude,
        points[1].longitude,
      );
      // Área do círculo = π * r²
      return pi * pow(radius, 2);
    }

    // Caso ≥3 pontos → área poligonal
    List<mt.LatLng> areaList =
        points.map((e) => mt.LatLng(e.latitude, e.longitude)).toList();
    return mt.SphericalUtil.computeArea(areaList);
  }

  Widget _infoItem(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 5),
        Text(value),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.docId == null ? "Adicionar monitorado" : "Editar monitorado",
        ),
        backgroundColor: const Color.fromARGB(255, 223, 223, 223),
        actions: [
          if (widget.docId != null) ...[
            IconButton(
              icon: Icon(
                currentPatient?.code != null && currentPatient!.code!.isNotEmpty
                    ? Icons.link
                    : Icons.link_off,
                color:
                    currentPatient?.code != null &&
                            currentPatient!.code!.isNotEmpty
                        ? Colors.green
                        : Colors.grey,
              ),
              tooltip:
                  currentPatient?.code != null &&
                          currentPatient!.code!.isNotEmpty
                      ? 'Desvincular monitorado'
                      : 'Vincular monitorado',
              onPressed: _toggleLinkPatient,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Excluir monitorado',
              onPressed: () async {
                await _pacienteService.deletePatient(widget.docId!);
                if (mounted) Navigator.pop(context);
              },
            ),
          ],
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 50),
                      Icon(
                        widget.docId == null ? Icons.group_add : Icons.edit,
                        size: 100,
                        color: mainColor,
                      ),
                      const SizedBox(height: 15),

                      // Informações do paciente com StreamBuilder para Realtime
                      if (widget.docId != null &&
                          currentPatient?.code != null &&
                          currentPatient!.code!.isNotEmpty)
                        StreamBuilder<Map<String, dynamic>?>(
                          stream: _pacienteService.getRealtimeData(
                            currentPatient!.code!,
                          ),
                          builder: (context, snapshot) {
                            final battery = snapshot.data?['battery'] ?? 0;
                            final speed =
                                (snapshot.data?['speed'] ?? 0).toDouble();

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _infoItem(
                                  Icons.battery_full,
                                  '$battery%',
                                  mainColor,
                                ),
                                _infoItem(
                                  Icons.speed,
                                  '${speed.round()} km/h',
                                  mainColor,
                                ),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    List<LatLng> area =
                                        (currentPatient?.area as List)
                                            .map(
                                              (p) => LatLng(
                                                (p as GeoPoint).latitude,
                                                p.longitude,
                                              ),
                                            )
                                            .toList();

                                    LatLng? currentLocation;
                                    final codePaciente =
                                        currentPatient?.code.toString();
                                    if (codePaciente != null &&
                                        codePaciente.isNotEmpty) {
                                      final locationData =
                                          await _pacienteService
                                              .getLocationFromRealtime(
                                                codePaciente,
                                              );
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
                                  icon: const Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    'Localização',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: mainColor,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                      const SizedBox(height: 25),

                      // Campos de formulário
                      MyTextField(
                        controller: patientNameController,
                        hintText: 'Nome completo',
                        obscureText: false,
                        required: true,
                      ),
                      const SizedBox(height: 10),
                      MyDateField(
                        controller: patientDateController,
                        hintText: 'Data de Nascimento',
                        required: true,
                      ),
                      const SizedBox(height: 25),

                      // Área Delimitadora
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Área Delimitadora',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (selectedArea.isNotEmpty)
                              Text(
                                selectedArea.length >= 2
                                    ? 'Área de ${(_getArea(selectedArea) / 1000000).toStringAsFixed(3)} km²'
                                    : 'Selecione pelo menos dois pontos',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              )
                            else
                              const Text(
                                'Nenhuma área definida ainda.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            const SizedBox(height: 15),
                            MyButton(
                              onTap: _selecionarArea,
                              text:
                                  widget.docId == null
                                      ? 'Criar área delimitadora'
                                      : 'Alterar área delimitadora',
                              color: const Color.fromARGB(255, 153, 153, 153),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Botão de salvar/adicionar paciente
                      MyButton(
                        onTap: () async {
                          final patient = PatientModel(
                            name: patientNameController.text,
                            date: patientDateController.text,
                            area:
                                selectedArea
                                    .map(
                                      (l) => GeoPoint(l.latitude, l.longitude),
                                    )
                                    .toList(),
                            code: currentPatient?.code,
                            userId: currentPatient?.userId ?? [],
                          );

                          if (widget.docId == null) {
                            await _pacienteService.createPatient(patient);
                          } else {
                            await _pacienteService.updatePatient(
                              widget.docId!,
                              patient.toJson(),
                            );
                          }

                          if (mounted) Navigator.pop(context);
                        },
                        text:
                            widget.docId == null
                                ? 'Adicionar'
                                : 'Salvar alterações',
                        color: mainColor,
                      ),
                      const SizedBox(height: 25),
                    ],
                  ),
                ),
              ),
    );
  }
}
