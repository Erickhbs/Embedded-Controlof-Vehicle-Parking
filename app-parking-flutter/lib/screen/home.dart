import 'package:flutter/material.dart';
import 'package:parking_lot/screen/component/estacionamento.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.onSurface,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        title: Text('Estacionamento', style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 30,
          color: Theme.of(context).colorScheme.onSecondary,
        ),),
      ),
      body: Estacionamento(),
    );
  }
}