import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../../../core/sync/sync_engine.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _tenantCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;

  @override
  void dispose() {
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

    ref.listen(authProvider, (prev, next) {
      if (next is AuthAuthenticated) {
        final engine = ref.read(syncEngineProvider);
        engine.start();
        unawaited(
          engine.performInitialSync().catchError((Object e) {
            debugPrint('[SyncEngine] initial sync failed: $e');
          }),
        );
        context.go('/pos');
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    });

    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.96),
              const Color(0xFFFF6B00),
              const Color(0xFFFF7A1A),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 420;
              final horizontalPadding = isCompact ? 20.0 : 28.0;
              final formPadding = isCompact ? 22.0 : 30.0;
              final cardRadius = isCompact ? 24.0 : 28.0;

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    24,
                    horizontalPadding,
                    24 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(cardRadius),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 36,
                            offset: Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(formPadding),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Icon(
                                  Icons.storefront_rounded,
                                  size: 34,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'LUMLUAY POS',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'เข้าสู่ระบบเพื่อจัดการร้านค้าและดูแดชบอร์ดของคุณ',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF7A746E),
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: const [
                                  _LoginHintChip(
                                    icon: Icons.phone_android_rounded,
                                    label: 'เหมาะกับมือถือ',
                                  ),
                                  _LoginHintChip(
                                    icon: Icons.admin_panel_settings_outlined,
                                    label: 'รองรับ Super Admin',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              TextFormField(
                                controller: _tenantCtrl,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.organizationName],
                                decoration: const InputDecoration(
                                  labelText: 'รหัสร้านค้า',
                                  hintText: 'เช่น system-admin',
                                  prefixIcon: Icon(Icons.storefront_outlined),
                                ),
                                validator: (v) =>
                                    (v == null || v.isEmpty) ? 'กรุณากรอกรหัสร้านค้า' : null,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _usernameCtrl,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                                autofillHints: const [AutofillHints.username],
                                decoration: const InputDecoration(
                                  labelText: 'ชื่อผู้ใช้',
                                  hintText: 'เช่น superadmin',
                                  prefixIcon: Icon(Icons.person_outline_rounded),
                                ),
                                validator: (v) =>
                                    (v == null || v.isEmpty) ? 'กรุณากรอกชื่อผู้ใช้' : null,
                              ),
                              const SizedBox(height: 14),
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
                                  labelText: 'รหัสผ่าน',
                                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                    onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                ),
                                validator: (v) =>
                                    (v == null || v.isEmpty) ? 'กรุณากรอกรหัสผ่าน' : null,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'สำหรับผู้ดูแลระบบ ใช้ tenant `system-admin` และบัญชีที่ได้รับมอบหมาย',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF8C857E),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 22),
                              FilledButton(
                                onPressed: authState is AuthLoading ? null : _login,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(58),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: authState is AuthLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'เข้าสู่ระบบ',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
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
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LoginHintChip extends StatelessWidget {
  const _LoginHintChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
