import 'dart:async';
import 'package:app_flutter_parking/views/components/Card_Map.dart';
import 'package:app_flutter_parking/views/components/app_bar.dart';
import 'package:app_flutter_parking/views/components/info_component.dart';
import 'package:app_flutter_parking/views/components/pannel_bar.dart';
import 'package:app_flutter_parking/views/map/map_view.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:mqtt_repository/mqtt_repository.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  Key mapKey = UniqueKey();
  Vaga? minhaReserva;
  Timer? _timer;
  double progress = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {
        mapKey = UniqueKey();
      });
    }
  }

  void iniciarContador(Vaga vaga) {
    _timer?.cancel();
    const duracao = Duration(minutes: 10);
    const intervalo = Duration(seconds: 1);
    int totalSegundos = duracao.inSeconds;
    int segundosRestantes = totalSegundos;

    setState(() {
      minhaReserva = vaga;
      progress = 0;
    });

    _timer = Timer.periodic(intervalo, (timer) {
      setState(() {
        segundosRestantes--;
        progress = 1 - (segundosRestantes / totalSegundos);
      });

      if (segundosRestantes <= 0) {
        timer.cancel();
        final viewModel = context.read<ParkingViewModel>();
        if (minhaReserva != null) {
          viewModel.cancelarReserva(minhaReserva!.id!);
          setState(() {
            minhaReserva = null;
            progress = 0;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ParkingViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 45.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: const CustomAppbar(),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: const InfoPannel(),
                ),
                MapCard(
                  key: mapKey,
                  map: MapPage(
                    vagaReservada: minhaReserva,
                    onAviso: (msg) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
                      );
                    },
                    onReserva: (vaga) {
                      if (vaga == null) return;
                      if (minhaReserva != null) {
                        // Já tem reserva, avisa o usuário
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Você já tem uma vaga reservada. Cancele a reserva atual para fazer outra.'),
                            duration: Duration(seconds: 3),
                          ),
                        );
                        return;
                      }
                      iniciarContador(vaga);
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: VagasPannel(),
                ),
                if (minhaReserva != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vaga Reservada: ${minhaReserva!.id}',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(seconds: 1),
                              width: MediaQuery.of(context).size.width * progress,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.blueAccent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            top: 136.h,
            right: 12.w,
            child: ElevatedButton.icon(
              onPressed: () {
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
                          child: const MapPage(),
                        ),
                      );
                    },
                  ),
                );
              },
              label: const Text("Ver no Mapa", style: TextStyle(color: Colors.black)),
              icon: const Icon(Icons.map, color: Colors.blue),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
