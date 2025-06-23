import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:mqtt_repository/mqtt_repository.dart';

class VagasPannel extends StatelessWidget {
  const VagasPannel({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ParkingViewModel>();
    final vagas = viewModel.vagas;
    final vagaReservada = viewModel.vagaReservada; // Assumindo que exista esta propriedade

    return Neumorphic(
      margin: EdgeInsets.symmetric(vertical: 12.h),
      padding: EdgeInsets.all(12.w),
      style: NeumorphicStyle(
        depth: 2,
        intensity: 1.5,
        surfaceIntensity: 1,
        shape: NeumorphicShape.concave,
        color: Colors.white,
        shadowLightColor: Colors.grey,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Vagas Disponíveis",
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: vagas.map((vaga) {
              final bool ocupada = vaga.ocupada ?? false;
              final bool reservada = vaga.reservada ?? false;

              Color color;
              if (ocupada) {
                color = Colors.red;
              } else if (reservada) {
                color = Colors.blue;
              } else {
                color = Colors.green;
              }

              return GestureDetector(
                onTap: () {
                  if (!ocupada) {
                    if (reservada) {
                      // Se clicar em vaga reservada, cancela reserva normalmente
                      viewModel.cancelarReserva(vaga.id!);
                    } else {
                      // Aqui bloqueia se já tiver vaga reservada diferente
                      if (vagaReservada != null && vagaReservada.id != vaga.id) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Você já possui uma vaga reservada: ${vagaReservada.id}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        return; // bloqueia nova reserva
                      }

                      // Se não tiver reserva ativa ou for a mesma vaga, faz reserva
                      viewModel.fazerReserva(vaga.id!);
                    }
                  }
                },
                child: Neumorphic(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  style: NeumorphicStyle(
                    depth: 2,
                    color: color.withOpacity(0.8),
                    shadowLightColor: Colors.white,
                    shape: NeumorphicShape.flat,
                  ),
                  child: Text(
                    vaga.id ?? '',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
