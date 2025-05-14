import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PatientMap extends StatefulWidget {
  final double latitude;
  final double longitude;

  const PatientMap({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<PatientMap> createState() => _PatientMapState();
}

class _PatientMapState extends State<PatientMap> {
  late GoogleMapController _mapController;

  @override
  Widget build(BuildContext context) {
    final LatLng location = LatLng(widget.latitude, widget.longitude);

    return Scaffold(
      appBar: AppBar(title: const Text('Localização do Paciente')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: location, zoom: 15),
        onMapCreated: (controller) {
          _mapController = controller;
          _mapController.animateCamera(
            CameraUpdate.newLatLng(location),
          ); // centraliza o mapa na localização
        },
        markers: {
          Marker(
            markerId: const MarkerId('paciente'),
            position: location,
          ),
        },
      ),
    );
  }
}
