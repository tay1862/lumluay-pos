import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/settings_repository.dart';

extension _PrinterTypeLabel on String {
  String get label {
    switch (this) {
      case 'bluetooth':
        return 'Bluetooth';
      case 'usb':
        return 'USB';
      case 'wifi':
        return 'Wi-Fi';
      default:
        return this;
    }
  }

  IconData get icon {
    switch (this) {
      case 'bluetooth':
        return Icons.bluetooth;
      case 'usb':
        return Icons.usb;
      case 'wifi':
        return Icons.wifi;
      default:
        return Icons.print;
    }
  }
}
class PrinterSettingsPage extends ConsumerStatefulWidget {
  const PrinterSettingsPage({super.key});

  @override
  ConsumerState<PrinterSettingsPage> createState() => _PrinterSettingsPageState();
}

class _PrinterSettingsPageState extends ConsumerState<PrinterSettingsPage> {
  bool _loading = true;
  bool _didLoad = false;
  List<PrinterConfig> _printers = [];

  Future<void> _load() async {
    try {
      final list = await ref.read(settingsRepositoryProvider).getPrinters();
      if (!mounted) return;
      setState(() => _printers = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('โหลดเครื่องพิมพ์ไม่สำเร็จ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deletePrinter(String id) async {
    await ref.read(settingsRepositoryProvider).deletePrinter(id);
    await _load();
  }

  Future<void> _setDefaultPrinter(PrinterConfig printer) async {
    await ref.read(settingsRepositoryProvider).updatePrinter(
          PrinterConfig(
            id: printer.id,
            name: printer.name,
            type: printer.type,
            ipAddress: printer.ipAddress,
            port: printer.port,
            isDefault: true,
          ),
        );
    await _load();
  }

  Future<void> _savePrinter(PrinterConfig printer, bool isCreate) async {
    final repo = ref.read(settingsRepositoryProvider);
    if (isCreate) {
      await repo.createPrinter(printer);
    } else {
      await repo.updatePrinter(printer);
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      if (!_didLoad) {
        _didLoad = true;
        _load();
      }
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งค่าเครื่องพิมพ์'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'เพิ่มเครื่องพิมพ์',
            onPressed: () => _showPrinterDialog(context, null),
          ),
        ],
      ),
      body: _printers.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.print_disabled_outlined,
                      size: 64.sp,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                  SizedBox(height: 12.h),
                  Text('ยังไม่มีเครื่องพิมพ์',
                      style: theme.textTheme.titleMedium),
                  SizedBox(height: 4.h),
                  Text('แตะ + เพื่อเพิ่มเครื่องพิมพ์',
                      style: theme.textTheme.bodySmall),
                ],
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.all(16.w),
              itemCount: _printers.length,
              separatorBuilder: (_, __) => SizedBox(height: 8.h),
              itemBuilder: (context, i) =>
                  _PrinterCard(
                    printer: _printers[i],
                    onSetDefault: () => _setDefaultPrinter(_printers[i]),
                    onEdit: () => _showPrinterDialog(context, _printers[i]),
                    onDelete: () => _confirmDelete(context, _printers[i]),
                  ),
            ),
    );
  }

  void _showPrinterDialog(BuildContext context, PrinterConfig? existing) {
    showDialog<void>(
      context: context,
      builder: (_) => _PrinterDialog(
        existing: existing,
        onSave: (p) => _savePrinter(p, existing == null),
      ),
    );
  }

  void _confirmDelete(BuildContext context, PrinterConfig printer) {
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ลบเครื่องพิมพ์'),
        content: Text('ต้องการลบ "${printer.name}" ใช่ไหม?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('ลบ'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true) return;
      await _deletePrinter(printer.id);
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Printer card
// ─────────────────────────────────────────────────────────────────────────────

class _PrinterCard extends StatelessWidget {
  const _PrinterCard({
    required this.printer,
    required this.onSetDefault,
    required this.onEdit,
    required this.onDelete,
  });

  final PrinterConfig printer;
  final VoidCallback onSetDefault;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        leading: Icon(printer.type.icon,
            color: theme.colorScheme.primary),
        title: Row(
          children: [
            Text(printer.name),
            if (printer.isDefault) ...[
              SizedBox(width: 8.w),
              Chip(
                label: const Text('ค่าเริ่มต้น'),
                labelStyle: TextStyle(fontSize: 10.sp),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ],
        ),
        subtitle: Text(
          printer.type.label +
              (printer.type == 'wifi'
                  ? ' • ${printer.ipAddress}:${printer.port}'
                  : ''),
        ),
        trailing: PopupMenuButton<String>(
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'test', child: Text('ทดสอบพิมพ์')),
            const PopupMenuItem(value: 'default', child: Text('ตั้งเป็นค่าเริ่มต้น')),
            const PopupMenuItem(value: 'edit', child: Text('แก้ไข')),
            PopupMenuItem(
              value: 'delete',
              child: Text('ลบ',
                  style:
                      TextStyle(color: theme.colorScheme.error)),
            ),
          ],
          onSelected: (action) {
            switch (action) {
              case 'test':
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('กำลังทดสอบพิมพ์: ${printer.name}')),
                );
              case 'default':
                onSetDefault();
              case 'edit':
                onEdit();
              case 'delete':
                onDelete();
            }
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Printer dialog
// ─────────────────────────────────────────────────────────────────────────────

class _PrinterDialog extends StatefulWidget {
  const _PrinterDialog({this.existing, required this.onSave});

  final PrinterConfig? existing;
  final Future<void> Function(PrinterConfig) onSave;

  @override
  State<_PrinterDialog> createState() => _PrinterDialogState();
}

class _PrinterDialogState extends State<_PrinterDialog> {
  final _nameCtrl = TextEditingController();
  final _ipCtrl = TextEditingController();
  final _portCtrl = TextEditingController(text: '9100');

  String _type = 'bluetooth';

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final p = widget.existing!;
      _nameCtrl.text = p.name;
      _type = p.type;
      _ipCtrl.text = p.ipAddress;
      _portCtrl.text = p.port.toString();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ipCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null
          ? 'เพิ่มเครื่องพิมพ์'
          : 'แก้ไขเครื่องพิมพ์'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'ชื่อเครื่องพิมพ์',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12.h),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'ประเภทการเชื่อมต่อ',
                border: OutlineInputBorder(),
              ),
              items: const ['bluetooth', 'usb', 'wifi']
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Row(
                          children: [
                            Icon(t.icon, size: 16.sp),
                            SizedBox(width: 8.w),
                            Text(t.label),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _type = v);
              },
            ),
            if (_type == 'wifi') ...[
              SizedBox(height: 12.h),
              TextField(
                controller: _ipCtrl,
                decoration: const InputDecoration(
                  labelText: 'IP Address',
                  hintText: '192.168.1.100',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: _portCtrl,
                decoration: const InputDecoration(
                  labelText: 'Port',
                  hintText: '9100',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: () async {
            if (_nameCtrl.text.trim().isEmpty) return;
            final p = PrinterConfig(
              id: widget.existing?.id ?? '',
              name: _nameCtrl.text.trim(),
              type: _type,
              ipAddress: _ipCtrl.text.trim(),
              port: int.tryParse(_portCtrl.text) ?? 9100,
              isDefault: widget.existing?.isDefault ?? false,
            );
            await widget.onSave(p);
            if (!mounted) return;
            Navigator.of(this.context).pop();
          },
          child: const Text('บันทึก'),
        ),
      ],
    );
  }
}
