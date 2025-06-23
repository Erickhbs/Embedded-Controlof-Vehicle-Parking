import 'package:app_flutter_parking/views/components/info_component.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mqtt_repository/mqtt_repository.dart';
import 'package:provider/provider.dart';

class MapPage extends StatefulWidget {
  final void Function(Vaga)? onReserva;
  final Vaga? vagaReservada;
  final void Function(String message)? onAviso;

  const MapPage({
    super.key,
    this.onReserva,
    this.vagaReservada,
    this.onAviso,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final LatLng labInfo = LatLng(-5.885996, -35.363136);
  final double initialZoom = 20.7;
  final double maxZoom = 20.9;
  double currentZoom = 21.0;
  LatLng? userLocation;
  bool sat = false;
  final MapController userPositionController = MapController();

  final List<LatLng> coordenadasFixas = [
    LatLng(-5.886102, -35.363278), // V1
    LatLng(-5.886098, -35.363248), // V2
    LatLng(-5.886095, -35.363218), // V3
    LatLng(-5.886092, -35.363188), // V4
  ];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.requestPermission();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();

    if (!mounted) return;

    setState(() {
      userLocation = LatLng(position.latitude, position.longitude);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ParkingViewModel>();
    final vagas = viewModel.vagas;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: userPositionController,
            options: MapOptions(
              initialCenter: labInfo,
              initialZoom: initialZoom,
              maxZoom: maxZoom,
              minZoom: 7,
              onPositionChanged: (position, hasGesture) {
                setState(() {
                  currentZoom = position.zoom;
                });
              },
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
              ),
            ),
            children: [
              sat
                  ? TileLayer(
                      urlTemplate:
                          'https://api.mapbox.com/styles/v1/mapbox/satellite-v9/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1Ijoic2hvbG9sb3BhIiwiYSI6ImNtYnZscGp0cDBzbjYya3EzbXRtcGY2ejkifQ.3uUmWAzuH2Xxkdqqs4MNHw',
                      userAgentPackageName: 'parking.app.com.app_flutter_parking',
                      additionalOptions: {
                        'access_token':
                            'pk.eyJ1Ijoic2hvbG9sb3BhIiwiYSI6ImNtYnZscGp0cDBzbjYya3EzbXRtcGY2ejkifQ.3uUmWAzuH2Xxkdqqs4MNHw',
                      },
                    )
                  : TileLayer(
                      urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: ['a', 'b', 'c'],
                    ),

              if (userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: userLocation!,
                      width: 60,
                      height: 60,
                      child: const Icon(
                        Icons.person_pin_circle_rounded,
                        color: Color.fromARGB(255, 31, 157, 132),
                        size: 50,
                      ),
                    ),
                  ],
                ),

              if (currentZoom >= (maxZoom - 1))
                MarkerLayer(
                  markers: vagas.asMap().entries.map((entry) {
                    final index = entry.key;
                    final vaga = entry.value;
                    final latLng = (index < coordenadasFixas.length)
                        ? coordenadasFixas[index]
                        : labInfo;

                    return Marker(
                      point: latLng,
                      width: 35,
                      height: 70,
                      child: GestureDetector(
                        onTap: () {
                          if (vaga.reservada == true) {
                            viewModel.cancelarReserva(vaga.id!);
                            if (widget.onReserva != null) {
                              widget.onReserva!(vaga);
                            }
                          } else {
                            if (widget.vagaReservada != null && widget.vagaReservada!.id != vaga.id) {
                              if (widget.onAviso != null) {
                                widget.onAviso!(
                                  'Você já possui uma vaga reservada: ${widget.vagaReservada!.id}'
                                );
                              }
                              return; 
                            }
                            viewModel.fazerReserva(vaga.id!);
                            if (widget.onReserva != null) {
                              widget.onReserva!(vaga);
                            }
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: vaga.ocupada == true
                                ? Colors.red.withOpacity(0.8)
                                : vaga.reservada == true
                                    ? Colors.blue.withOpacity(0.8)
                                    : Colors.green.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.black),
                          ),
                          child: Center(
                            child: Text(
                              vaga.id ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

              MarkerLayer(
                markers: [
                  Marker(
                    point: labInfo,
                    width: 110,
                    height: 60,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Center(
                        child: Text(
                          'Lab. de Informática',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          Positioned(
            top: 60,
            left: 16,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
              label: const Text("Voltar", style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 16,
            right: 16,
            child: ElevatedButton.icon(
              onPressed: () => setState(() {
                sat = !sat;
              }),
              icon: Icon(
                sat ? Icons.map_rounded : Icons.satellite_alt_outlined,
                color: Colors.blue,
              ),
              label: Text(
                sat ? "Imagem de Mapa" : "Imagem de Satélite",
                style: const TextStyle(color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const InfoPannel(),
        ],
      ),
    );
  }
}
