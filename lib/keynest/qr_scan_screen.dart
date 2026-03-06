import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QRを読み取る')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (_handled) {
                return;
              }
              for (final barcode in capture.barcodes) {
                final value = barcode.rawValue?.trim();
                if (value != null && value.isNotEmpty) {
                  _handled = true;
                  Navigator.of(context).pop(value);
                  break;
                }
              }
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'otpauth QRコードを中央に合わせてください',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
