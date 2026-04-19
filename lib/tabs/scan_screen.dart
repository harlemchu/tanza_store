import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../controllers/database_helper.dart';
import '../views/add_edit_screen.dart';
import '../views/details_screen.dart';

class ScanScreen extends StatefulWidget {
  final bool isCashierMode;
  const ScanScreen({super.key, this.isCashierMode = false});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;
  bool _isClosing = false; // NEW: prevent multiple navigation attempts

  @override
  void dispose() {
    // FIX: Dispose controller only when the screen is fully gone
    _controller.dispose();
    super.dispose();
  }

  // Helper to safely navigate away after stopping the camera
  Future<void> _navigateAndStop(FutureOr<dynamic> result) async {
    if (_isClosing) return;
    _isClosing = true;

    // Stop the camera and wait for it to release resources
    await _controller.stop();
    // Give the platform time to detach the texture (critical for Impeller)
    await Future.delayed(const Duration(milliseconds: 150));

    if (mounted) {
      Navigator.pop(context, result);
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _isClosing) return;
    _isProcessing = true;

    final barcode = capture.barcodes.first;
    final rawValue = barcode.rawValue;
    if (rawValue == null) {
      _isProcessing = false;
      return;
    }

    final format = barcode.format;
    final bool isQR = format == BarcodeFormat.qrCode ||
        format == BarcodeFormat.pdf417 ||
        format == BarcodeFormat.aztec ||
        format == BarcodeFormat.dataMatrix;
    final type = isQR ? 'qr' : 'barcode';

    final existing = await DatabaseHelper().getCodeByCode(rawValue);

    // ------------------------------
    // CASHIER MODE
    // ------------------------------
    if (widget.isCashierMode) {
      if (existing != null) {
        // Stop camera and return the product
        await _navigateAndStop(existing);
      } else {
        // Product not found – ask to add
        if (mounted) {
          final shouldAdd = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text('Product Not Found'),
              content: Text(
                  'Barcode $rawValue not found.\nDo you want to add it now?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Add'),
                ),
              ],
            ),
          );
          if (shouldAdd == true && mounted) {
            // Stop camera before pushing add screen
            await _controller.stop();
            await Future.delayed(const Duration(milliseconds: 150));
            if (!mounted) return;
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
              final added = await DatabaseHelper().getCodeByCode(rawValue);
              if (added != null && mounted) {
                await _navigateAndStop(added);
              } else if (mounted) {
                await _navigateAndStop(null);
              }
            } else if (mounted) {
              await _navigateAndStop(null);
            }
          } else if (mounted) {
            await _navigateAndStop(null);
          }
        }
      }
      _isProcessing = false;
      return;
    }

    // ------------------------------
    // ORIGINAL BEHAVIOR (non‑cashier)
    // ------------------------------
    if (existing != null) {
      if (mounted) {
        // Stop the camera to prevent multiple detections
        await _controller.stop();
        // Wait for the detail screen to be popped
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailsScreen(codeItem: existing),
          ),
        );
        // Restart the camera after returning
        await _controller.start();
        // Allow new scans
        _isProcessing = false;
        return; // Important: exit the function
      }
    } else {
      if (mounted) {
        // await _controller.stop();
        // await Future.delayed(const Duration(milliseconds: 150));
        if (!mounted) return;
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
        if (result == true) {
          Navigator.pop(context, true);
        } else {
          Navigator.pop(context);
        }
        _isProcessing = false;
        return; // Important: exit the function
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Code'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller.torchState,
              builder: (context, state, child) {
                return Icon(
                  state == TorchState.on ? Icons.flash_on : Icons.flash_off,
                );
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller.cameraFacingState,
              builder: (context, state, child) {
                return Icon(
                  state == CameraFacing.front
                      ? Icons.camera_front
                      : Icons.camera_rear,
                );
              },
            ),
            onPressed: () => _controller.switchCamera(),
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
