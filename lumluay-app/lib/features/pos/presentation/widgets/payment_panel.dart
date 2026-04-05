import 'dart:async' show unawaited;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/sound_player_util.dart';
import '../../../../core/services/print_service.dart';
import '../../../../core/services/cash_drawer_service.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../settings/data/settings_repository.dart';
import '../../data/pos_repository.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_bloc.dart';

// Selected payment method
final _payMethodProvider = StateProvider<String>((ref) => 'cash');

class PaymentPanel extends ConsumerStatefulWidget {
  const PaymentPanel({super.key, required this.cart, required this.onClose});
  final CartState cart;
  final VoidCallback onClose;

  @override
  ConsumerState<PaymentPanel> createState() => _PaymentPanelState();
}

class _PaymentPanelState extends ConsumerState<PaymentPanel> {
  final _amountCtrl = TextEditingController();
  final _receivedCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  bool _processing = false;
  String? _error;
  Map<String, dynamic>? _result;
  String? _orderId;
  String _currency = 'LAK';
  double _remaining = 0;
  List<String> _enabledCurrencies = const ['LAK'];
  Map<String, double> _exchangeRates = const {'LAK': 1};
  final List<_PaymentEntry> _payments = [];

  @override
  void initState() {
    super.initState();
    _remaining = widget.cart.total;
    _amountCtrl.text = widget.cart.total.toStringAsFixed(2);
    _loadCurrencySettings();
  }

  Future<void> _loadCurrencySettings() async {
    try {
      final settings = await ref.read(settingsRepositoryProvider).getCurrencies();
      if (!mounted) return;
      setState(() {
        _enabledCurrencies = settings.enabledCurrencies.isEmpty
            ? const ['LAK']
            : settings.enabledCurrencies.map((c) => c.toUpperCase()).toList();
        _exchangeRates = {
          'LAK': 1,
          ...settings.exchangeRates.map((k, v) => MapEntry(k.toUpperCase(), v)),
        };
        if (!_enabledCurrencies.contains(_currency)) {
          _currency = _enabledCurrencies.first;
        }
      });
    } catch (_) {
      // Keep safe defaults when settings endpoint is unavailable.
    }
  }

  double get amount {
    final v = double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    return v ?? 0;
  }

  double get received {
    final v = double.tryParse(_receivedCtrl.text.replaceAll(',', ''));
    return v ?? 0;
  }

  double get activeRate {
    if (_currency == 'LAK') return 1;
    return _exchangeRates[_currency] ?? 1;
  }

  double get baseAmount {
    if (_currency == 'LAK') return amount;
    final rate = activeRate;
    if (rate <= 0) return amount;
    return amount / rate;
  }

  double get changeInCurrency =>
      (received - amount).clamp(0, double.maxFinite);

  Future<String> _ensureOrder() async {
    if (_orderId != null && _orderId!.isNotEmpty) return _orderId!;
    final orderBloc = ref.read(orderBlocProvider.notifier);
    final orderId = await orderBloc.createAndConfirm(widget.cart);
    _orderId = orderId;
    return orderId;
  }

  String _mapBackendMethod(String method) {
    return switch (method) {
      'cash' => 'cash',
      'qr' => 'qr_promptpay',
      'transfer' => 'bank_transfer',
      'wallet' => 'wallet_truemoney',
      _ => 'cash',
    };
  }

