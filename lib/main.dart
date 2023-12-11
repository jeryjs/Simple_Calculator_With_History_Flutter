import 'package:flutter/material.dart';
import 'package:simple_calculator/calculator.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.greenAccent,
      ),
      home: const Scaffold(
        body: Center(
          child: Calculator(),
        ),
      ),
    );
  }
}
