import 'dart:io' show Socket;
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:usb_serial/usb_serial.dart';

/// Abstract interface for printing receipts & kitchen tickets.
abstract class PrintService {
  /// Print an order receipt to the default printer / PDF viewer.
  Future<void> printReceipt(ReceiptData receipt);

  /// Print a kitchen ticket to the default printer.
  Future<void> printKitchenTicket(KitchenTicketData ticket);

  /// Print raw ESC/POS bytes to a network (TCP) printer.
  Future<void> printRaw(Uint8List bytes);
}

// ─────────────────────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────────────────────

class ReceiptItem {
  final String name;
  final int qty;
  final double unitPrice;
  final double lineTotal;
  const ReceiptItem({
    required this.name,
    required this.qty,
    required this.unitPrice,
    required this.lineTotal,
  });
}

class ReceiptData {
  final String tenantName;
  final String? tenantAddress;
  final String? tenantPhone;
  final String receiptNumber;
  final DateTime printedAt;
  final String? cashierName;
  final String? tableName;
  final List<ReceiptItem> items;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double total;
  final String? paymentMethod;
  final double? amountPaid;
  final double? changeAmount;
  final String? footer;

  const ReceiptData({
    required this.tenantName,
    this.tenantAddress,
    this.tenantPhone,
    required this.receiptNumber,
    required this.printedAt,
    this.cashierName,
    this.tableName,
    required this.items,
    required this.subtotal,
    this.discountAmount = 0,
    this.taxAmount = 0,
    required this.total,
    this.paymentMethod,
    this.amountPaid,
    this.changeAmount,
    this.footer,
  });
}

class KitchenTicketItem {
  final String name;
  final int qty;
  final String? notes;
  const KitchenTicketItem({required this.name, required this.qty, this.notes});
}

