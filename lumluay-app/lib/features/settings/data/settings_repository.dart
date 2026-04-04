import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class StoreSettings {
  final String? storeName;
  final bool taxEnabled;
  final bool serviceChargeEnabled;
  final double serviceChargePercent;
  final bool receiptPrintEnabled;
  final String? defaultCurrency;

  const StoreSettings({
    this.storeName,
    this.taxEnabled = false,
    this.serviceChargeEnabled = false,
    this.serviceChargePercent = 0,
    this.receiptPrintEnabled = true,
    this.defaultCurrency,
  });

  factory StoreSettings.fromJson(Map<String, dynamic> j) => StoreSettings(
        storeName: j['storeName'] as String?,
        taxEnabled: j['taxEnabled'] as bool? ?? false,
        serviceChargeEnabled: j['serviceChargeEnabled'] as bool? ?? false,
        serviceChargePercent:
            double.tryParse(j['serviceChargePercent']?.toString() ?? '0') ?? 0,
        receiptPrintEnabled: j['receiptPrintEnabled'] as bool? ?? true,
        defaultCurrency: j['defaultCurrency'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (storeName != null) 'storeName': storeName,
        'taxEnabled': taxEnabled,
        'serviceChargeEnabled': serviceChargeEnabled,
        'serviceChargePercent': serviceChargePercent,
        'receiptPrintEnabled': receiptPrintEnabled,
        if (defaultCurrency != null) 'defaultCurrency': defaultCurrency,
      };

  StoreSettings copyWith({
    String? storeName,
    bool? taxEnabled,
    bool? serviceChargeEnabled,
    double? serviceChargePercent,
    bool? receiptPrintEnabled,
    String? defaultCurrency,
  }) =>
      StoreSettings(
        storeName: storeName ?? this.storeName,
        taxEnabled: taxEnabled ?? this.taxEnabled,
        serviceChargeEnabled: serviceChargeEnabled ?? this.serviceChargeEnabled,
        serviceChargePercent:
            serviceChargePercent ?? this.serviceChargePercent,
        receiptPrintEnabled: receiptPrintEnabled ?? this.receiptPrintEnabled,
        defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      );
}

class TaxRate {
  final String id;
  final String name;
  final double rate;
  final bool isDefault;

  const TaxRate({
    required this.id,
    required this.name,
    required this.rate,
    required this.isDefault,
  });

  factory TaxRate.fromJson(Map<String, dynamic> j) => TaxRate(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        rate: double.tryParse(j['rate']?.toString() ?? '0') ?? 0,
        isDefault: j['isDefault'] as bool? ?? false,
      );
}

class SettingsRepository {
  const SettingsRepository(this._api);
  final ApiClient _api;

  Future<({StoreSettings settings, List<TaxRate> taxRates})> getSettings() async {
    final data = await _api.get<Map<String, dynamic>>('/settings');
    final rawSettings = data['settings'] as Map<String, dynamic>? ?? {};
    final rawTax = data['taxRates'] as List? ?? [];
    return (
      settings: StoreSettings.fromJson(rawSettings),
      taxRates: rawTax
          .map((e) => TaxRate.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<StoreSettings> updateSettings(StoreSettings s) async {
    final data = await _api.patch<Map<String, dynamic>>(
      '/settings',
      data: s.toJson(),
    );
    return StoreSettings.fromJson(data);
  }

  Future<void> createTaxRate(
      {required String name, required double rate, bool isDefault = false}) async {
    await _api.post('/settings/tax-rates',
        data: {'name': name, 'rate': rate, 'isDefault': isDefault});
  }

  Future<CurrencySettings> getCurrencies() async {
    final data = await _api.get<Map<String, dynamic>>('/settings/currencies');
    return CurrencySettings.fromJson(data);
  }

  Future<CurrencySettings> updateCurrencies(CurrencySettings s) async {
    final data = await _api.patch<Map<String, dynamic>>(
      '/settings/currencies',
      data: s.toJson(),
    );
    return CurrencySettings.fromJson(data);
  }

  Future<Map<String, double>> updateExchangeRates(
      Map<String, double> rates) async {
    final data = await _api.patch<Map<String, dynamic>>(
      '/settings/exchange-rates',
      data: {'rates': rates},
    );
    final raw = data['rates'] as Map<String, dynamic>? ?? {};
    return raw.map((k, v) => MapEntry(k, double.tryParse('$v') ?? 0));
  }

  Future<ReceiptSettings> getReceiptSettings() async {
    final data = await _api.get<Map<String, dynamic>>('/settings/receipt');
    return ReceiptSettings.fromJson(data);
  }

  Future<ReceiptSettings> updateReceiptSettings(ReceiptSettings s) async {
    final data = await _api.patch<Map<String, dynamic>>(
      '/settings/receipt',
      data: s.toJson(),
    );
    return ReceiptSettings.fromJson(data);
  }

  Future<List<PrinterConfig>> getPrinters() async {
    final data = await _api.get<List<dynamic>>('/settings/printers');
    return data
        .map((e) => PrinterConfig.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PrinterConfig> createPrinter(PrinterConfig p) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/settings/printers',
      data: p.toCreateJson(),
    );
    return PrinterConfig.fromJson(data);
  }

  Future<PrinterConfig> updatePrinter(PrinterConfig p) async {
    final data = await _api.patch<Map<String, dynamic>>(
      '/settings/printers/${p.id}',
      data: p.toUpdateJson(),
    );
    return PrinterConfig.fromJson(data);
  }

  Future<void> deletePrinter(String id) async {
    await _api.delete('/settings/printers/$id');
  }

  Future<TenantProfile> getTenantProfile() async {
    final data = await _api.get<Map<String, dynamic>>('/tenant');
    return TenantProfile.fromJson(data);
  }

  Future<TenantInfo> updateTenantInfo(TenantInfo info) async {
    final data = await _api.patch<Map<String, dynamic>>(
      '/tenant',
      data: info.toJson(),
    );
    return TenantInfo.fromJson(data);
  }

  Future<SampleSeedResult> seedSampleData({bool clearExisting = false}) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/settings/sample-data/seed',
      data: {'clearExisting': clearExisting},
    );
    return SampleSeedResult.fromJson(data);
  }
}

class TenantProfile {
  final TenantInfo tenant;

  const TenantProfile({required this.tenant});

  factory TenantProfile.fromJson(Map<String, dynamic> j) => TenantProfile(
        tenant: TenantInfo.fromJson(
          (j['tenant'] as Map<String, dynamic>? ?? {}),
        ),
      );
}

class TenantInfo {
  final String id;
  final String name;
  final String ownerName;
  final String? email;
  final String? phone;
  final String? address;
  final String? taxId;

  const TenantInfo({
    required this.id,
    required this.name,
    required this.ownerName,
    this.email,
    this.phone,
    this.address,
    this.taxId,
  });

  factory TenantInfo.fromJson(Map<String, dynamic> j) => TenantInfo(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        ownerName: j['ownerName']?.toString() ?? '',
        email: j['email']?.toString(),
        phone: j['phone']?.toString(),
        address: j['address']?.toString(),
        taxId: j['taxId']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'ownerName': ownerName,
        'email': email,
        'phone': phone,
        'address': address,
        'taxId': taxId,
      };

  TenantInfo copyWith({
    String? id,
    String? name,
    String? ownerName,
    String? email,
    String? phone,
    String? address,
    String? taxId,
  }) =>
      TenantInfo(
        id: id ?? this.id,
        name: name ?? this.name,
        ownerName: ownerName ?? this.ownerName,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        taxId: taxId ?? this.taxId,
      );
}

class SampleSeedResult {
  final int createdCategories;
  final int createdProducts;
  final bool skipped;
  final String? reason;

  const SampleSeedResult({
    required this.createdCategories,
    required this.createdProducts,
    required this.skipped,
    this.reason,
  });

  factory SampleSeedResult.fromJson(Map<String, dynamic> j) =>
      SampleSeedResult(
        createdCategories: int.tryParse('${j['createdCategories']}') ?? 0,
        createdProducts: int.tryParse('${j['createdProducts']}') ?? 0,
        skipped: j['skipped'] == true,
        reason: j['reason']?.toString(),
      );
}

class CurrencySettings {
  final String defaultCurrency;
  final List<String> enabledCurrencies;
  final Map<String, int> decimals;
  final Map<String, double> exchangeRates;

  const CurrencySettings({
    required this.defaultCurrency,
    required this.enabledCurrencies,
    required this.decimals,
    required this.exchangeRates,
  });

  factory CurrencySettings.fromJson(Map<String, dynamic> j) {
    final rawDecimals = j['decimals'] as Map<String, dynamic>? ?? {};
    final rawRates = j['exchangeRates'] as Map<String, dynamic>? ?? {};
    return CurrencySettings(
      defaultCurrency: j['defaultCurrency']?.toString() ?? 'THB',
      enabledCurrencies: ((j['enabledCurrencies'] as List?) ?? ['THB'])
          .map((e) => e.toString())
          .toList(),
      decimals: rawDecimals.map(
        (k, v) => MapEntry(k, int.tryParse('$v') ?? 2),
      ),
      exchangeRates: rawRates.map(
        (k, v) => MapEntry(k, double.tryParse('$v') ?? 0),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'defaultCurrency': defaultCurrency,
        'enabledCurrencies': enabledCurrencies,
        'decimals': decimals,
      };
}

class ReceiptSettings {
  final String header;
  final String footer;
  final String prefix;
  final int width;
  final bool showLogo;

  const ReceiptSettings({
    required this.header,
    required this.footer,
    required this.prefix,
    required this.width,
    required this.showLogo,
  });

  factory ReceiptSettings.fromJson(Map<String, dynamic> j) => ReceiptSettings(
        header: j['header']?.toString() ?? '',
        footer: j['footer']?.toString() ?? '',
        prefix: j['prefix']?.toString() ?? 'RC',
        width: int.tryParse('${j['width']}') ?? 80,
        showLogo: j['showLogo'] == true,
      );

  Map<String, dynamic> toJson() => {
        'header': header,
        'footer': footer,
        'prefix': prefix,
        'width': width,
        'showLogo': showLogo,
      };
}

class PrinterConfig {
  final String id;
  final String name;
  final String type;
  final String ipAddress;
  final int port;
  final bool isDefault;

  const PrinterConfig({
    required this.id,
    required this.name,
    required this.type,
    required this.ipAddress,
    required this.port,
    required this.isDefault,
  });

  factory PrinterConfig.fromJson(Map<String, dynamic> j) => PrinterConfig(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        type: j['type']?.toString() ?? 'bluetooth',
        ipAddress: j['ipAddress']?.toString() ?? '',
        port: int.tryParse('${j['port']}') ?? 9100,
        isDefault: j['isDefault'] == true,
      );

  Map<String, dynamic> toCreateJson() => {
        'name': name,
        'type': type,
        'ipAddress': ipAddress,
        'port': port,
        'isDefault': isDefault,
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'type': type,
        'ipAddress': ipAddress,
        'port': port,
        'isDefault': isDefault,
      };
}

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(apiClientProvider)),
);

typedef SettingsData = ({StoreSettings settings, List<TaxRate> taxRates});

final settingsDataProvider = FutureProvider<SettingsData>((ref) {
  return ref.watch(settingsRepositoryProvider).getSettings();
});
