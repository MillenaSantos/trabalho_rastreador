import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:trabalho_rastreador/components/customButton.dart';
import 'package:trabalho_rastreador/components/customTextfield.dart';
import 'package:trabalho_rastreador/utils/toastMessages.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  BitmapDescriptor markerIcon = BitmapDescriptor.defaultMarker;

  LatLng initialCamera = LatLng(-23.550520, -46.633308);

  //lista de coordenadas
  List<LatLng> area = [];
  GoogleMapController? mapController;
  bool isLoading = true;

  final TextEditingController locationAddressController =
      TextEditingController();

  @override
  void initState() {
    _getCurrentPosition();
    super.initState();
  }

  void _getCurrentPosition() async {
    if (isLoading) {
      LocationPermission permission = await Geolocator.checkPermission();
      //verifica a permissão da localização e pede autorização se estiver negada
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        LocationPermission requestedPermission =
            await Geolocator.requestPermission();
        //verifica se não aceitou
        if (requestedPermission == LocationPermission.denied ||
            requestedPermission == LocationPermission.deniedForever) {
          print('Permissões negadas');
          return;
        }
      }

      Position location = await Geolocator.getCurrentPosition();

      setState(() {
        //vai trocar a localização padrão pela atual
        initialCamera = LatLng(location.latitude, location.longitude);
        isLoading = false;
      });
    }
    //vai atualizar o mapa com a localização correta

    mapController?.animateCamera(CameraUpdate.newLatLng(initialCamera));
    
  }

  Future<void> _searchAddress() async {
    String address = locationAddressController.text;

    try {
      //tenta converter o endereço digitado pra coordenadas
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        //pega a primeira da lista
        Location location = locations.first;

        //move o mapa pra coordenada encontrada
        mapController?.animateCamera(
          CameraUpdate.newLatLng(LatLng(location.latitude, location.longitude)),
        );
      } else {
        ToastMessage().warning(message: 'Endereço não encontrado');
      }
    } catch (e) {
      ToastMessage().error(message: 'Erro ao buscar o endereço');
    }
  }

  void _onMapTap(LatLng location) {
    setState(() {
      if (area.length < 2) {
        area.add(location);
      } else {
        ToastMessage().warning(message: 'Você só pode selecionar dois pontos.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Marker> markers =
        area.map((location) {
          var index = area.indexOf(location);
          //vai criar um marcador pra cada area da lista
          return Marker(
            markerId: MarkerId('area-$index'),
            position: LatLng(location.latitude, location.longitude),
            draggable: true,
            //vai atualizar a posição do marcador
            onDragEnd: (location) {
              setState(() {
                area.replaceRange(index, index + 1, [location]);
              });
            },
            //tocar no marcador remove ele
            onTap: () {
              setState(() {
                area.removeAt(index);
              });
            },
            icon: markerIcon,
          );
        }).toList();

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              //detectar toques no mapa
              onTap: _onMapTap,
              //salva o controlador do mapa em mapController
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: initialCamera,
                zoom: 14,
              ),
              markers: Set<Marker>.of(markers),
              circles:
                  area.length == 2
                      ? {
                        Circle(
                          circleId: CircleId('circle-area'),
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
                      : {},
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 25),
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
                  color: Colors.black,
                ),
                const SizedBox(height: 10),
                MyButton(
                  onTap: () {
                    Navigator.pop(context, area);
                  },
                  text: 'Confirmar área',
                  color: Colors.deepPurple.shade600,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
