import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PatientMap extends StatefulWidget {
  final LatLng areaCenter;
  final double areaEdge;
  final LatLng currentLocation;

  const PatientMap({
    super.key,
    required this.areaCenter,
    required this.areaEdge,
    required this.currentLocation,
  });

  @override
  State<PatientMap> createState() => _PatientMapState();
}

class _PatientMapState extends State<PatientMap> {
  late GoogleMapController _mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Área do Paciente')),
      body: GoogleMap(
        onMapCreated: (controller) => _mapController = controller,
        initialCameraPosition: CameraPosition(
          target: widget.areaCenter,
          zoom: 15,
        ),
        circles: {
          Circle(
            circleId: const CircleId('areaPermitida'),
            center: widget.areaCenter,
            radius: widget.areaEdge,
            fillColor: Colors.blue.withOpacity(0.3),
            strokeColor: Colors.blue,
            strokeWidth: 2,
          ),
        },
        markers: {
          Marker(
            markerId: const MarkerId('localizacaoAtual'),
            position: widget.currentLocation,
            infoWindow: const InfoWindow(title: 'Localização Atual'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        },
      ),
    );
  }
}
