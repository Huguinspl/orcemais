import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final MobileScannerController controller = MobileScannerController();
  bool _isScanComplete = false;
  // ✅ CORREÇÃO 1: Adicionar uma variável para controlar o estado do ícone da lanterna
  bool _isFlashOn = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanComplete) return;

    final String? code = capture.barcodes.first.rawValue;
    if (code != null) {
      setState(() {
        _isScanComplete = true;
      });
      Navigator.pop(context, code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Código'),
        actions: [
          // ✅ CORREÇÃO 2: Simplificando o botão da lanterna
          IconButton(
            // O ícone agora muda com base na nossa variável _isFlashOn
            icon: Icon(
              _isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: _isFlashOn ? Colors.yellow : Colors.white,
            ),
            onPressed: () {
              // Liga/desliga a lanterna
              controller.toggleTorch();
              // Atualiza o estado do nosso ícone
              setState(() {
                _isFlashOn = !_isFlashOn;
              });
            },
            tooltip: 'Lanterna',
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(controller: controller, onDetect: _onDetect),
          // O Overlay (interface sobre a câmera)
          Container(
            decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(
                  color: Colors.black.withOpacity(0.5),
                  width: MediaQuery.of(context).size.height * 0.3,
                ),
                vertical: BorderSide(
                  color: Colors.black.withOpacity(0.5),
                  width: MediaQuery.of(context).size.width * 0.1,
                ),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Posicione o código de barras na área',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  backgroundColor: Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