class KitchenTicketData {
  final String orderNumber;
  final String? tableName;
  final String? orderType;
  final DateTime createdAt;
  final List<KitchenTicketItem> items;
  const KitchenTicketData({
    required this.orderNumber,
    this.tableName,
    this.orderType,
    required this.createdAt,
    required this.items,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Printing (PDF / system dialog) implementation
// ─────────────────────────────────────────────────────────────────────────────

class FlutterPrintService implements PrintService {
  @override
  Future<void> printReceipt(ReceiptData receipt) async {
    final pdfBytes = await ReceiptBuilder.buildPdf(receipt);
    await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
  }

  @override
  Future<void> printKitchenTicket(KitchenTicketData ticket) async {
    final bytes = await KitchenTicketBuilder.buildEscPos(ticket);
    await printRaw(bytes);
  }

  @override
  Future<void> printRaw(Uint8List bytes) async {
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Receipt PDF Builder
// ─────────────────────────────────────────────────────────────────────────────

class ReceiptBuilder {
  ReceiptBuilder._();

  static Future<Uint8List> buildPdf(ReceiptData data) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSansThaiRegular();
    final fontBold = await PdfGoogleFonts.notoSansThaiBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, double.infinity,
            marginAll: 4 * PdfPageFormat.mm),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Header
            pw.Center(
              child: pw.Text(data.tenantName,
                  style: pw.TextStyle(font: fontBold, fontSize: 14)),
            ),
            if (data.tenantAddress != null)
              pw.Center(
                  child: pw.Text(data.tenantAddress!,
                      style: pw.TextStyle(font: font, fontSize: 9))),
            if (data.tenantPhone != null)
              pw.Center(
                  child: pw.Text(data.tenantPhone!,
                      style: pw.TextStyle(font: font, fontSize: 9))),
            pw.SizedBox(height: 4),
            pw.Divider(thickness: 0.5),

            // Receipt info
            _infoRow('Receipt#', data.receiptNumber, font: font),
            _infoRow(
                'Date',
                '${data.printedAt.day}/${data.printedAt.month}/${data.printedAt.year} ${data.printedAt.hour.toString().padLeft(2, '0')}:${data.printedAt.minute.toString().padLeft(2, '0')}',
                font: font),
            if (data.cashierName != null)
              _infoRow('Cashier', data.cashierName!, font: font),
            if (data.tableName != null)
              _infoRow('Table', data.tableName!, font: font),
            pw.Divider(thickness: 0.5),

            // Items
            ...data.items.map((item) => pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                        child: pw.Text('${item.qty}x ${item.name}',
                            style: pw.TextStyle(font: font, fontSize: 9))),
                    pw.Text(item.lineTotal.toStringAsFixed(2),
                        style: pw.TextStyle(font: font, fontSize: 9)),
                  ],
                )),
            pw.Divider(thickness: 0.5),

            // Totals
            _infoRow('Subtotal', data.subtotal.toStringAsFixed(2), font: font),
            if (data.discountAmount > 0)
              _infoRow('Discount', '-${data.discountAmount.toStringAsFixed(2)}',
                  font: font),
            if (data.taxAmount > 0)
              _infoRow('Tax', data.taxAmount.toStringAsFixed(2), font: font),
            pw.Divider(thickness: 0.5),
            _infoRow('TOTAL', data.total.toStringAsFixed(2),
                font: fontBold, fontSize: 12),
            if (data.paymentMethod != null)
              _infoRow('Payment', data.paymentMethod!, font: font),
            if (data.amountPaid != null)
              _infoRow('Paid', data.amountPaid!.toStringAsFixed(2), font: font),
            if (data.changeAmount != null)
              _infoRow('Change', data.changeAmount!.toStringAsFixed(2),
                  font: font),
            pw.SizedBox(height: 8),
            if (data.footer != null)
              pw.Center(
                  child: pw.Text(data.footer!,
                      style: pw.TextStyle(font: font, fontSize: 9))),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  static pw.Widget _infoRow(String label, String value,
      {required pw.Font font, double fontSize = 9}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(font: font, fontSize: fontSize)),
        pw.Text(value, style: pw.TextStyle(font: font, fontSize: fontSize)),
      ],
    );
  }

  /// Build an ESC/POS receipt for thermal printers (BT / USB / Network).
  static Future<Uint8List> buildEscPos(ReceiptData data) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    bytes += generator.reset();
    bytes += generator.setGlobalCodeTable('CP874');

    bytes += generator.text(data.tenantName,
        styles: const PosStyles(bold: true, align: PosAlign.center));
    if (data.tenantAddress != null) {
      bytes += generator.text(data.tenantAddress!,
          styles: const PosStyles(align: PosAlign.center));
    }
    if (data.tenantPhone != null) {
      bytes += generator.text(data.tenantPhone!,
          styles: const PosStyles(align: PosAlign.center));
    }
    bytes += generator.hr();

    bytes += generator.row([
      PosColumn(text: 'Receipt#', width: 5),
      PosColumn(text: data.receiptNumber, width: 7),
    ]);
    final ts = data.printedAt;
    bytes += generator.row([
      PosColumn(text: 'Date', width: 5),
      PosColumn(
          text:
              '${ts.day}/${ts.month}/${ts.year} ${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}',
          width: 7),
    ]);
    if (data.cashierName != null) {
      bytes += generator.row([
        PosColumn(text: 'Cashier', width: 5),
        PosColumn(text: data.cashierName!, width: 7),
      ]);
    }
    if (data.tableName != null) {
      bytes += generator.row([
        PosColumn(text: 'Table', width: 5),
        PosColumn(text: data.tableName!, width: 7),
      ]);
    }
    bytes += generator.hr();

    for (final item in data.items) {
      bytes += generator.row([
        PosColumn(
            text: '${item.qty}x ${item.name}',
            width: 10,
            styles: const PosStyles()),
        PosColumn(
            text: item.lineTotal.toStringAsFixed(2),
            width: 6,
            styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    bytes += generator.hr();

    bytes += generator.row([
      PosColumn(text: 'Subtotal', width: 8),
      PosColumn(
          text: data.subtotal.toStringAsFixed(2),
          width: 4,
          styles: const PosStyles(align: PosAlign.right)),
    ]);
    if (data.discountAmount > 0) {
      bytes += generator.row([
        PosColumn(text: 'Discount', width: 8),
        PosColumn(
            text: '-${data.discountAmount.toStringAsFixed(2)}',
            width: 4,
            styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    if (data.taxAmount > 0) {
      bytes += generator.row([
        PosColumn(text: 'Tax', width: 8),
        PosColumn(
            text: data.taxAmount.toStringAsFixed(2),
            width: 4,
            styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(
          text: 'TOTAL',
          width: 8,
          styles: const PosStyles(bold: true)),
      PosColumn(
          text: data.total.toStringAsFixed(2),
          width: 4,
          styles: const PosStyles(bold: true, align: PosAlign.right)),
    ]);

    if (data.paymentMethod != null) {
      bytes += generator.row([
        PosColumn(text: 'Payment', width: 8),
        PosColumn(text: data.paymentMethod!, width: 4,
            styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    if (data.amountPaid != null) {
      bytes += generator.row([
        PosColumn(text: 'Paid', width: 8),
        PosColumn(
            text: data.amountPaid!.toStringAsFixed(2),
            width: 4,
            styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    if (data.changeAmount != null) {
      bytes += generator.row([
        PosColumn(text: 'Change', width: 8),
        PosColumn(
            text: data.changeAmount!.toStringAsFixed(2),
            width: 4,
            styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    if (data.footer != null && data.footer!.isNotEmpty) {
      bytes += generator.text(data.footer!,
          styles: const PosStyles(align: PosAlign.center));
    }

    bytes += generator.feed(3);
    bytes += generator.cut();

    return Uint8List.fromList(bytes);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Kitchen Ticket ESC/POS Builder
// ─────────────────────────────────────────────────────────────────────────────

class KitchenTicketBuilder {
  KitchenTicketBuilder._();

  static Future<Uint8List> buildEscPos(KitchenTicketData data) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    bytes += generator.reset();
    bytes += generator.setGlobalCodeTable('CP874');

    bytes += generator.text('*** KITCHEN ***',
        styles: const PosStyles(
          bold: true,
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ));
    bytes += generator.text('Order #${data.orderNumber}',
        styles: const PosStyles(bold: true, align: PosAlign.center));
    if (data.tableName != null) {
      bytes += generator.text('Table: ${data.tableName}',
          styles: const PosStyles(align: PosAlign.center));
    }
    if (data.orderType != null) {
      bytes += generator.text('Type: ${data.orderType}',
          styles: const PosStyles(align: PosAlign.center));
    }
    final ts = data.createdAt;
    bytes += generator.text(
        '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}',
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.hr();

    for (final item in data.items) {
      bytes += generator.row([
        PosColumn(text: '${item.qty}x', width: 2, styles: const PosStyles(bold: true)),
        PosColumn(text: item.name, width: 10, styles: const PosStyles(bold: true)),
      ]);
      if (item.notes != null && item.notes!.isNotEmpty) {
        bytes += generator.text('  * ${item.notes}',
            styles: const PosStyles());
      }
    }

    bytes += generator.hr();
    bytes += generator.feed(3);
    bytes += generator.cut();

    return Uint8List.fromList(bytes);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Network (TCP) Printer — 17.1.4
// ─────────────────────────────────────────────────────────────────────────────

/// Sends ESC/POS bytes to a TCP socket printer (Wi-Fi / Ethernet).
class NetworkPrinter implements PrintService {
  final String host;
  final int port;

  const NetworkPrinter(this.host, this.port);

  @override
  Future<void> printReceipt(ReceiptData receipt) async {
    final bytes = await ReceiptBuilder.buildEscPos(receipt);
    await printRaw(bytes);
  }

  @override
  Future<void> printKitchenTicket(KitchenTicketData ticket) async {
    final bytes = await KitchenTicketBuilder.buildEscPos(ticket);
    await printRaw(bytes);
  }

  @override
  Future<void> printRaw(Uint8List bytes) async {
    final socket =
        await Socket.connect(host, port, timeout: const Duration(seconds: 5));
    try {
      socket.add(bytes);
      await socket.flush();
    } finally {
      await socket.close();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bluetooth Printer — 17.1.2
// ─────────────────────────────────────────────────────────────────────────────

/// Sends ESC/POS bytes to a Bluetooth LE printer via flutter_blue_plus.
///
/// [deviceId] is the Bluetooth device's MAC address (Android) or UUID (iOS).
class BluetoothPrinter implements PrintService {
  final String deviceId;

  BluetoothPrinter(this.deviceId);

  @override
  Future<void> printReceipt(ReceiptData receipt) async {
    final bytes = await ReceiptBuilder.buildEscPos(receipt);
    await printRaw(bytes);
  }

  @override
  Future<void> printKitchenTicket(KitchenTicketData ticket) async {
    final bytes = await KitchenTicketBuilder.buildEscPos(ticket);
    await printRaw(bytes);
  }

  @override
  Future<void> printRaw(Uint8List bytes) async {
    if (deviceId.isEmpty) throw Exception('Bluetooth device not configured');
    final device = BluetoothDevice.fromId(deviceId);
    await device.connect(timeout: const Duration(seconds: 8));
    try {
      final services = await device.discoverServices();
      BluetoothCharacteristic? writeChar;
      outer:
      for (final service in services) {
        for (final char in service.characteristics) {
          if (char.properties.write || char.properties.writeWithoutResponse) {
            writeChar = char;
            break outer;
          }
        }
      }
      if (writeChar == null) {
        throw Exception('No writable BLE characteristic found');
      }
      // Write in 512-byte chunks respecting BLE MTU limit
      const chunkSize = 512;
      for (var i = 0; i < bytes.length; i += chunkSize) {
        final end = (i + chunkSize).clamp(0, bytes.length);
        await writeChar.write(
          bytes.sublist(i, end),
          withoutResponse: writeChar.properties.writeWithoutResponse,
        );
      }
    } finally {
      await device.disconnect();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// USB Serial Printer — 17.1.3
// ─────────────────────────────────────────────────────────────────────────────

/// Sends ESC/POS bytes to a USB-connected printer via usb_serial.
/// Connects to the first available USB serial device.
class UsbPrinterService implements PrintService {
  @override
  Future<void> printReceipt(ReceiptData receipt) async {
    final bytes = await ReceiptBuilder.buildEscPos(receipt);
    await printRaw(bytes);
  }

  @override
  Future<void> printKitchenTicket(KitchenTicketData ticket) async {
    final bytes = await KitchenTicketBuilder.buildEscPos(ticket);
    await printRaw(bytes);
  }

  @override
  Future<void> printRaw(Uint8List bytes) async {
    final devices = await UsbSerial.listDevices();
    if (devices.isEmpty) throw Exception('No USB serial devices found');
    final port = await UsbSerial.createFromDeviceId(devices.first.deviceId);
    if (port == null) throw Exception('Failed to open USB port');
    try {
      await port.open();
      await port.setPortParameters(
        9600,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );
      await port.write(Uint8List.fromList(bytes));
    } finally {
      await port.close();
    }
  }
}
