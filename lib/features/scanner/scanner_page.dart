import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../correcao/correcao_page.dart';
import 'cartao_gerador_page.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    formats: const [
      BarcodeFormat.qrCode,
      BarcodeFormat.code39,
      BarcodeFormat.code128,
    ],
  );

  final TextEditingController manualCodeController = TextEditingController();
  String? lastDetectedCode;

  @override
  void dispose() {
    controller.dispose();
    manualCodeController.dispose();
    super.dispose();
  }

  String _normalizeCode(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  void _openCorrection(String rawValue) {
    final value = _normalizeCode(rawValue);
    if (value.isEmpty) {
      return;
    }

    setState(() => lastDetectedCode = value);

    if (!mounted) {
      return;
    }

    controller.stop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CorrecaoPage(codigo: value),
      ),
    ).then((_) {
      if (mounted) {
        controller.start();
      }
    });
  }

  void _handleDetection(BarcodeCapture capture) {
    final barcodes = capture.barcodes;

    if (barcodes.isEmpty) {
      return;
    }

    final barcode = barcodes.first;
    final value = barcode.rawValue;

    if (value == null || value.isEmpty || value == lastDetectedCode) {
      return;
    }

    _openCorrection(value);
  }

  Future<void> _confirmManualCode() async {
    final value = _normalizeCode(manualCodeController.text);
    if (value.isEmpty) {
      return;
    }

    manualCodeController.clear();
    _openCorrection(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner de cartão-resposta'),
        actions: [
          IconButton(
            tooltip: 'Gerar cartão QRCode',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CartaoGeradorPage(),
                ),
              );
            },
            icon: const Icon(Icons.qr_code_2_rounded),
          ),
          IconButton(
            tooltip: 'Ligar lanterna',
            onPressed: () => controller.toggleTorch(),
            icon: const Icon(Icons.flashlight_on_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _handleDetection,
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double size = constraints.maxWidth * 0.72;
                  return Center(
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: const [
                          BoxShadow(color: Color(0x66000000), blurRadius: 12),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 28,
            child: Card(
              color: Colors.black.withValues(alpha: 0.5),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code_scanner_rounded,
                        color: Colors.white, size: 30),
                    const SizedBox(height: 12),
                    const Text(
                      'Posicione o cartão dentro da área de leitura ou digite o código abaixo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: manualCodeController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Cole o código do cartão',
                        hintStyle: const TextStyle(color: Color(0xFFCBD5E1)),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          onPressed: _confirmManualCode,
                          icon: const Icon(Icons.arrow_forward_rounded,
                              color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (lastDetectedCode != null)
                      Text(
                        'Último código: $lastDetectedCode',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFBFDBFE),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
