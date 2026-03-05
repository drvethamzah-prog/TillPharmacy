import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {

  String barcode = "No barcode scanned";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Till Pharmacy POS'),
      ),
      body: Column(
        children: [

          const SizedBox(height:20),

          Text(
            barcode,
            style: const TextStyle(fontSize:20),
          ),

          const SizedBox(height:20),

          Expanded(
            child: MobileScanner(
              onDetect: (barcodeCapture) {
                final List<Barcode> barcodes = barcodeCapture.barcodes;
                for (final code in barcodes) {
                  setState(() {
                    barcode = code.rawValue ?? "Unknown";
                  });
                }
              },
            ),
          ),

        ],
      ),
    );
  }
}