import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:trabalho_rastreador/components/customButton.dart';
import 'package:trabalho_rastreador/components/customTextfield.dart';
import 'package:trabalho_rastreador/utils/toastMessages.dart';

class MapScreen extends StatefulWidget {
  final List<LatLng>? initialArea;
  final LatLng? currentLocation; // se quiser mostrar a localização atual
  final bool readonly; // indica se é apenas visualização

  const MapScreen({
    super.key,
    this.initialArea,
    this.currentLocation,
    this.readonly = false,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  List<LatLng> area = [];
  LatLng initialCamera = LatLng(-23.550520, -46.633308);
  final TextEditingController locationAddressController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.initialArea != null && widget.initialArea!.isNotEmpty) {
      area = List.from(widget.initialArea!);
      initialCamera = area[0];
    } else if (!widget.readonly) {
      _getCurrentPosition();
    } else if (widget.currentLocation != null) {
      initialCamera = widget.currentLocation!;
    }
  }

  void _getCurrentPosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print('Permissões negadas');
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      initialCamera = LatLng(position.latitude, position.longitude);
    });

    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
      );
    }
  }

  void _onMapTap(LatLng location) {
    if (!widget.readonly) {
      setState(() {
        area.add(location);
      });
    }
  }

  Future<void> _searchAddress() async {
    String address = locationAddressController.text;
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        mapController?.animateCamera(
          CameraUpdate.newLatLng(LatLng(loc.latitude, loc.longitude)),
        );
      } else {
        ToastMessage().warning(message: 'Endereço não encontrado');
      }
    } catch (e) {
      ToastMessage().error(message: 'Erro ao buscar o endereço');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Marcadores apenas se não for readonly
    final markers =
        !widget.readonly
            ? area
                .asMap()
                .entries
                .map(
                  (entry) => Marker(
                    markerId: MarkerId('marker-${entry.key}'),
                    position: entry.value,
                    draggable: true,
                    onDragEnd: (newLoc) {
                      setState(() {
                        area[entry.key] = newLoc;
                      });
                    },
                    onTap: () {
                      setState(() {
                        area.removeAt(entry.key);
                      });
                    },
                  ),
                )
                .toSet()
            : <Marker>{};

    // Polígono ou círculo
    final polygons =
        area.length >= 3
            ? {
              Polygon(
                polygonId: const PolygonId('selected-area'),
                points: area,
                strokeColor: Colors.blue.shade600,
                fillColor: Colors.blue.shade200.withOpacity(0.2),
                strokeWidth: 2,
              ),
            }
            : <Polygon>{};

    final circles =
        area.length == 2
            ? {
              Circle(
                circleId: const CircleId('circle-area'),
                center: area[0],
                radius: Geolocator.distanceBetween(
                  area[0].latitude,
                  area[0].longitude,
                  area[1].latitude,
                  area[1].longitude,
                ),
                strokeColor: Colors.blue.shade600,
                fillColor: Colors.blue.shade200.withOpacity(0.2),
                strokeWidth: 2,
              ),
            }
            : <Circle>{};

    // Zoom inicial
    CameraPosition initialCameraPosition = CameraPosition(
      target: initialCamera,
      zoom: 14,
    );

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: initialCameraPosition,
              markers: markers.union(
                widget.readonly && widget.currentLocation != null
                    ? {
                      Marker(
                        markerId: const MarkerId('current-location'),
                        position: widget.currentLocation!,
                        infoWindow: const InfoWindow(
                          title: 'Localização Atual',
                        ),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed,
                        ),
                      ),
                    }
                    : <Marker>{},
              ),
              polygons: polygons,
              circles: circles,
              onMapCreated: (controller) {
                mapController = controller;
              },
              onTap: _onMapTap,
            ),
          ),
          if (!widget.readonly)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
              child: Column(
                children: [
                  MyTextField(
                    controller: locationAddressController,
                    hintText: 'Endereço',
                    obscureText: false,
                    required: false,
                  ),
                  const SizedBox(height: 15),
                  MyButton(
                    onTap: _searchAddress,
                    text: 'Buscar endereço',
                    color: Color.fromARGB(255, 153, 153, 153),
                  ),
                  const SizedBox(height: 10),
                  MyButton(
                    onTap: () {
                      Navigator.pop(context, area);
                    },
                    text: 'Confirmar área',
                    color: Color.fromARGB(255, 38, 166, 154),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