  Future<void> _addPayment() async {
    setState(() {
      _processing = true;
      _error = null;
    });

    try {
      if (amount <= 0) {
        throw Exception('ກະລຸນາໃສ່ຈຳນວນເງິນທີ່ຖືກຕ້ອງ');
      }

      final method = ref.read(_payMethodProvider);
      if (method == 'cash' && received < amount) {
        throw Exception('ຈຳນວນລັບເງິນຕ້ອງບໍ່ນ້ອຍກວ່າຍອດຊຳລະ');
      }

      final orderId = await _ensureOrder();
      final repo = ref.read(posRepositoryProvider);

      final payment = await repo.createPayment(
        orderId: orderId,
        amount: amount,
        method: _mapBackendMethod(method),
        currency: _currency,
        exchangeRate: _currency == 'LAK' ? null : activeRate,
        received: method == 'cash' ? received : null,
        reference: _referenceCtrl.text,
      );

      final split = Map<String, dynamic>.from(
        (payment['split'] ?? const {}) as Map,
      );
      final change = Map<String, dynamic>.from(
        (payment['change'] ?? const {}) as Map,
      );

      final remaining =
          (double.tryParse('${split['remaining'] ?? _remaining}') ?? _remaining)
              .clamp(0.0, double.maxFinite);

      _payments.add(
        _PaymentEntry(
          method: method,
          backendMethod: _mapBackendMethod(method),
          currency: _currency,
          sourceAmount: amount,
          baseAmount: double.tryParse('${payment['payment']?['amount'] ?? baseAmount}') ?? baseAmount,
          tendered: method == 'cash' ? received : null,
          changeBase: double.tryParse('${change['base'] ?? 0}') ?? 0,
          changeCurrency: double.tryParse('${change['amount'] ?? 0}') ?? 0,
        ),
      );

      setState(() {
        _remaining = remaining;
        _processing = false;
        _receivedCtrl.clear();
        _referenceCtrl.clear();
        if (_remaining > 0) {
          final nextAmount = _currency == 'LAK' ? _remaining : (_remaining * activeRate);
          _amountCtrl.text = nextAmount.toStringAsFixed(2);
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _processing = false;
      });
    }
  }

  Future<void> _completePayment() async {
    setState(() {
      _processing = true;
      _error = null;
    });

    try {
      if (_remaining > 0.0001) {
        throw Exception('ຍອດຊຳລະຍັງບໍ່ຄົບ');
      }

      final orderId = await _ensureOrder();
      final repo = ref.read(posRepositoryProvider);
      final completed = await repo.completeOrder(orderId);

      final paidTotal = _payments.fold<double>(
        0,
        (sum, p) => sum + p.baseAmount,
      );
      final changeTotal = _payments.fold<double>(
        0,
        (sum, p) => sum + p.changeBase,
      );

      setState(() {
        _result = {
          'orderId': orderId,
          'payments': _payments,
          'completed': completed,
          'total': widget.cart.total,
          'paid': paidTotal,
          'change': changeTotal,
        };
        _processing = false;
      });

      await ref.read(soundPlayerProvider).play(AppSound.notification);
      HapticFeedback.heavyImpact(); // 18.5.6: payment success vibration
      ref.read(cartProvider.notifier).clear();

      // ── 17.1.8 Auto-print receipt ────────────────────────────────────────
      _autoPrintReceipt(cart: widget.cart, result: _result!);

      // ── 17.1.9 Auto-print kitchen ticket ─────────────────────────────────
      _autoPrintKitchenTicket(cart: widget.cart, orderId: orderId);

      // ── 17.3.2 Auto-open cash drawer on cash payment ─────────────────────
      if (ref.read(_payMethodProvider) == 'cash') {
        unawaited(
          ref.read(cashDrawerServiceProvider).openDrawer().catchError((_) {}),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _processing = false;
      });
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _receivedCtrl.dispose();
    _referenceCtrl.dispose();
    super.dispose();
  }

  // ── Auto-print helpers (17.1.8 receipt, 17.1.9 kitchen) ─────────────────

  void _autoPrintReceipt({
    required CartState cart,
    required Map<String, dynamic> result,
  }) {
    final authState = ref.read(authProvider);
    final cashierName =
        authState is AuthAuthenticated ? authState.user.displayName : null;
    final receiptItems = cart.items
        .map((i) => ReceiptItem(
              name: i.productName,
              qty: i.quantity,
              unitPrice: i.unitPrice,
              lineTotal: i.lineTotal,
            ))
        .toList();
    final paidTotal = (result['paid'] as double?) ?? cart.total;
    final changeTotal = (result['change'] as double?) ?? 0.0;
    final method = ref.read(_payMethodProvider);

    final receipt = ReceiptData(
      tenantName: 'LUMLUAY POS',
      receiptNumber: 'RC-${result['orderId'] ?? _orderId ?? 'N/A'}',
      printedAt: DateTime.now(),
      cashierName: cashierName,
      tableName: cart.tableName,
      items: receiptItems,
      subtotal: cart.subtotal,
      discountAmount: cart.discountAmount,
      total: cart.total,
      paymentMethod: method,
      amountPaid: paidTotal,
      changeAmount: changeTotal > 0 ? changeTotal : null,
    );

    unawaited(
      ref.read(printServiceProvider).printReceipt(receipt).catchError((_) {}),
    );
  }

  void _autoPrintKitchenTicket({
    required CartState cart,
    required String orderId,
  }) {
    final kitchenItems = cart.items
        .map((i) => KitchenTicketItem(
              name: i.productName,
              qty: i.quantity,
              notes: i.note,
            ))
        .toList();
    final ticket = KitchenTicketData(
      orderNumber: orderId,
      tableName: cart.tableName,
      orderType: cart.orderType,
      createdAt: DateTime.now(),
      items: kitchenItems,
    );
    unawaited(
      ref
          .read(printServiceProvider)
          .printKitchenTicket(ticket)
          .catchError((_) {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat('#,##0.00', 'th_TH');
    final method = ref.watch(_payMethodProvider);

    if (_result != null) {
      return _SuccessView(
        result: _result!,
        cart: widget.cart,
        onDone: widget.onClose,
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            color: Theme.of(context).colorScheme.primary,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: widget.onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                SizedBox(width: 8.w),
                Text('ຊຳລະເງິນ',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Total amount
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      children: [
                        Text('ຍອດລວມບິນ',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13.sp)),
                        SizedBox(height: 4.h),
                        Text(
                          '₭${currencyFmt.format(widget.cart.total)}',
                          style: TextStyle(
                            fontSize: 32.sp,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'ຄົງເຫຼືອ',
                          style: TextStyle(fontSize: 13.sp, color: Colors.orange[800]),
                        ),
                        const Spacer(),
                        Text(
                          '₭${currencyFmt.format(_remaining)}',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.orange[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Payment method tabs
                  Text('ວິທີຊຳລະເງິນ',
                      style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700])),
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 8.w,
                    children: [
                      _PayMethodChip(
                          value: 'cash',
                          label: 'ເງິນສົດ',
                          icon: Icons.payments_outlined,
                          selected: method),
                      _PayMethodChip(
                          value: 'qr',
                          label: 'QR Code',
                          icon: Icons.qr_code,
                          selected: method),
                      _PayMethodChip(
                          value: 'transfer',
                          label: 'ໂອນເງິນ',
                          icon: Icons.account_balance,
                          selected: method),
                      _PayMethodChip(
                          value: 'wallet',
                          label: 'E-Wallet',
                          icon: Icons.account_balance_wallet_outlined,
                          selected: method),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  _MultiCurrencyInput(
                    amountController: _amountCtrl,
                    selectedCurrency: _currency,
                    currencies: _enabledCurrencies,
                    onCurrencyChanged: (value) {
                      setState(() {
                        _currency = value;
                      });
                    },
                    onAmountChanged: (_) => setState(() {}),
                    convertedBaseAmount: baseAmount,
                    rate: activeRate,
                  ),
                  SizedBox(height: 12.h),

                  // Cash received (only for cash)
                  if (method == 'cash') ...[
                    Text('ລັບເງິນມາ',
                        style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700])),
                    SizedBox(height: 8.h),
                    TextField(
                      controller: _receivedCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.]'))
                      ],
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        prefixText: '₭ ',
                        hintText: '0.00',
                      ),
                      style: TextStyle(
                          fontSize: 22.sp, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 8.h),
                    // Quick amounts
                    Wrap(
                      spacing: 8.w,
                      children: [
                        _remaining,
                        50,
                        100,
                        500,
                        1000,
                      ].map((v) {
                        final amount =
                            v is double ? v : (v as int).toDouble();
                        return ActionChip(
                          label: Text('₭${currencyFmt.format(amount)}',
                              style: TextStyle(fontSize: 12.sp)),
                          onPressed: () {
                            _receivedCtrl.text =
                                amount.toStringAsFixed(2);
                            setState(() {});
                          },
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 12.h),
                    if (received >= amount)
                      _ChangeDisplay(
                        received: received,
                        paidAmount: amount,
                        changeAmount: changeInCurrency,
                        currency: _currency,
                      ),
                  ],

                  if (method != 'cash') ...[
                    Text('ເລກອ້າງອີງ (ຖ້າມີ)',
                        style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700])),
                    SizedBox(height: 8.h),
                    TextField(
                      controller: _referenceCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Reference / Transaction ID',
                      ),
                    ),
                  ],

                  SizedBox(height: 12.h),
                  _SplitBillPanel(payments: _payments, remaining: _remaining),

                  if (_error != null) ...[
                    SizedBox(height: 12.h),
                    Text(_error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12.sp)),
                  ],
                ],
              ),
            ),
          ),

          // Pay button
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52.h,
                    child: OutlinedButton.icon(
                      onPressed: _processing || _remaining <= 0 ? null : _addPayment,
                      icon: _processing
                          ? SizedBox(
                              width: 16.w,
                              height: 16.h,
                              child: const CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_circle_outline),
                      label: const Text('ເພີ່ມການຊຳລະ'),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: SizedBox(
                    height: 52.h,
                    child: FilledButton.icon(
                      onPressed: _processing || _remaining > 0 ? null : _completePayment,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('ປິດບິນ'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentEntry {
  const _PaymentEntry({
    required this.method,
    required this.backendMethod,
    required this.currency,
    required this.sourceAmount,
    required this.baseAmount,
    this.tendered,
    this.changeBase = 0,
    this.changeCurrency = 0,
  });

  final String method;
  final String backendMethod;
  final String currency;
  final double sourceAmount;
  final double baseAmount;
  final double? tendered;
  final double changeBase;
  final double changeCurrency;
}

class _MultiCurrencyInput extends StatelessWidget {
  const _MultiCurrencyInput({
    required this.amountController,
    required this.selectedCurrency,
    required this.currencies,
    required this.onCurrencyChanged,
    required this.onAmountChanged,
    required this.convertedBaseAmount,
    required this.rate,
  });

  final TextEditingController amountController;
  final String selectedCurrency;
  final List<String> currencies;
  final ValueChanged<String> onCurrencyChanged;
  final ValueChanged<String> onAmountChanged;
  final double convertedBaseAmount;
  final double rate;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00', 'th_TH');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('ສະກຸນເງິນແລະຍອດຊຳລະ',
            style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700])),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              flex: 4,
              child: DropdownButtonFormField<String>(
                initialValue: selectedCurrency,
                items: currencies
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onCurrencyChanged(v);
                },
                decoration: const InputDecoration(labelText: 'Currency'),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              flex: 6,
              child: TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                onChanged: onAmountChanged,
                decoration: const InputDecoration(
                  labelText: 'ຈຳນວນເງິນ',
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        Text(
          selectedCurrency == 'LAK'
              ? 'ຄິດເປັນຖານ: ₭${fmt.format(convertedBaseAmount)}'
              : 'Rate: $rate | ຄິດເປັນ LAK: ₭${fmt.format(convertedBaseAmount)}',
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class _SplitBillPanel extends StatelessWidget {
  const _SplitBillPanel({required this.payments, required this.remaining});
  final List<_PaymentEntry> payments;
  final double remaining;

  String _methodLabel(String method) {
    return switch (method) {
      'cash' => 'ເງິນສົດ',
      'qr' => 'QR',
      'transfer' => 'ໂອນ',
      'wallet' => 'E-Wallet',
      _ => method,
    };
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00', 'th_TH');
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE3E7EC)),
        color: const Color(0xFFF9FBFD),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('ການຊຳລະເງິນ (Split Bill)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.sp)),
              const Spacer(),
              Text('ຄົງເຫຼືອ ₭${fmt.format(remaining)}',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.sp,
                      color: remaining > 0 ? Colors.orange[800] : Colors.green[700])),
            ],
          ),
          SizedBox(height: 8.h),
          if (payments.isEmpty)
            Text('ຍັງບໍ່ມີລາຍການຊຳລະ', style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]))
          else
            ...payments.map(
              (p) => Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_methodLabel(p.method)} • ${p.currency} ${fmt.format(p.sourceAmount)}',
                        style: TextStyle(fontSize: 12.sp),
                      ),
                    ),
                    Text('THB ${fmt.format(p.baseAmount)}',
                        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChangeDisplay extends StatelessWidget {
  const _ChangeDisplay({
    required this.received,
    required this.paidAmount,
    required this.changeAmount,
    required this.currency,
  });

  final double received;
  final double paidAmount;
  final double changeAmount;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00', 'th_TH');
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Text(
            'ລັບ ${currency.toUpperCase()} ${fmt.format(received)} | ທອນ',
            style: TextStyle(fontSize: 13.sp, color: Colors.green[700]),
          ),
          const Spacer(),
          Text(
            '${currency.toUpperCase()} ${fmt.format(changeAmount)}',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }
}

class _PayMethodChip extends ConsumerWidget {
  const _PayMethodChip({
    required this.value,
    required this.label,
    required this.icon,
    required this.selected,
  });
  final String value;
  final String label;
  final IconData icon;
  final String selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = selected == value;
    return FilterChip(
      avatar: Icon(icon,
          size: 16, color: isSelected ? Colors.white : Colors.black54),
      label: Text(label),
      selected: isSelected,
      onSelected: (_) =>
          ref.read(_payMethodProvider.notifier).state = value,
      selectedColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87, fontSize: 13),
      showCheckmark: false,
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({
    required this.result,
    required this.cart,
    required this.onDone,
  });
  final Map<String, dynamic> result;
  final CartState cart;
  final VoidCallback onDone;

  void _showReceiptPreview(BuildContext context) {
    final currencyFmt = NumberFormat('#,##0.00', 'th_TH');
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ຕົວຢ່າງໃບເສັດ'),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ບິນ: ${result['orderId'] ?? '-'}'),
                const SizedBox(height: 8),
                ...cart.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(child: Text('${item.productName} x${item.quantity}')),
                          Text('₭${currencyFmt.format(item.lineTotal)}'),
                        ],
                      ),
                    )),
                const Divider(),
                Row(
                  children: [
                    const Expanded(child: Text('ລວມສຸດທິ')),
                    Text('₭${currencyFmt.format((result['total'] as num?)?.toDouble() ?? 0)}'),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ປິດ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat('#,##0.00', 'th_TH');
    final total = (result['total'] as num?)?.toDouble() ?? 0;
    final paid = (result['paid'] as num?)?.toDouble() ?? 0;
    final change = (result['change'] as num?)?.toDouble() ?? 0;
    return Container(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle,
                  color: Colors.green, size: 72.sp),
              SizedBox(height: 16.h),
              Text('ຊຳລະເງິນສຳເລັດ',
                  style: TextStyle(
                      fontSize: 22.sp, fontWeight: FontWeight.w700)),
              SizedBox(height: 8.h),
                Text('ບິນ: ${result['orderId'] ?? '-'}',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[700])),
                SizedBox(height: 8.h),
                Text('ຍອດລວມ ₭${currencyFmt.format(total)}',
                  style: TextStyle(fontSize: 15.sp, color: Colors.black87)),
                Text('ລັບຊຳລະ ₭${currencyFmt.format(paid)}',
                  style: TextStyle(fontSize: 15.sp, color: Colors.black87)),
              if (change > 0)
                Text(
                  'ທອນເງິນ ₭${currencyFmt.format(change)}',
                  style: TextStyle(
                      fontSize: 16.sp, color: Colors.green[700]),
                ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      _showReceiptPreview(context);
                    },
                    icon: const Icon(Icons.receipt),
                    label: const Text('ເບິ່ງໃບເສັດ'),
                  ),
                  SizedBox(width: 12.w),
                  FilledButton.icon(
                    onPressed: onDone,
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('ລາຍການໃໝ່'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
