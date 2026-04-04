import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../data/settings_repository.dart';
import '../../data/users_repository.dart';

class SetupWizardPage extends ConsumerStatefulWidget {
  const SetupWizardPage({super.key});

  @override
  ConsumerState<SetupWizardPage> createState() => _SetupWizardPageState();
}

class _SetupWizardPageState extends ConsumerState<SetupWizardPage> {
  int _step = 0;
  bool _loading = true;
  bool _saving = false;

  // Step 1
  final _storeNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _taxIdCtrl = TextEditingController();

  // Step 2
  String _defaultCurrency = 'THB';
  double _vatRate = 7.0;

  // Step 3
  final List<PrinterConfig> _draftPrinters = [];

  // Step 4
  String _productImportMode = 'sample'; // sample | csv | later

  // Step 5
  final _usernameCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  String _role = 'cashier';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _taxIdCtrl.dispose();
    _usernameCtrl.dispose();
    _displayNameCtrl.dispose();
    _passwordCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final repo = ref.read(settingsRepositoryProvider);
      final tenantProfile = await repo.getTenantProfile();
      final currencies = await repo.getCurrencies();
      final printers = await repo.getPrinters();

      if (!mounted) return;
      setState(() {
        _storeNameCtrl.text = tenantProfile.tenant.name;
        _ownerNameCtrl.text = tenantProfile.tenant.ownerName;
        _phoneCtrl.text = tenantProfile.tenant.phone ?? '';
        _addressCtrl.text = tenantProfile.tenant.address ?? '';
        _taxIdCtrl.text = tenantProfile.tenant.taxId ?? '';
        _defaultCurrency = currencies.defaultCurrency;
        _draftPrinters
          ..clear()
          ..addAll(printers);
      });
    } catch (_) {
      // Keep local defaults when API is temporarily unavailable.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _next() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      switch (_step) {
        case 0:
          await _submitStep1StoreInfo();
        case 1:
          await _submitStep2CurrencyTax();
        case 2:
          await _submitStep3Printers();
        case 3:
          await _submitStep4ProductImport();
        case 4:
          await _submitStep5CreateStaff();
      }

      if (!mounted) return;
      if (_step < 4) {
        setState(() => _step += 1);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Setup Wizard เสร็จสมบูรณ์แล้ว')),
        );
        context.go('/dashboard');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submitStep1StoreInfo() async {
    if (_storeNameCtrl.text.trim().isEmpty) {
      throw Exception('กรุณากรอกชื่อร้าน');
    }

    final repo = ref.read(settingsRepositoryProvider);
    await repo.updateTenantInfo(
      TenantInfo(
        id: '',
        name: _storeNameCtrl.text.trim(),
        ownerName: _ownerNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        address:
            _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        taxId: _taxIdCtrl.text.trim().isEmpty ? null : _taxIdCtrl.text.trim(),
      ),
    );
  }

  Future<void> _submitStep2CurrencyTax() async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.updateCurrencies(
      CurrencySettings(
        defaultCurrency: _defaultCurrency,
        enabledCurrencies: [_defaultCurrency, 'THB'],
        decimals: const {'THB': 2, 'LAK': 0, 'USD': 2},
        exchangeRates: const {},
      ),
    );

    if (_vatRate >= 0 && _vatRate <= 100) {
      await repo.createTaxRate(name: 'VAT', rate: _vatRate, isDefault: true);
    }
  }

  Future<void> _submitStep3Printers() async {
    final repo = ref.read(settingsRepositoryProvider);
    final existing = await repo.getPrinters();
    final existingByName = {for (final p in existing) p.name: p};

    for (final p in _draftPrinters) {
      if (existingByName.containsKey(p.name)) continue;
      await repo.createPrinter(p);
    }
  }

  Future<void> _submitStep4ProductImport() async {
    if (_productImportMode == 'sample') {
      final result =
          await ref.read(settingsRepositoryProvider).seedSampleData();
      if (result.skipped) {
        throw Exception(result.reason ?? 'ไม่สามารถ seed sample data ได้');
      }
    }

    if (_productImportMode == 'csv') {
      // Placeholder for CSV upload integration; wizard can continue.
      return;
    }
  }

  Future<void> _submitStep5CreateStaff() async {
    if (_usernameCtrl.text.trim().isEmpty ||
        _displayNameCtrl.text.trim().isEmpty ||
        _passwordCtrl.text.trim().length < 8) {
      throw Exception('กรอกข้อมูลพนักงานให้ครบ (รหัสผ่านอย่างน้อย 8 ตัว)');
    }

    await ref.read(usersRepositoryProvider).createUser({
      'username': _usernameCtrl.text.trim(),
      'displayName': _displayNameCtrl.text.trim(),
      'password': _passwordCtrl.text.trim(),
      'role': _role,
      if (_pinCtrl.text.trim().isNotEmpty) 'pinCode': _pinCtrl.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final stepTitle = [
      'ข้อมูลร้าน',
      'สกุลเงินและภาษี',
      'เครื่องพิมพ์',
      'นำเข้าสินค้า',
      'สร้างพนักงาน',
    ][_step];

    return Scaffold(
      appBar: AppBar(
        title: Text('Setup Wizard • ขั้นตอน ${_step + 1}/5'),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: (_step + 1) / 5),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                Text(stepTitle, style: Theme.of(context).textTheme.headlineSmall),
                SizedBox(height: 12.h),
                _buildStepBody(),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
              child: Row(
                children: [
                  if (_step > 0)
                    OutlinedButton(
                      onPressed: _saving ? null : () => setState(() => _step -= 1),
                      child: const Text('ย้อนกลับ'),
                    )
                  else
                    const SizedBox.shrink(),
                  const Spacer(),
                  FilledButton(
                    onPressed: _saving ? null : _next,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_step == 4 ? 'เสร็จสิ้น' : 'ถัดไป'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepBody() {
    switch (_step) {
      case 0:
        return _StoreInfoStep(
          storeNameCtrl: _storeNameCtrl,
          ownerNameCtrl: _ownerNameCtrl,
          phoneCtrl: _phoneCtrl,
          addressCtrl: _addressCtrl,
          taxIdCtrl: _taxIdCtrl,
        );
      case 1:
        return _CurrencyTaxStep(
          defaultCurrency: _defaultCurrency,
          vatRate: _vatRate,
          onCurrencyChanged: (v) => setState(() => _defaultCurrency = v),
          onVatRateChanged: (v) => setState(() => _vatRate = v),
        );
      case 2:
        return _PrinterStep(
          printers: _draftPrinters,
          onChanged: () => setState(() {}),
        );
      case 3:
        return _ProductImportStep(
          selectedMode: _productImportMode,
          onChanged: (v) => setState(() => _productImportMode = v),
        );
      case 4:
        return _CreateStaffStep(
          usernameCtrl: _usernameCtrl,
          displayNameCtrl: _displayNameCtrl,
          passwordCtrl: _passwordCtrl,
          pinCtrl: _pinCtrl,
          role: _role,
          onRoleChanged: (v) => setState(() => _role = v),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _StoreInfoStep extends StatelessWidget {
  const _StoreInfoStep({
    required this.storeNameCtrl,
    required this.ownerNameCtrl,
    required this.phoneCtrl,
    required this.addressCtrl,
    required this.taxIdCtrl,
  });

  final TextEditingController storeNameCtrl;
  final TextEditingController ownerNameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController addressCtrl;
  final TextEditingController taxIdCtrl;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            TextField(controller: storeNameCtrl, decoration: const InputDecoration(labelText: 'ชื่อร้าน')),
            SizedBox(height: 12.h),
            TextField(controller: ownerNameCtrl, decoration: const InputDecoration(labelText: 'ชื่อเจ้าของ/ผู้ดูแล')),
            SizedBox(height: 12.h),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'เบอร์โทร')),
            SizedBox(height: 12.h),
            TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'ที่อยู่'), maxLines: 2),
            SizedBox(height: 12.h),
            TextField(controller: taxIdCtrl, decoration: const InputDecoration(labelText: 'เลขผู้เสียภาษี')),
          ],
        ),
      ),
    );
  }
}

class _CurrencyTaxStep extends StatelessWidget {
  const _CurrencyTaxStep({
    required this.defaultCurrency,
    required this.vatRate,
    required this.onCurrencyChanged,
    required this.onVatRateChanged,
  });

  final String defaultCurrency;
  final double vatRate;
  final ValueChanged<String> onCurrencyChanged;
  final ValueChanged<double> onVatRateChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: defaultCurrency,
              items: const [
                DropdownMenuItem(value: 'THB', child: Text('THB - บาทไทย')),
                DropdownMenuItem(value: 'LAK', child: Text('LAK - กีบลาว')),
                DropdownMenuItem(value: 'USD', child: Text('USD - US Dollar')),
              ],
              onChanged: (v) {
                if (v != null) onCurrencyChanged(v);
              },
              decoration: const InputDecoration(labelText: 'สกุลเงินเริ่มต้น'),
            ),
            SizedBox(height: 16.h),
            Text('VAT (%) : ${vatRate.toStringAsFixed(1)}'),
            Slider(
              min: 0,
              max: 20,
              divisions: 40,
              value: vatRate,
              onChanged: onVatRateChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _PrinterStep extends StatelessWidget {
  const _PrinterStep({required this.printers, required this.onChanged});

  final List<PrinterConfig> printers;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('เพิ่มเครื่องพิมพ์อย่างน้อย 1 เครื่อง (ข้ามได้)',
                style: Theme.of(context).textTheme.titleSmall),
            SizedBox(height: 12.h),
            ...printers.map(
              (p) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.print_outlined),
                title: Text('${p.name} (${p.type})'),
                subtitle: p.type == 'wifi' ? Text('${p.ipAddress}:${p.port}') : null,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    printers.removeWhere((x) => x.name == p.name);
                    onChanged();
                  },
                ),
              ),
            ),
            SizedBox(height: 8.h),
            OutlinedButton.icon(
              onPressed: () => _showAddPrinterDialog(context, printers, onChanged),
              icon: const Icon(Icons.add),
              label: const Text('เพิ่มเครื่องพิมพ์'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPrinterDialog(
    BuildContext context,
    List<PrinterConfig> printers,
    VoidCallback onChanged,
  ) {
    final nameCtrl = TextEditingController();
    final ipCtrl = TextEditingController();
    final portCtrl = TextEditingController(text: '9100');
    String type = 'bluetooth';

    showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('เพิ่มเครื่องพิมพ์'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ชื่อเครื่องพิมพ์')),
              SizedBox(height: 8.h),
              DropdownButtonFormField<String>(
                value: type,
                items: const [
                  DropdownMenuItem(value: 'bluetooth', child: Text('Bluetooth')),
                  DropdownMenuItem(value: 'usb', child: Text('USB')),
                  DropdownMenuItem(value: 'wifi', child: Text('Wi-Fi')),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => type = v);
                },
                decoration: const InputDecoration(labelText: 'ประเภท'),
              ),
              if (type == 'wifi') ...[
                SizedBox(height: 8.h),
                TextField(controller: ipCtrl, decoration: const InputDecoration(labelText: 'IP Address')),
                SizedBox(height: 8.h),
                TextField(controller: portCtrl, decoration: const InputDecoration(labelText: 'Port')),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                printers.add(
                  PrinterConfig(
                    id: '',
                    name: name,
                    type: type,
                    ipAddress: ipCtrl.text.trim(),
                    port: int.tryParse(portCtrl.text) ?? 9100,
                    isDefault: printers.isEmpty,
                  ),
                );
                onChanged();
                Navigator.pop(context);
              },
              child: const Text('เพิ่ม'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductImportStep extends StatelessWidget {
  const _ProductImportStep({
    required this.selectedMode,
    required this.onChanged,
  });

  final String selectedMode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            RadioListTile<String>(
              value: 'sample',
              groupValue: selectedMode,
              title: const Text('ใช้ข้อมูลตัวอย่าง (แนะนำ)'),
              subtitle: const Text('5 หมวดหมู่, 20 สินค้า ตัวอย่างสำหรับร้านอาหาร'),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
            RadioListTile<String>(
              value: 'csv',
              groupValue: selectedMode,
              title: const Text('นำเข้า CSV'),
              subtitle: const Text('จะรองรับขั้นถัดไป'),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
            RadioListTile<String>(
              value: 'later',
              groupValue: selectedMode,
              title: const Text('เพิ่มทีหลัง'),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateStaffStep extends StatelessWidget {
  const _CreateStaffStep({
    required this.usernameCtrl,
    required this.displayNameCtrl,
    required this.passwordCtrl,
    required this.pinCtrl,
    required this.role,
    required this.onRoleChanged,
  });

  final TextEditingController usernameCtrl;
  final TextEditingController displayNameCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController pinCtrl;
  final String role;
  final ValueChanged<String> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            TextField(controller: usernameCtrl, decoration: const InputDecoration(labelText: 'Username')),
            SizedBox(height: 12.h),
            TextField(controller: displayNameCtrl, decoration: const InputDecoration(labelText: 'ชื่อที่แสดง')),
            SizedBox(height: 12.h),
            TextField(controller: passwordCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'รหัสผ่าน (8+ ตัวอักษร)')),
            SizedBox(height: 12.h),
            TextField(controller: pinCtrl, decoration: const InputDecoration(labelText: 'PIN (ตัวเลือก)', hintText: '4-6 หลัก')),
            SizedBox(height: 12.h),
            DropdownButtonFormField<String>(
              value: role,
              decoration: const InputDecoration(labelText: 'บทบาท'),
              items: const [
                DropdownMenuItem(value: 'cashier', child: Text('Cashier')),
                DropdownMenuItem(value: 'waiter', child: Text('Waiter')),
                DropdownMenuItem(value: 'kitchen', child: Text('Kitchen')),
                DropdownMenuItem(value: 'manager', child: Text('Manager')),
              ],
              onChanged: (v) {
                if (v != null) onRoleChanged(v);
              },
            ),
          ],
        ),
      ),
    );
  }
}
