import 'package:app_flutter_parking/views/app.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_repository/mqtt_repository.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ParkingViewModel(MqttRepository()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

