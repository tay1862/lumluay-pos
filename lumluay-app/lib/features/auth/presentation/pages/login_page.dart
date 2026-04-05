import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _tenantCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic));
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _tenantCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).login(
          tenantSlug: _tenantCtrl.text.trim(),
          username: _usernameCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen(authProvider, (prev, next) {
      if (next is AuthAuthenticated) {
        context.go('/pos');
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkHeroGradient : AppColors.heroGradient,
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 420;
              final horizontalPadding = isCompact ? 20.0 : 32.0;
              final formPadding = isCompact ? 24.0 : 32.0;

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    32,
                    horizontalPadding,
                    32 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            boxShadow: isDark
                                ? AppShadows.cardDark
                                : AppShadows.elevated,
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(formPadding),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // ── Brand Logo ──
                                  Center(
                                    child: Container(
                                      width: 80.w,
                                      height: 80.w,
                                      decoration: BoxDecoration(
                                        gradient: AppColors.primaryGradient,
                                        borderRadius: BorderRadius.circular(AppRadius.xl),
                                        boxShadow: AppShadows.primaryGlow(0.25),
                                      ),
                                      child: Icon(
                                        Icons.storefront_rounded,
                                        size: 38.sp,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 20.h),

                                  // ── Title ──
                                  Center(
                                    child: Text(
                                      'LUMLUAY POS',
                                      style: TextStyle(
                                        fontFamily: 'Sarabun',
                                        fontSize: 26.sp,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 6.h),
                                  Center(
                                    child: Text(
                                      'ເຂົ້າສູ່ລະບົບເພື່ອຈັດການຮ້ານຄ້າຂອງທ່ານ',
                                      style: TextStyle(
                                        fontFamily: 'Sarabun',
                                        fontSize: 14.sp,
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondary,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 28.h),

                                  // ── Tenant Field ──
                                  TextFormField(
                                    controller: _tenantCtrl,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [AutofillHints.organizationName],
                                    decoration: InputDecoration(
                                      labelText: 'ລະຫັດຮ້ານຄ້າ',
                                      hintText: 'ປ້ອນລະຫັດຮ້ານຄ້າ',
                                      prefixIcon: Icon(
                                        Icons.storefront_outlined,
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textTertiary,
                                      ),
                                    ),
                                    validator: (v) =>
                                        (v == null || v.isEmpty) ? 'ກະລຸນາປ້ອນລະຫັດຮ້ານຄ້າ' : null,
                                  ),
                                  SizedBox(height: 16.h),

                                  // ── Username Field ──
                                  TextFormField(
                                    controller: _usernameCtrl,
                                    textInputAction: TextInputAction.next,
                                    onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                                    autofillHints: const [AutofillHints.username],
                                    decoration: InputDecoration(
                                      labelText: 'ຊື່ຜູ້ໃຊ້',
                                      hintText: 'ປ້ອນຊື່ຜູ້ໃຊ້',
                                      prefixIcon: Icon(
                                        Icons.person_outline_rounded,
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textTertiary,
                                      ),
                                    ),
                                    validator: (v) =>
                                        (v == null || v.isEmpty) ? 'ກະລຸນາປ້ອນຊື່ຜູ້ໃຊ້' : null,
                                  ),
                                  SizedBox(height: 16.h),

                                  // ── Password Field ──
                                  TextFormField(
                                    controller: _passwordCtrl,
                                    focusNode: _passwordFocusNode,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) {
                                      if (authState is! AuthLoading) {
                                        _login();
                                      }
                                    },
                                    autofillHints: const [AutofillHints.password],
                                    decoration: InputDecoration(
                                      labelText: 'ລະຫັດຜ່ານ',
                                      hintText: 'ປ້ອນລະຫັດຜ່ານ',
                                      prefixIcon: Icon(
                                        Icons.lock_outline_rounded,
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textTertiary,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textTertiary,
                                        ),
                                        onPressed: () => setState(
                                          () => _obscurePassword = !_obscurePassword,
                                        ),
                                      ),
                                    ),
                                    validator: (v) =>
                                        (v == null || v.isEmpty) ? 'ກະລຸນາປ້ອນລະຫັດຜ່ານ' : null,
                                  ),
                                  SizedBox(height: 8.h),

                                  // ── Remember Me ──
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          onChanged: (v) =>
                                              setState(() => _rememberMe = v ?? false),
                                          activeColor: AppColors.primary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          side: BorderSide(
                                            color: isDark
                                                ? AppColors.borderDark
                                                : AppColors.border,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        'ຈື່ການເຂົ້າສູ່ລະບົບ',
                                        style: TextStyle(
                                          fontFamily: 'Sarabun',
                                          fontSize: 13.sp,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 24.h),

                                  // ── Login Button ──
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                      gradient: AppColors.primaryGradient,
                                      boxShadow: AppShadows.primaryGlow(0.3),
                                    ),
                                    child: FilledButton(
                                      onPressed: authState is AuthLoading ? null : _login,
                                      style: FilledButton.styleFrom(
                                        minimumSize: Size.fromHeight(56.h),
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(AppRadius.md),
                                        ),
                                      ),
                                      child: authState is AuthLoading
                                          ? SizedBox(
                                              height: 22.w,
                                              width: 22.w,
                                              child: const CircularProgressIndicator(
                                                strokeWidth: 2.4,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                              'ເຂົ້າສູ່ລະບົບ',
                                              style: TextStyle(
                                                fontFamily: 'Sarabun',
                                                fontSize: 17.sp,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  ),
                                  SizedBox(height: 16.h),

                                  // ── Footer ──
                                  Center(
                                    child: Text(
                                      'Lumluay POS v1.0',
                                      style: TextStyle(
                                        fontFamily: 'Sarabun',
                                        fontSize: 12.sp,
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textTertiary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
