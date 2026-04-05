import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ConfirmDialog
// ─────────────────────────────────────────────────────────────────────────────
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'ຍືນຍັນ',
    this.cancelLabel = 'ຍົກເລີກ',
    this.isDanger = false,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDanger;

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'ຍືນຍັນ',
    String cancelLabel = 'ຍົກເລີກ',
    bool isDanger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDanger: isDanger,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700)),
      content: Text(message, style: TextStyle(fontSize: 14.sp)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: isDanger ? Colors.red.shade600 : null,
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NoteDialog — free-text note input
// ─────────────────────────────────────────────────────────────────────────────
class NoteDialog extends StatefulWidget {
  const NoteDialog({super.key, this.initialNote, this.title = 'ເພີ່ມໝາຍເຫດ'});
  final String? initialNote;
  final String title;

  static Future<String?> show(BuildContext context,
      {String? initialNote, String title = 'ເພີ່ມໝາຍເຫດ'}) {
    return showDialog<String>(
      context: context,
      builder: (_) => NoteDialog(initialNote: initialNote, title: title),
    );
  }

  @override
  State<NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<NoteDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        maxLines: 3,
        maxLength: 200,
        decoration: InputDecoration(
          hintText: 'ລະບຸໝາຍເຫດ...',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ຍົກເລີກ'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _ctrl.text.trim()),
          child: const Text('ບັນທຶກ'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VoidReasonDialog — Void order / item with reason text
// ─────────────────────────────────────────────────────────────────────────────
class VoidReasonDialog extends StatefulWidget {
  const VoidReasonDialog({super.key, this.title = 'ຍົກເລີກລາຍການ'});
  final String title;

  static Future<String?> show(BuildContext context,
      {String title = 'ຍົກເລີກລາຍການ'}) {
    return showDialog<String>(
      context: context,
      builder: (_) => VoidReasonDialog(title: title),
    );
  }

  @override
  State<VoidReasonDialog> createState() => _VoidReasonDialogState();
}

class _VoidReasonDialogState extends State<VoidReasonDialog> {
  final _ctrl = TextEditingController();
  String? _selected;

  final List<String> _presets = [
    'ລູກຄ້າປ່ຽນໃຈ',
    'ສັ່ງຜິດ',
    'ສິນຄ້າໝົດ',
    'ທົດສອບລະບົບ',
    'ອື່ນໆ',
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title,
          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ເລືອກເຫດຜົນ',
              style: TextStyle(fontSize: 12.sp, color: Colors.black54)),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: _presets
                .map(
                  (p) => ChoiceChip(
                    label: Text(p, style: TextStyle(fontSize: 12.sp)),
                    selected: _selected == p,
                    onSelected: (v) {
                      setState(() {
                        _selected = v ? p : null;
                        if (v && p != 'ອື່ນໆ') _ctrl.text = p;
                        if (v && p == 'ອື່ນໆ') _ctrl.clear();
                      });
                    },
                  ),
                )
                .toList(),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _ctrl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'ໝາຍເຫດເພີ່ມເຕີມ...',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('ຍົກເລີກ')),
        FilledButton(
          onPressed: () {
            final reason = _ctrl.text.trim().isNotEmpty
                ? _ctrl.text.trim()
                : _selected;
            Navigator.pop(context, reason);
          },
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
          child: const Text('ຍືນຍັນ Void'),
        ),
      ],
    );
  }
}
