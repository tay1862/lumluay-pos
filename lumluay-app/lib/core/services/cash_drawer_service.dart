import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'print_service.dart';

/// Opens a cash drawer by sending ESC/POS kick-drawer command via the
/// connected receipt printer.
class CashDrawerService {
  final PrintService _printService;

  CashDrawerService(this._printService);

  /// Sends pin-2 kick command (standard for most cash drawers).
  Future<void> openDrawer() async {
    final bytes = await _buildOpenCommand();
    await _printService.printRaw(bytes);
  }

  Future<Uint8List> _buildOpenCommand() async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];
    bytes += generator.reset();
    // ESC/POS: ESC p m t1 t2 — kick drawer on pin 2
    bytes += [0x1B, 0x70, 0x00, 0x19, 0xFA];
    return Uint8List.fromList(bytes);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Printer mode selection providers (17.1.2 – 17.1.4)
// ─────────────────────────────────────────────────────────────────────────────

/// Active printer mode.  Default: 'pdf' (system print dialog / browser print).
/// Other options: 'network', 'bluetooth', 'usb'.
final printerModeProvider = StateProvider<String>((ref) => 'pdf');

/// Network printer host (IP or hostname).
final printerNetworkHostProvider =
    StateProvider<String>((ref) => '192.168.1.100');

/// Network printer port (default ESC/POS TCP port).
final printerNetworkPortProvider = StateProvider<int>((ref) => 9100);

/// Bluetooth device ID (MAC on Android, UUID on iOS).
final printerBtDeviceIdProvider = StateProvider<String>((ref) => '');

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final cashDrawerServiceProvider = Provider<CashDrawerService>((ref) {
  final printService = ref.watch(printServiceProvider);
  return CashDrawerService(printService);
});

final printServiceProvider = Provider<PrintService>((ref) {
  final mode = ref.watch(printerModeProvider);
  switch (mode) {
    case 'bluetooth':
      final deviceId = ref.watch(printerBtDeviceIdProvider);
      return BluetoothPrinter(deviceId);
    case 'network':
      final host = ref.watch(printerNetworkHostProvider);
      final port = ref.watch(printerNetworkPortProvider);
      return NetworkPrinter(host, port);
    case 'usb':
      return UsbPrinterService();
    default:
      return FlutterPrintService();
  }
});
