import 'package:app_flutter_parking/views/map/map_view.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mqtt_repository/mqtt_repository.dart';
import 'package:provider/provider.dart';

class MapCard extends StatelessWidget {
  const MapCard({
    required this.map,
    super.key,
  });

  final MapPage map;
  final bool sat = false;

  List<LatLng> getVagas(bool sat) {
    return List.generate(4, (index) {
      final double baseLat = sat ? -5.886140 : -5.886090;
      final double baseLng = -35.363278;
      final double stepLat = index * (sat ? 0.000003 : 0.000002);
      final double stepLng = index * 0.00003;
      return LatLng(baseLat + stepLat, baseLng + stepLng);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 700),
            pageBuilder: (_, animation, __) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 1.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.fastEaseInToSlowEaseOut,
                  )),
                  child: map,
                ),
              );
            },
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
        child: Neumorphic(
          style: NeumorphicStyle(
            depth: 6,
            color: Colors.cyan[50],
            shadowLightColor: Colors.grey,
            intensity: 0.8,
            shape: NeumorphicShape.flat,
          ),
          child: SizedBox(
            height: 200.h,
            child: AbsorbPointer(
              child: Consumer<ParkingViewModel>(
                builder: (context, viewModel, _) {
                  final vagasVM = viewModel.vagas;
                  final coordenadas = getVagas(sat);

                  return FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(-5.886040, -35.363120),
                      initialZoom: 20.7,
                      initialRotation: 0.9,
                      maxZoom: 20.9,
                    ),
                    children: [
                      sat
                          ? TileLayer(
                              urlTemplate:
                                  'https://api.mapbox.com/styles/v1/mapbox/satellite-v9/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1Ijoic2hvbG9sb3BhIiwiYSI6ImNtYnZscGp0cDBzbjYya3EzbXRtcGY2ejkifQ.3uUmWAzuH2Xxkdqqs4MNHw',
                              userAgentPackageName:
                                  'parking.app.com.app_flutter_parking',
                              additionalOptions: {
                                'access_token':
                                    'pk.eyJ1Ijoic2hvbG9sb3BhIiwiYSI6ImNtYnZscGp0cDBzbjYya3EzbXRtcGY2ejkifQ.3uUmWAzuH2Xxkdqqs4MNHw',
                              },
                            )
                          : TileLayer(
                              urlTemplate:
                                  "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                              subdomains: ['a', 'b', 'c'],
                            ),
                      MarkerLayer(
                        markers: coordenadas.asMap().entries.map((entry) {
                          final index = entry.key;
                          final position = entry.value;
                          final vaga = index < vagasVM.length ? vagasVM[index] : null;

                          final Color color;
                          if (vaga?.ocupada == true) {
                            color = Colors.red;
                          } else if (vaga?.reservada == true) {
                            color = Colors.blue;
                          } else {
                            color = Colors.green;
                          }

                          return Marker(
                            point: position,
                            width: 35,
                            height: 70,
                            child: Container(
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.black),
                              ),
                              child: Center(
                                child: Text(
                                  vaga?.id ?? 'V${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
