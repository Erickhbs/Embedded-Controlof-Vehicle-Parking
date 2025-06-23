import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';

class InfoPannel extends StatelessWidget {
  const InfoPannel({super.key});

  Widget _buildLegenda(String texto, Color cor) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          Neumorphic(
            padding: EdgeInsets.all(8.w),
            style: NeumorphicStyle(
              depth: 2,
              intensity: 1.5,
              surfaceIntensity: 1,
              shape: NeumorphicShape.concave,
              color: cor,
              shadowLightColor: Colors.white,
            ),
            child: const Icon(
              Icons.local_parking_rounded,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            texto,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      left: 16,
      child: Neumorphic(
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
            _buildLegenda("Vaga Livre", Colors.green),
            _buildLegenda("Vaga Reservada", Colors.blue),
            _buildLegenda("Vaga Ocupada", Colors.red),
          ],
        ),
      ),
    );
  }
}
