import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../controllers/database_helper.dart';
import 'add_edit_screen.dart';
import 'details_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    _isProcessing = true;

    final barcode = capture.barcodes.first;
    final rawValue = barcode.rawValue;
    if (rawValue == null) {
      _isProcessing = false;
      return;
    }

    // Determine type: barcode or qr
    final format = barcode.format;
    final bool isQR = format == BarcodeFormat.qrCode ||
        format == BarcodeFormat.pdf417 ||
        format == BarcodeFormat.aztec ||
        format == BarcodeFormat.dataMatrix;
    final type = isQR ? 'qr' : 'barcode';

    // Check database
    final existing = await DatabaseHelper().getCodeByCode(rawValue);
    if (existing != null) {
      // Found: go to details
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DetailsScreen(codeItem: existing),
          ),
        );
      }
    } else {
      // Not found: prompt to add
      if (mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddEditScreen(
              code: rawValue,
              type: type,
              isEditing: false,
            ),
          ),
        );
        if (result == true && mounted) {
          Navigator.pop(context, true);
        } else {
          Navigator.pop(context);
        }
      }
    }
    _isProcessing = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Code'),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.image_search),
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //           builder: (_) => const ImageRecognitionScreen()),
          //     );
          //   },
          //   tooltip: 'Image Recognition',
          // ),
          // Torch button with state listener
          ValueListenableBuilder(
            valueListenable: _controller.torchState,
            builder: (context, state, child) {
              return IconButton(
                icon: Icon(
                  state == TorchState.on ? Icons.flash_on : Icons.flash_off,
                ),
                onPressed: () => _controller.toggleTorch(),
              );
            },
          ),
          // Camera switch button with state listener
          ValueListenableBuilder(
            valueListenable: _controller.cameraFacingState,
            builder: (context, state, child) {
              return IconButton(
                icon: Icon(
                  state == CameraFacing.front
                      ? Icons.camera_front
                      : Icons.camera_rear,
                ),
                onPressed: () => _controller.switchCamera(),
              );
            },
          ),
        ],
      ),
      body: MobileScanner(
        controller: _controller,
        onDetect: _onDetect,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.black87,
        child: const Text(
          'Point camera at QR or barcode',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
