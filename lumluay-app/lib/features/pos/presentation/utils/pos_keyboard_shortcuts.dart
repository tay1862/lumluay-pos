import 'package:flutter/services.dart';

/// POS keyboard shortcut definitions (18.5.5).
///
/// Shortcuts follow the spec in docs/design/04-ui-ux-flow.md.
class PosKeyboardShortcuts {
  PosKeyboardShortcuts._();

  // ── Numpad / digit quick-add ──────────────────────────────────
  /// F1-F9: select product slot 1-9 in the current category
  static bool isProductSlotKey(LogicalKeyboardKey key, int slot) {
    return key == _fKeys[slot];
  }

  // ── Global POS actions ────────────────────────────────────────
  /// Ctrl+N / F10: new order
  static bool isNewOrder(Set<LogicalKeyboardKey> keys) =>
      (_hasCtrl(keys) && keys.contains(LogicalKeyboardKey.keyN)) ||
      keys.contains(LogicalKeyboardKey.f10);

  /// Ctrl+P / F11: open payment panel
  static bool isPayment(Set<LogicalKeyboardKey> keys) =>
      (_hasCtrl(keys) && keys.contains(LogicalKeyboardKey.keyP)) ||
      keys.contains(LogicalKeyboardKey.f11);

  /// Escape: close modal / cancel
  static bool isCancel(Set<LogicalKeyboardKey> keys) =>
      keys.contains(LogicalKeyboardKey.escape);

  /// Delete: remove selected cart item
  static bool isDeleteItem(Set<LogicalKeyboardKey> keys) =>
      keys.contains(LogicalKeyboardKey.delete) ||
      keys.contains(LogicalKeyboardKey.backspace);

  /// +  (numpadAdd or equal): increase quantity of selected item
  static bool isIncreaseQty(Set<LogicalKeyboardKey> keys) =>
      keys.contains(LogicalKeyboardKey.numpadAdd) ||
      keys.contains(LogicalKeyboardKey.equal);

  /// -  (numpadSubtract or minus): decrease quantity of selected item
  static bool isDecreaseQty(Set<LogicalKeyboardKey> keys) =>
      keys.contains(LogicalKeyboardKey.numpadSubtract) ||
      keys.contains(LogicalKeyboardKey.minus);

  /// F12: open barcode scan mode
  static bool isBarcodeScan(Set<LogicalKeyboardKey> keys) =>
      keys.contains(LogicalKeyboardKey.f12);

  // ── Internal helpers ─────────────────────────────────────────
  static bool _hasCtrl(Set<LogicalKeyboardKey> keys) =>
      keys.contains(LogicalKeyboardKey.controlLeft) ||
      keys.contains(LogicalKeyboardKey.controlRight);

  static final _fKeys = {
    1: LogicalKeyboardKey.f1,
    2: LogicalKeyboardKey.f2,
    3: LogicalKeyboardKey.f3,
    4: LogicalKeyboardKey.f4,
    5: LogicalKeyboardKey.f5,
    6: LogicalKeyboardKey.f6,
    7: LogicalKeyboardKey.f7,
    8: LogicalKeyboardKey.f8,
    9: LogicalKeyboardKey.f9,
  };
}
