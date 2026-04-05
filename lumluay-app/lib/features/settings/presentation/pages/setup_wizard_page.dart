import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lumluay_pos/l10n/generated/app_localizations.dart';
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
  String _defaultCurrency = 'LAK';
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
    final l10n = AppLocalizations.of(context);
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
          SnackBar(content: Text(l10n.setupWizardCompleted)),
        );
        context.go('/dashboard');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.errorOccurred}: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submitStep1StoreInfo() async {
    if (_storeNameCtrl.text.trim().isEmpty) {
      throw Exception(AppLocalizations.of(context).setupWizardStoreNameRequired);
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
        enabledCurrencies: {_defaultCurrency, 'LAK'}.toList(),
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
        final l10n = AppLocalizations.of(context);
        throw Exception(
          result.reason == null
              ? l10n.setupWizardSeedSampleDataFailed
              : '${l10n.setupWizardSeedSampleDataFailed}: ${result.reason}',
        );
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
      throw Exception(
        AppLocalizations.of(context).setupWizardStaffInfoIncomplete,
      );
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
    final l10n = AppLocalizations.of(context);

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final stepTitle = [
      l10n.setupWizardStepStoreInfo,
      l10n.setupWizardStepCurrencyTax,
      l10n.setupWizardStepPrinters,
      l10n.setupWizardStepProductImport,
      l10n.setupWizardStepCreateStaff,
    ][_step];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.setupWizardStepProgress(_step + 1, 5),
        ),
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
                      child: Text(l10n.back),
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
                        : Text(_step == 4 ? l10n.finish : l10n.next),
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
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            TextField(
              controller: storeNameCtrl,
              decoration: InputDecoration(labelText: l10n.setupWizardStoreName),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: ownerNameCtrl,
              decoration: InputDecoration(labelText: l10n.setupWizardOwnerName),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: phoneCtrl,
              decoration: InputDecoration(labelText: l10n.setupWizardPhone),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: addressCtrl,
              decoration: InputDecoration(labelText: l10n.setupWizardAddress),
              maxLines: 2,
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: taxIdCtrl,
              decoration: InputDecoration(labelText: l10n.setupWizardTaxId),
            ),
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
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: defaultCurrency,
              items: [
                DropdownMenuItem(
                  value: 'THB',
                  child: Text(l10n.setupWizardCurrencyThb),
                ),
                DropdownMenuItem(
                  value: 'LAK',
                  child: Text(l10n.setupWizardCurrencyLak),
                ),
                DropdownMenuItem(
                  value: 'USD',
                  child: Text(l10n.setupWizardCurrencyUsd),
                ),
              ],
              onChanged: (v) {
                if (v != null) onCurrencyChanged(v);
              },
              decoration: InputDecoration(labelText: l10n.setupWizardDefaultCurrency),
            ),
            SizedBox(height: 16.h),
            Text('${l10n.setupWizardVatRate} (%) : ${vatRate.toStringAsFixed(1)}'),
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
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.setupWizardPrinterHint,
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
              label: Text(l10n.setupWizardAddPrinter),
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
        builder: (context, setDialogState) {
          final l10n = AppLocalizations.of(context);

          return AlertDialog(
          title: Text(l10n.setupWizardAddPrinter),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: l10n.setupWizardPrinterName),
              ),
              SizedBox(height: 8.h),
              DropdownButtonFormField<String>(
                initialValue: type,
                items: const [
                  DropdownMenuItem(value: 'bluetooth', child: Text('Bluetooth')),
                  DropdownMenuItem(value: 'usb', child: Text('USB')),
                  DropdownMenuItem(value: 'wifi', child: Text('Wi-Fi')),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => type = v);
                },
                decoration: InputDecoration(labelText: l10n.setupWizardPrinterType),
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
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
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
              child: Text(l10n.add),
            ),
          ],
        );
        },
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
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: RadioGroup<String>(
          groupValue: selectedMode,
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          child: Column(
            children: [
              RadioListTile<String>(
                value: 'sample',
                title: Text(l10n.setupWizardUseSampleData),
                subtitle: Text(l10n.setupWizardUseSampleDataHint),
              ),
              RadioListTile<String>(
                value: 'csv',
                title: Text(l10n.setupWizardImportCsv),
                subtitle: Text(l10n.setupWizardImportCsvHint),
              ),
              RadioListTile<String>(
                value: 'later',
                title: Text(l10n.setupWizardAddLater),
              ),
            ],
          ),
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
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            TextField(
              controller: usernameCtrl,
              decoration: InputDecoration(labelText: l10n.setupWizardUsername),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: displayNameCtrl,
              decoration: InputDecoration(labelText: l10n.setupWizardDisplayName),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: passwordCtrl,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.setupWizardPassword),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: pinCtrl,
              decoration: InputDecoration(
                labelText: l10n.setupWizardPinOptional,
                hintText: l10n.setupWizardPinHint,
              ),
            ),
            SizedBox(height: 12.h),
            DropdownButtonFormField<String>(
              initialValue: role,
              decoration: InputDecoration(labelText: l10n.setupWizardRole),
              items: [
                DropdownMenuItem(
                  value: 'cashier',
                  child: Text(l10n.setupWizardRoleCashier),
                ),
                DropdownMenuItem(
                  value: 'waiter',
                  child: Text(l10n.setupWizardRoleWaiter),
                ),
                DropdownMenuItem(
                  value: 'kitchen',
                  child: Text(l10n.setupWizardRoleKitchen),
                ),
                DropdownMenuItem(
                  value: 'manager',
                  child: Text(l10n.setupWizardRoleManager),
                ),
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
