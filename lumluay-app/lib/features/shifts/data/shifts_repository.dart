import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

enum ShiftStatus { open, closed }

class Shift {
  final String id;
  final ShiftStatus status;
  final double openingCash;
  final double? closingCash;
  final double? totalSales;
  final int? totalOrders;
  final DateTime openedAt;
  final DateTime? closedAt;
  final String openedByName;

  const Shift({
    required this.id,
    required this.status,
    required this.openingCash,
    this.closingCash,
    this.totalSales,
    this.totalOrders,
    required this.openedAt,
    this.closedAt,
    required this.openedByName,
  });

  factory Shift.fromJson(Map<String, dynamic> j) => Shift(
        id: j['id'] as String,
        status: j['status'] == 'open' ? ShiftStatus.open : ShiftStatus.closed,
        openingCash:
            (j['openingCash'] as num?)?.toDouble() ?? 0,
        closingCash: (j['closingCash'] as num?)?.toDouble(),
        totalSales: (j['totalSales'] as num?)?.toDouble(),
        totalOrders: (j['totalOrders'] as num?)?.toInt(),
        openedAt: DateTime.tryParse(j['openedAt'] as String? ?? '') ??
            DateTime.now(),
        closedAt: j['closedAt'] != null
            ? DateTime.tryParse(j['closedAt'] as String)
            : null,
        openedByName: j['openedByName'] as String? ?? '',
      );
}

class ShiftsRepository {
  const ShiftsRepository(this._api);
  final ApiClient _api;

  Future<Shift?> getCurrentShift() async {
    try {
      final resp = await _api.get('/shifts/current');
      if (resp == null) return null;
      return Shift.fromJson(resp as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<List<Shift>> getShiftHistory() async {
    final resp = await _api.get('/shifts');
    final list = resp is List ? resp : (resp is Map ? (resp['data'] as List? ?? []) : []);
    return list
        .map((e) => Shift.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Shift> openShift(double openingCash) async {
    final resp = await _api
        .post('/shifts/open', data: {'openingCash': openingCash});
    return Shift.fromJson(resp as Map<String, dynamic>);
  }

  Future<Shift> closeShift(double closingCash) async {
    final resp = await _api
        .post('/shifts/close', data: {'closingCash': closingCash});
    return Shift.fromJson(resp as Map<String, dynamic>);
  }
}

final shiftsRepositoryProvider = Provider<ShiftsRepository>(
  (ref) => ShiftsRepository(ref.watch(apiClientProvider)),
);

final currentShiftProvider = FutureProvider<Shift?>((ref) {
  return ref.watch(shiftsRepositoryProvider).getCurrentShift();
});

final shiftHistoryProvider = FutureProvider<List<Shift>>((ref) {
  return ref.watch(shiftsRepositoryProvider).getShiftHistory();
});

// ─────────────────────────────────────────────────────────────────────────────
// ShiftBloc (10.2.2)
// Global notifier that tracks the current shift state and exposes open/close
// actions.  Consumed by the router shift-guard (10.2.5) and the shift page.
// ─────────────────────────────────────────────────────────────────────────────

enum ShiftBlocStatus { initial, loading, open, closed, error }

class ShiftBlocState {
  final ShiftBlocStatus status;
  final Shift? shift;
  final String? errorMessage;

  const ShiftBlocState({
    this.status = ShiftBlocStatus.initial,
    this.shift,
    this.errorMessage,
  });

  bool get hasOpenShift => status == ShiftBlocStatus.open;

  ShiftBlocState copyWith({
    ShiftBlocStatus? status,
    Shift? shift,
    String? errorMessage,
  }) =>
      ShiftBlocState(
        status: status ?? this.status,
        shift: shift ?? this.shift,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

class ShiftNotifier extends StateNotifier<ShiftBlocState> {
  ShiftNotifier(this._repo) : super(const ShiftBlocState()) {
    checkCurrent();
  }

  final ShiftsRepository _repo;

  Future<void> checkCurrent() async {
    state = state.copyWith(status: ShiftBlocStatus.loading);
    try {
      final shift = await _repo.getCurrentShift();
      if (shift != null && shift.status == ShiftStatus.open) {
        state = ShiftBlocState(status: ShiftBlocStatus.open, shift: shift);
      } else {
        state = const ShiftBlocState(status: ShiftBlocStatus.closed);
      }
    } catch (e) {
      state = ShiftBlocState(
          status: ShiftBlocStatus.error, errorMessage: e.toString());
    }
  }

  Future<bool> openShift(double openingCash) async {
    state = state.copyWith(status: ShiftBlocStatus.loading);
    try {
      final shift = await _repo.openShift(openingCash);
      state = ShiftBlocState(status: ShiftBlocStatus.open, shift: shift);
      return true;
    } catch (e) {
      state = ShiftBlocState(
          status: ShiftBlocStatus.error, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> closeShift(double closingCash) async {
    state = state.copyWith(status: ShiftBlocStatus.loading);
    try {
      final shift = await _repo.closeShift(closingCash);
      state = ShiftBlocState(status: ShiftBlocStatus.closed, shift: shift);
      return true;
    } catch (e) {
      state = ShiftBlocState(
          status: ShiftBlocStatus.error, errorMessage: e.toString());
      return false;
    }
  }
}

final shiftBlocProvider =
    StateNotifierProvider<ShiftNotifier, ShiftBlocState>((ref) {
  return ShiftNotifier(ref.watch(shiftsRepositoryProvider));
});
