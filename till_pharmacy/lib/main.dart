import 'package:flutter/material.dart';
import 'screens/pos_screen.dart';

void main() {
  runApp(const TillPharmacy());
}

class TillPharmacy extends StatelessWidget {
  const TillPharmacy({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Till Pharmacy',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const PosScreen(),
    );
  }
}