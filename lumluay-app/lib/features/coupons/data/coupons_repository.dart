import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

enum CouponType { percent, fixed, freeItem }

class Coupon {
  final String id;
  final String code;
  final String name;
  final String? description;
  final CouponType type;
  final double value;
  final double? minOrderAmount;
  final double? maxDiscountAmount;
  final int? usageLimit;
  final int usageCount;
  final bool isActive;
  final DateTime? startsAt;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  const Coupon({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.type,
    required this.value,
    this.minOrderAmount,
    this.maxDiscountAmount,
    this.usageLimit,
    this.usageCount = 0,
    this.isActive = true,
    this.startsAt,
    this.expiresAt,
    this.createdAt,
  });

  factory Coupon.fromJson(Map<String, dynamic> j) => Coupon(
        id: j['id'] as String,
        code: j['code'] as String,
        name: j['name'] as String,
        description: j['description'] as String?,
        type: _parseType(j['type'] as String? ?? 'fixed'),
        value: double.tryParse('${j['value']}') ?? 0,
        minOrderAmount: j['minOrderAmount'] != null
            ? double.tryParse('${j['minOrderAmount']}')
            : null,
        maxDiscountAmount: j['maxDiscountAmount'] != null
            ? double.tryParse('${j['maxDiscountAmount']}')
            : null,
        usageLimit: (j['usageLimit'] as num?)?.toInt(),
        usageCount: (j['usageCount'] as num?)?.toInt() ?? 0,
        isActive: j['isActive'] as bool? ?? true,
        startsAt: j['startsAt'] != null
            ? DateTime.tryParse(j['startsAt'] as String)
            : null,
        expiresAt: j['expiresAt'] != null
            ? DateTime.tryParse(j['expiresAt'] as String)
            : null,
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'] as String)
            : null,
      );

  static CouponType _parseType(String t) {
    switch (t) {
      case 'percent':
        return CouponType.percent;
      case 'free_item':
        return CouponType.freeItem;
      default:
        return CouponType.fixed;
    }
  }

  String get typeLabel {
    switch (type) {
      case CouponType.percent:
        return 'ເປີເຊັນ';
      case CouponType.freeItem:
        return 'ຂອງຟຣີ';
      case CouponType.fixed:
        return 'ຈຳນວນເງິນ';
    }
  }

  String get typeApi {
    switch (type) {
      case CouponType.percent:
        return 'percent';
      case CouponType.freeItem:
        return 'free_item';
      case CouponType.fixed:
        return 'fixed';
    }
  }

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  bool get isEffectivelyActive => isActive && !isExpired;
}

class ValidateCouponResult {
  final Coupon coupon;
  final double discountAmount;

  const ValidateCouponResult({
    required this.coupon,
    required this.discountAmount,
  });

  factory ValidateCouponResult.fromJson(Map<String, dynamic> j) =>
      ValidateCouponResult(
        coupon: Coupon.fromJson(j['coupon'] as Map<String, dynamic>),
        discountAmount:
            double.tryParse('${j['discountAmount']}') ?? 0,
      );
}

class CouponsRepository {
  const CouponsRepository(this._api);
  final ApiClient _api;

  Future<List<Coupon>> getCoupons({bool? activeOnly}) async {
    final resp = await _api.get(
      '/coupons',
      queryParameters: {
        if (activeOnly == true) 'active': 'true',
      },
    );
    final list = resp is List ? resp : (resp is Map ? (resp['data'] as List? ?? []) : []);
    return list
        .map((e) => Coupon.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Coupon> createCoupon(Map<String, dynamic> data) async {
    final resp = await _api.post('/coupons', data: data);
    return Coupon.fromJson(resp as Map<String, dynamic>);
  }

  Future<Coupon> updateCoupon(String id, Map<String, dynamic> data) async {
    final resp = await _api.patch('/coupons/$id', data: data);
    return Coupon.fromJson(resp as Map<String, dynamic>);
  }

  Future<void> deleteCoupon(String id) async {
    await _api.delete('/coupons/$id');
  }

  Future<ValidateCouponResult> validateCoupon(
      String code, double orderAmount) async {
    final resp = await _api.post(
      '/coupons/validate',
      data: {'code': code, 'orderAmount': orderAmount},
    );
    return ValidateCouponResult.fromJson(
        resp as Map<String, dynamic>);
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final couponsRepositoryProvider = Provider<CouponsRepository>(
  (ref) => CouponsRepository(ref.watch(apiClientProvider)),
);

/// Filter: null = all, true = active, false = inactive/expired
final couponsFilterProvider = StateProvider<bool?>((ref) => null);

final couponsListProvider = FutureProvider<List<Coupon>>((ref) {
  final activeOnly = ref.watch(couponsFilterProvider);
  return ref.watch(couponsRepositoryProvider).getCoupons(
        activeOnly: activeOnly,
      );
});
