import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Result model
// ─────────────────────────────────────────────────────────────────────────────

class BarcodeResult {
  final String value;
  final BarcodeFormat format;
  const BarcodeResult({required this.value, required this.format});
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

class BarcodeService {
  final _controller = StreamController<BarcodeResult>.broadcast();

  /// Stream of scanned barcodes (from camera or HID keyboard input).
  Stream<BarcodeResult> get barcodes => _controller.stream;

  /// Start listening for HID barcode scanner input on the given [FocusNode].
  /// Returns a KeyEventResult to handle focus.
  final _buffer = StringBuffer();
  Timer? _debounce;

  KeyEventResult handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final char = event.character;
      if (char != null && char.isNotEmpty) {
        _buffer.write(char);
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 100), _flushBuffer);
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        _debounce?.cancel();
        _flushBuffer();
      }
    }
    return KeyEventResult.ignored;
  }

  void _flushBuffer() {
    final value = _buffer.toString().trim();
    _buffer.clear();
    if (value.isNotEmpty) {
      _controller.add(BarcodeResult(
        value: value,
        format: BarcodeFormat.unknown,
      ));
    }
  }

  /// Emit a barcode from camera scan.
  void handleCameraBarcode(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.isNotEmpty) {
        _controller.add(BarcodeResult(
          value: raw,
          format: barcode.format,
        ));
      }
    }
  }

  void dispose() {
    _debounce?.cancel();
    _controller.close();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final barcodeServiceProvider = Provider<BarcodeService>((ref) {
  final service = BarcodeService();
  ref.onDispose(service.dispose);
  return service;
});

/// Stream of barcode scan results.
final barcodeScanProvider = StreamProvider<BarcodeResult>((ref) {
  return ref.watch(barcodeServiceProvider).barcodes;
});
