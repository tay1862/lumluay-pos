import 'package:flutter_test/flutter_test.dart';
import 'package:lumluay_pos/core/config/app_env.dart';
import 'package:lumluay_pos/core/network/api_client.dart';
import 'package:lumluay_pos/features/shifts/data/shifts_repository.dart';

class FakeShiftsRepository extends ShiftsRepository {
  FakeShiftsRepository()
      : super(ApiClient(const AppEnv(
          flavor: AppFlavor.dev,
          apiBaseUrl: 'http://localhost',
          wsBaseUrl: 'http://localhost',
        )));

  @override
  Future<Shift?> getCurrentShift() async => null;

  @override
  Future<Shift> openShift(double openingCash) async => Shift(
        id: 's1',
        status: ShiftStatus.open,
        openingCash: openingCash,
        openedAt: DateTime.now(),
        openedByName: 'Tester',
      );

  @override
  Future<Shift> closeShift(double closingCash) async => Shift(
        id: 's1',
        status: ShiftStatus.closed,
        openingCash: 100,
        closingCash: closingCash,
        openedAt: DateTime.now().subtract(const Duration(hours: 4)),
        closedAt: DateTime.now(),
        openedByName: 'Tester',
      );
}

void main() {
  test('ShiftNotifier open and close shift', () async {
    final notifier = ShiftNotifier(FakeShiftsRepository());

    final opened = await notifier.openShift(100);
    expect(opened, isTrue);
    expect(notifier.state.status, ShiftBlocStatus.open);

    final closed = await notifier.closeShift(150);
    expect(closed, isTrue);
    expect(notifier.state.status, ShiftBlocStatus.closed);
  });
}
