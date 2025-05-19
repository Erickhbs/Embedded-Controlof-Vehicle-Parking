import 'package:flutter/material.dart';
import 'package:parking_lot/screen/home.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          onPrimary: Colors.white,
          onSecondary: Color(0xFF17192D),
          onTertiary: Color(0xFF2188FF),
          onSurface: Colors.grey,
          onSurfaceVariant: Colors.white30
        ),
      ),
      home: const Home(),
    );
  }
}