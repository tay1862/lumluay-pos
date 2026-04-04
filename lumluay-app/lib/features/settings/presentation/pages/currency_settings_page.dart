import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/settings_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

class _CurrencyEntry {
  final String code;
  final String symbol;
  final String name;
  bool enabled;
  TextEditingController rateController;

  _CurrencyEntry({
    required this.code,
    required this.symbol,
    required this.name,
    required this.enabled,
    required double rate,
  }) : rateController = TextEditingController(text: rate.toStringAsFixed(4));

  double get rate => double.tryParse(rateController.text) ?? 1.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class CurrencySettingsPage extends ConsumerStatefulWidget {
  const CurrencySettingsPage({super.key});

  @override
  ConsumerState<CurrencySettingsPage> createState() =>
      _CurrencySettingsPageState();
}

class _CurrencySettingsPageState extends ConsumerState<CurrencySettingsPage> {
  static const _kAvailableCurrencies = [
    ('THB', '฿', 'บาทไทย'),
    ('LAK', '₭', 'กีบลาว'),
    ('USD', r'$', 'ดอลลาร์สหรัฐ'),
    ('EUR', '€', 'ยูโร'),
    ('CNY', '¥', 'หยวนจีน'),
  ];

  late List<_CurrencyEntry> _entries;
  String _baseCurrency = 'THB';
  bool _didLoad = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _entries = _kAvailableCurrencies.map((c) {
      return _CurrencyEntry(
        code: c.$1,
        symbol: c.$2,
        name: c.$3,
        enabled: c.$1 == 'THB',
        rate: c.$1 == 'THB' ? 1.0 : 0.0,
      );
    }).toList();
  }

  @override
  void dispose() {
    for (final e in _entries) {
      e.rateController.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(settingsRepositoryProvider);
      final data = await repo.getCurrencies();
      if (!mounted) return;

      setState(() {
        _baseCurrency = data.defaultCurrency;
        for (final e in _entries) {
          e.enabled = data.enabledCurrencies.contains(e.code);
          if (e.code == _baseCurrency) {
            e.enabled = true;
            e.rateController.text = '1.0000';
          } else {
            final rate = data.exchangeRates[e.code] ?? 0.0;
            e.rateController.text = rate.toStringAsFixed(4);
          }
        }
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
      final enabledCurrencies = _entries
          .where((e) => e.enabled)
          .map((e) => e.code)
          .toList();
      final exchangeRates = {
        for (final e in _entries)
          if (e.enabled && e.code != _baseCurrency) e.code: e.rate,
      };

      await repo.updateCurrencies(
        CurrencySettings(
          defaultCurrency: _baseCurrency,
          enabledCurrencies: enabledCurrencies,
          decimals: const {'THB': 2, 'LAK': 0, 'USD': 2},
          exchangeRates: exchangeRates,
        ),
      );
      await repo.updateExchangeRates(exchangeRates);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกการตั้งค่าสกุลเงินแล้ว')),
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
      // Trigger initial load lazily from build lifecycle.
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
        title: const Text('ตั้งค่าสกุลเงิน'),
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
            TextButton(
              onPressed: _save,
              child: const Text('บันทึก'),
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // ── Base currency selector ──────────────────────────────────
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'สกุลเงินหลัก',
                    style: theme.textTheme.titleSmall,
                  ),
                  SizedBox(height: 8.h),
                  DropdownButtonFormField<String>(
                    initialValue: _baseCurrency,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _entries
                        .map((e) => DropdownMenuItem(
                              value: e.code,
                              child: Text('${e.code} (${e.symbol}) — ${e.name}'),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _baseCurrency = v;
                          // Ensure base currency is always enabled
                          for (final e in _entries) {
                            if (e.code == v) {
                              e.enabled = true;
                              e.rateController.text = '1.0000';
                            }
                          }
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // ── Currency list ────────────────────────────────────────────
          Text(
            'สกุลเงินที่รองรับ',
            style: theme.textTheme.titleSmall,
          ),
          SizedBox(height: 8.h),

          ..._entries.map((e) {
            final isBase = e.code == _baseCurrency;
            return Card(
              margin: EdgeInsets.only(bottom: 8.h),
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: 16.w, vertical: 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16.r,
                          child: Text(
                            e.symbol,
                            style: TextStyle(fontSize: 12.sp),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.code,
                                  style: theme.textTheme.titleSmall),
                              Text(e.name,
                                  style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                        Switch(
                          value: isBase ? true : e.enabled,
                          onChanged: isBase
                              ? null
                              : (v) => setState(() => e.enabled = v),
                        ),
                      ],
                    ),
                    if (e.enabled && !isBase) ...[
                      SizedBox(height: 8.h),
                      TextFormField(
                        controller: e.rateController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: 'อัตราแลกเปลี่ยน (1 $_baseCurrency = ? ${e.code})',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
