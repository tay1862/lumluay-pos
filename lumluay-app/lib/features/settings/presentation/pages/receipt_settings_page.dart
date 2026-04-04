import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/settings_repository.dart';

class ReceiptSettingsPage extends ConsumerStatefulWidget {
  const ReceiptSettingsPage({super.key});

  @override
  ConsumerState<ReceiptSettingsPage> createState() =>
      _ReceiptSettingsPageState();
}

class _ReceiptSettingsPageState extends ConsumerState<ReceiptSettingsPage> {
  final _headerCtrl = TextEditingController();
  final _footerCtrl = TextEditingController();
  final _prefixCtrl = TextEditingController();

  bool _printShopName = true;
  bool _printLogo = false;
  bool _printQr = false;
  int _paperWidth = 80; // mm
  bool _didLoad = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void dispose() {
    _headerCtrl.dispose();
    _footerCtrl.dispose();
    _prefixCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(settingsRepositoryProvider);
      final data = await repo.getReceiptSettings();
      if (!mounted) return;
      setState(() {
        _headerCtrl.text = data.header;
        _footerCtrl.text = data.footer;
        _prefixCtrl.text = data.prefix;
        _paperWidth = data.width;
        _printLogo = data.showLogo;
      });
    } catch (_) {
      // Keep local defaults when API is unavailable.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(settingsRepositoryProvider);
      await repo.updateReceiptSettings(
        ReceiptSettings(
          header: _headerCtrl.text.trim(),
          footer: _footerCtrl.text.trim(),
          prefix: _prefixCtrl.text.trim().isEmpty ? 'RC' : _prefixCtrl.text.trim(),
          width: _paperWidth,
          showLogo: _printLogo,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกการตั้งค่าใบเสร็จแล้ว')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      if (!_didLoad) {
        _didLoad = true;
        _load();
      }
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งค่าใบเสร็จ'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(onPressed: _save, child: const Text('บันทึก')),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // ── Header / Footer text ──────────────────────────────────
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ข้อความใบเสร็จ',
                      style: theme.textTheme.titleSmall),
                  SizedBox(height: 12.h),
                  TextFormField(
                    controller: _headerCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'ข้อความส่วนหัว',
                      hintText: 'เช่น ยินดีต้อนรับ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  TextFormField(
                    controller: _footerCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'ข้อความส่วนท้าย',
                      hintText: 'เช่น ขอบคุณที่ใช้บริการ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  TextFormField(
                    controller: _prefixCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Prefix เลขใบเสร็จ',
                      hintText: 'เช่น RC',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // ── Paper width ──────────────────────────────────────────
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ขนาดกระดาษ', style: theme.textTheme.titleSmall),
                  SizedBox(height: 8.h),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 58, label: Text('58 มม.')),
                      ButtonSegment(value: 80, label: Text('80 มม.')),
                    ],
                    selected: {_paperWidth},
                    onSelectionChanged: (v) =>
                        setState(() => _paperWidth = v.first),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // ── Print options ─────────────────────────────────────────
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('พิมพ์ชื่อร้าน'),
                  value: _printShopName,
                  onChanged: (v) => setState(() => _printShopName = v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('พิมพ์โลโก้ร้าน'),
                  subtitle: const Text('ต้องอัปโหลดโลโก้ก่อน'),
                  value: _printLogo,
                  onChanged: (v) => setState(() => _printLogo = v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('พิมพ์ QR Code'),
                  subtitle: const Text('QR ลิงก์ไปยังใบเสร็จออนไลน์'),
                  value: _printQr,
                  onChanged: (v) => setState(() => _printQr = v),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // ── Preview ───────────────────────────────────────────────
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ตัวอย่างส่วนหัว/ท้าย',
                      style: theme.textTheme.titleSmall),
                  SizedBox(height: 12.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(8.r),
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (_printShopName)
                          Text('ชื่อร้านค้า',
                              style: theme.textTheme.titleMedium),
                        if (_headerCtrl.text.isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          Text(_headerCtrl.text,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall),
                        ],
                        SizedBox(height: 8.h),
                        const Divider(),
                        Text('- รายการสินค้า -',
                            style: theme.textTheme.bodySmall),
                        const Divider(),
                        SizedBox(height: 8.h),
                        if (_footerCtrl.text.isNotEmpty)
                          Text(_footerCtrl.text,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall),
                        if (_printQr) ...[
                          SizedBox(height: 8.h),
                          Icon(Icons.qr_code, size: 40.sp),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
