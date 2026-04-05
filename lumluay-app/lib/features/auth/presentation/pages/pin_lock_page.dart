import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';

class PinLockPage extends ConsumerStatefulWidget {
  /// userId is the ID of the user whose PIN is being verified.
  /// When null, any authenticated user in the stored session is used.
  const PinLockPage({super.key, this.userId});
  final String? userId;

  @override
  ConsumerState<PinLockPage> createState() => _PinLockPageState();
}

class _PinLockPageState extends ConsumerState<PinLockPage>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _error = false;
  bool _loading = false;

  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  static const _maxLen = 6;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticOut),
    );
    _shakeCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        setState(() {
          _pin = '';
          _error = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _appendDigit(String d) {
    if (_pin.length >= _maxLen || _loading) return;
    setState(() {
      _pin += d;
      _error = false;
    });
    if (_pin.length == _maxLen) _submit();
  }

  void _backspace() {
    if (_pin.isEmpty || _loading) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _clear() {
    if (_loading) return;
    setState(() => _pin = '');
  }

  Future<void> _submit() async {
    if (_pin.length < 4) return;
    setState(() => _loading = true);

    final authState = ref.read(authProvider);
    final userId = widget.userId ??
        (authState is AuthAuthenticated ? authState.user.id : null);

    if (userId == null) {
      context.go('/login');
      return;
    }

    try {
      await ref.read(authProvider.notifier).loginWithPin(
            pin: _pin,
            userId: userId,
          );
      // After successful PIN login, go to dashboard
      if (mounted) context.go('/dashboard');
    } catch (e) {
      HapticFeedback.heavyImpact();
      setState(() {
        _error = true;
        _loading = false;
      });
      _shakeCtrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final displayName = authState is AuthAuthenticated
        ? authState.user.displayName
        : 'ຜູ້ໃຊ້ງານ';

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 40.h),

            // Avatar + Name
            CircleAvatar(
              radius: 36.r,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w700),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              displayName,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6.h),
            Text(
              'ກະລຸນາໃສ່ PIN',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 13.sp),
            ),

            SizedBox(height: 32.h),

            // PIN dots
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (ctx, child) {
                final dx = (_shakeAnim.value * 24 *
                        (1 - _shakeAnim.value) *
                        ((_pin.length % 2 == 0) ? 1 : -1))
                    .toDouble();
                return Transform.translate(
                  offset: Offset(dx, 0),
                  child: child!,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_maxLen, (i) {
                  final filled = i < _pin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: EdgeInsets.symmetric(horizontal: 8.w),
                    width: 16.w,
                    height: 16.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _error
                          ? Colors.red.shade300
                          : filled
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.3),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  );
                }),
              ),
            ),

            if (_error) ...[
              SizedBox(height: 12.h),
              Text(
                'PIN ບໍ່ຖືກຕ້ອງ ລອງອີກຄັ້ງ',
                style: TextStyle(
                    color: Colors.red.shade200, fontSize: 12.sp),
              ),
            ],

            const Spacer(),

            // Numpad
            Container(
              margin: EdgeInsets.symmetric(horizontal: 40.w),
              child: Column(
                children: [
                  for (final row in const [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                    ['C', '0', '⌫'],
                  ])
                    Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: row
                            .map((label) => _NumBtn(
                                  label: label,
                                  onTap: label == '⌫'
                                      ? _backspace
                                      : label == 'C'
                                          ? _clear
                                          : () => _appendDigit(label),
                                  loading: _loading,
                                ))
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Switch user
            TextButton(
              onPressed: () => context.go('/login'),
              child: Text(
                'ປ່ຽນຜູ້ໃຊ້',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13.sp),
              ),
            ),

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Numpad button
// ─────────────────────────────────────────────────────────────────────────────
class _NumBtn extends StatelessWidget {
  const _NumBtn({
    required this.label,
    required this.onTap,
    required this.loading,
  });
  final String label;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final isSpecial = label == '⌫' || label == 'C';

    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: 72.w,
        height: 72.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSpecial
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.2),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: isSpecial && label == '⌫'
              ? Icon(Icons.backspace_outlined,
                  color: Colors.white, size: 22.sp)
              : Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSpecial ? 16.sp : 22.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}

