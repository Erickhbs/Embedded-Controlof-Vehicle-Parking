
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomAppbar extends StatelessWidget {
  const CustomAppbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Neumorphic(
      padding: EdgeInsets.all(8),
      style: const NeumorphicStyle(
        depth: 2,
        intensity: 1.5,
        surfaceIntensity: 1,
        shape: NeumorphicShape.concave,
        color: Colors.white,
        shadowLightColor: Colors.grey
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          SizedBox(width: 8),
          Text(
            "Controlador Estacionamento",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black
            ),
          ),
          Neumorphic(
            style: const NeumorphicStyle(
              depth: 2,
              intensity: 1.5,
              surfaceIntensity: 1,
              shape: NeumorphicShape.concave,
              color: Colors.white,
              shadowLightColor: Colors.white
            ),
            padding: EdgeInsets.all(8),
            duration: Duration(microseconds: 1500),
            child: SvgPicture.asset(
              'assets/icons/user.svg',
              width: 20.r,
              height: 20.r,
              colorFilter: ColorFilter.linearToSrgbGamma(),
              placeholderBuilder: (context) => SizedBox(
                width: 20.r,
                height: 20.r,
              ),
            )
          )
        ],
      ),
    );
  }
}
