import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/sound_player_util.dart';
import '../../../products/data/products_repository.dart';
import '../../data/pos_repository.dart';
import '../../providers/cart_provider.dart';
import '../../providers/pos_view_mode_provider.dart';
import '../utils/pos_keyboard_shortcuts.dart';
import '../widgets/product_grid.dart';
import '../widgets/product_list_view.dart';
import '../widgets/quick_keys_bar.dart';
import '../widgets/order_cart.dart';
import '../widgets/payment_panel.dart';
import '../widgets/modifier_dialog.dart';
import '../../../auth/providers/auth_provider.dart';

// Selected category state
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// Whether the payment panel is visible
final paymentPanelVisibleProvider = StateProvider<bool>((ref) => false);

final productSearchQueryProvider = StateProvider<String>((ref) => '');

// ─────────────────────────────────────────────────────────────────────────────
// POS Page
// ─────────────────────────────────────────────────────────────────────────────
class PosPage extends ConsumerStatefulWidget {
  const PosPage({
    super.key,
    this.initialTableId,
    this.initialTableName,
  });

  final String? initialTableId;
  final String? initialTableName;

  @override
  ConsumerState<PosPage> createState() => _PosPageState();
}

class _PosPageState extends ConsumerState<PosPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey _cartIconKey = GlobalKey();
  double _cartScale = 1;

  static const _desktopBreakpoint = 980.0;

  @override
  void initState() {
    super.initState();
    final tableId = widget.initialTableId;
    final tableName = widget.initialTableName;
    if (tableId != null && tableId.isNotEmpty && tableName != null && tableName.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(cartProvider.notifier).setTable(tableId, tableName);
      });
    }
  }

  Future<void> _playFlyToCartAnimation(Offset startGlobal) async {
    final overlay = Overlay.of(context);

    final box =
        _cartIconKey.currentContext?.findRenderObject() as RenderBox?;
    final endGlobal = box != null
        ? box.localToGlobal(Offset(box.size.width / 2, box.size.height / 2))
        : Offset(MediaQuery.of(context).size.width - 44, 28);

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );

    final movement = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutCubic,
    );

    final dx = Tween<double>(begin: startGlobal.dx, end: endGlobal.dx)
        .animate(movement);
    final dy = Tween<double>(begin: startGlobal.dy, end: endGlobal.dy)
        .animate(movement);

    final scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 1.22)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.22, end: 0.58)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 60,
      ),
    ]).animate(controller);

    final opacity = Tween<double>(begin: 1, end: 0.2).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.68, 1, curve: Curves.easeOut),
      ),
    );

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return Positioned(
              left: dx.value - 14,
              top: dy.value - 14,
              child: IgnorePointer(
                child: Opacity(
                  opacity: opacity.value,
                  child: Transform.scale(
                    scale: scale.value,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shopping_bag,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    overlay.insert(entry);
    await controller.forward();
    entry.remove();
    controller.dispose();

    if (!mounted) return;
    setState(() => _cartScale = 1.16);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    setState(() => _cartScale = 1);
  }

  Future<void> _showCartBottomSheet(
    BuildContext context,
    WidgetRef ref,
    CartState cart,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: OrderCart(
            cart: cart,
            onCheckout: () {
              Navigator.of(context).pop();
              _showPaymentBottomSheet(context, cart);
            },
          ),
        );
      },
    );
  }

  Future<void> _showPaymentBottomSheet(
    BuildContext context,
    CartState cart,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.92,
          child: PaymentPanel(
            cart: cart,
            onClose: () => Navigator.of(context).pop(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final authState = ref.watch(authProvider);
    final userName = authState is AuthAuthenticated
        ? authState.user.displayName
        : 'ລະບົບ';
    final now = DateTime.now();
    final formatter = DateFormat('EEE d MMM y  HH:mm');

    return Focus(
      autofocus: true,
      onKeyEvent: (_, event) => _handleKeyEvent(event, cart),
      child: Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Column(
        children: [
          _PosHeader(
            userName: userName,
            dateTime: formatter.format(now),
            cartItemCount: cart.itemCount,
            cartScale: _cartScale,
            cartIconKey: _cartIconKey,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= _desktopBreakpoint;
                if (isDesktop) {
                  final paymentVisible = ref.watch(paymentPanelVisibleProvider);
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _CategoryStrip(),
                            Expanded(
                              child: _ProductSection(
                                onAddToCartAnimation: _playFlyToCartAnimation,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 340.w,
                        child: paymentVisible
                            ? PaymentPanel(
                                cart: cart,
                                onClose: () => ref
                                    .read(paymentPanelVisibleProvider.notifier)
                                    .state = false,
                              )
                            : OrderCart(
                                cart: cart,
                                onCheckout: () => ref
                                    .read(paymentPanelVisibleProvider.notifier)
                                    .state = true,
                              ),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    _CategoryStrip(),
                    Expanded(
                      child: _ProductSection(
                        onAddToCartAnimation: _playFlyToCartAnimation,
                      ),
                    ),
                    _MobileCartBottomBar(
                      cart: cart,
                      onTap: () => _showCartBottomSheet(context, ref, cart),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ), // Scaffold
    ); // Focus
  }

  // ── Keyboard handler (18.5.5) ──────────────────────────────────────────────
  KeyEventResult _handleKeyEvent(KeyEvent event, CartState cart) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final keys = HardwareKeyboard.instance.logicalKeysPressed;

    if (PosKeyboardShortcuts.isNewOrder(keys)) {
      ref.read(cartProvider.notifier).clear();
      return KeyEventResult.handled;
    }

    if (PosKeyboardShortcuts.isPayment(keys)) {
      if (cart.items.isNotEmpty) {
        ref.read(paymentPanelVisibleProvider.notifier).state = true;
      }
      return KeyEventResult.handled;
    }

    if (PosKeyboardShortcuts.isIncreaseQty(keys)) {
      final items = cart.items;
      if (items.isNotEmpty) {
        final last = items.last;
        ref.read(cartProvider.notifier).addItem(
          ProductItem(id: last.productId, name: last.productName, price: last.unitPrice, categoryId: ''),
        );
      }
      return KeyEventResult.handled;
    }

    if (PosKeyboardShortcuts.isDecreaseQty(keys)) {
      final items = cart.items;
      if (items.isNotEmpty) ref.read(cartProvider.notifier).removeItem(items.last.productId);
      return KeyEventResult.handled;
    }

    if (PosKeyboardShortcuts.isDeleteItem(keys)) {
      final items = cart.items;
      if (items.isNotEmpty) {
        ref.read(cartProvider.notifier).removeItem(items.last.productId);
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header bar
// ─────────────────────────────────────────────────────────────────────────────
class _PosHeader extends StatelessWidget {
  const _PosHeader({
    required this.userName,
    required this.dateTime,
    required this.cartItemCount,
    required this.cartScale,
    required this.cartIconKey,
  });

  final String userName;
  final String dateTime;
  final int cartItemCount;
  final double cartScale;
  final GlobalKey cartIconKey;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 60.h,
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkHeroGradient : AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              'LUMLUAY',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Text(
              dateTime,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_rounded, size: 16.sp, color: Colors.white),
                SizedBox(width: 6.w),
                Text(
                  userName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          AnimatedScale(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            scale: cartScale,
            child: Container(
              key: cartIconKey,
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: Colors.white.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 16.sp),
                  SizedBox(width: 6.w),
                  Text(
                    '$cartItemCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.sp,
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

// ─────────────────────────────────────────────────────────────────────────────
// Category strip
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryStrip extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selected = ref.watch(selectedCategoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 52.h,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: categoriesAsync.when(
        loading: () => Center(
          child: LinearProgressIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.primarySoft,
          ),
        ),
        error: (_, __) => const SizedBox(),
        data: (cats) => ListView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          children: [
            _CategoryChip(
              label: 'ທັງໝົດ',
              isSelected: selected == null,
              onTap: () =>
                  ref.read(selectedCategoryProvider.notifier).state = null,
            ),
            ...cats.map((c) => _CategoryChip(
                  label: c['name'] as String,
                  isSelected: selected == c['id'],
                  onTap: () => ref
                      .read(selectedCategoryProvider.notifier)
                      .state = c['id'] as String,
                )),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.primaryGradient : null,
            color: isSelected
                ? null
                : isDark
                    ? AppColors.surfaceVariantDark
                    : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: isSelected ? AppShadows.primaryGlow(0.15) : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Sarabun',
              fontSize: 13.sp,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product section
// ─────────────────────────────────────────────────────────────────────────────
class _ProductSection extends ConsumerStatefulWidget {
  const _ProductSection({required this.onAddToCartAnimation});

  final Future<void> Function(Offset startGlobal) onAddToCartAnimation;

  @override
  ConsumerState<_ProductSection> createState() => _ProductSectionState();
}

class _ProductSectionState extends ConsumerState<_ProductSection> {
  Future<ProductItem?> _resolveProductWithPrice(
    BuildContext context,
    ProductItem product,
  ) async {
    if (!product.isOpenPrice) return product;

    final ctrl = TextEditingController();
    final value = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('ລະບຸລາຄາ ${product.name}'),
          content: TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(prefixText: '₭ ', hintText: '0.00'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ຍົກເລີກ'),
            ),
            FilledButton(
              onPressed: () {
                final parsed = double.tryParse(ctrl.text.trim());
                if (parsed == null || parsed <= 0) return;
                Navigator.of(context).pop(parsed);
              },
              child: const Text('ຢືນຢັນ'),
            ),
          ],
        );
      },
    );

    if (value == null) return null;
    return product.copyWith(price: value);
  }

  Future<void> _onTapProduct(
    BuildContext context,
    ProductItem product,
    Offset tapOrigin,
  ) async {
    final selected = await _resolveProductWithPrice(context, product);
    if (selected == null) return;
    if (!mounted) return;
    // ignore: use_build_context_synchronously
    final item = await ModifierDialog.show(context, product: selected);
    if (item == null) return;
    ref.read(cartProvider.notifier).addCartItem(item);
    await ref.read(soundPlayerProvider).play(AppSound.newOrder);
    await widget.onAddToCartAnimation(tapOrigin);
  }

  // ── 17.2.4 Barcode scan ──────────────────────────────────────────────────

  void _openCameraScanner() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.55,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Text('ສະແກນ Barcode',
                  style:
                      TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700)),
            ),
            Expanded(
              child: MobileScanner(
                onDetect: (capture) {
                  final code = capture.barcodes.firstOrNull?.rawValue;
                  if (code != null && code.isNotEmpty) {
                    Navigator.of(context).pop();
                    _lookupAndAddByBarcode(code);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _lookupAndAddByBarcode(String code) async {
    try {
      final repo = ref.read(productsRepositoryProvider);
      final product = await repo.findByBarcode(code);
      if (!mounted) return;
      final item = ProductItem.fromJson(product.toJson());
      final resolved = await _resolveProductWithPrice(context, item);
      if (resolved == null || !mounted) return;
      final cartItem = await ModifierDialog.show(context, product: resolved);
      if (cartItem == null) return;
      ref.read(cartProvider.notifier).addCartItem(cartItem);
      await ref.read(soundPlayerProvider).play(AppSound.newOrder);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ບໍ່ພົບສິນຄ້າສຳລັບ barcode: $code'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final query = ref.watch(productSearchQueryProvider);
    final viewMode = ref.watch(posViewModeProvider);
    final productsAsync = ref.watch(productsProvider(selectedCategory));

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('ເກີດຂໍ້ຜິດພາດ: $e')),
      data: (products) {
        final q = query.trim().toLowerCase();
        final filtered = q.isEmpty
            ? products
            : products.where((p) {
                final name = p.name.toLowerCase();
                final sku = (p.sku ?? '').toLowerCase();
                final barcode = (p.barcode ?? '').toLowerCase();
                return name.contains(q) || sku.contains(q) || barcode.contains(q);
              }).toList();

        return Column(
          children: [
            _ProductToolsBar(
              onQueryChanged: (value) =>
                  ref.read(productSearchQueryProvider.notifier).state = value,
              viewMode: viewMode,
              onToggleView: () => ref.read(posViewModeProvider.notifier).toggle(),
              onScanPressed: _openCameraScanner,
            ),
            QuickKeysBar(
              products: filtered,
              onTapProduct: (product, tapOrigin) =>
                  _onTapProduct(context, product, tapOrigin),
            ),
            Expanded(
              child: viewMode == PosProductViewMode.grid
                  ? ProductGrid(
                      products: filtered,
                      onAddRequested: (product, tapOrigin) =>
                          _onTapProduct(context, product, tapOrigin),
                    )
                  : ProductListView(
                      products: filtered,
                      onAddRequested: (product, tapOrigin) =>
                          _onTapProduct(context, product, tapOrigin),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _ProductToolsBar extends StatelessWidget {
  const _ProductToolsBar({
    required this.onQueryChanged,
    required this.viewMode,
    required this.onToggleView,
    required this.onScanPressed,
  });

  final ValueChanged<String> onQueryChanged;
  final PosProductViewMode viewMode;
  final VoidCallback onToggleView;
  final VoidCallback onScanPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: onQueryChanged,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'ຄົ້ນຫາສິນຄ້າ / SKU / Barcode',
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          SizedBox(width: 6.w),
          // 17.2.4 Camera barcode scan button
          IconButton.filledTonal(
            onPressed: onScanPressed,
            tooltip: 'ສະແກນ Barcode',
            icon: const Icon(Icons.qr_code_scanner),
          ),
          SizedBox(width: 6.w),
          IconButton.filledTonal(
            onPressed: onToggleView,
            tooltip: viewMode == PosProductViewMode.grid
                ? 'ສະຫຼັບເປັນ List'
                : 'ສະຫຼັບເປັນ Grid',
            icon: Icon(
              viewMode == PosProductViewMode.grid
                  ? Icons.view_list_rounded
                  : Icons.grid_view_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileCartBottomBar extends StatelessWidget {
  const _MobileCartBottomBar({required this.cart, required this.onTap});

  final CartState cart;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,##0.00', 'th_TH');
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      '${cart.itemCount} ລາຍການ',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'ເບິ່ງກະຕ່າ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '₭${money.format(cart.total)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
