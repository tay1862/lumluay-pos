import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../data/settings_repository.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/config/app_env.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';

final _qrMenuLinkProvider = FutureProvider<({String menuUrl, String tenantName})?>((ref) async {
  final storage = const FlutterSecureStorage();
  final tenantSlug = await storage.read(key: AppConstants.keyTenantSlug);
  if (tenantSlug == null || tenantSlug.isEmpty) return null;

  final tenantProfile = await ref.read(settingsRepositoryProvider).getTenantProfile();
  final env = AppEnv.fromDartDefine();
  final apiBaseUrl = env.resolveApiBaseUrl(
    await storage.read(key: AppConstants.keyApiBaseUrl),
  );
  final publicBaseUrl = apiBaseUrl
      .replaceFirst(RegExp(r'/api/?$'), '')
      .replaceFirst(RegExp(r'/v1/?$'), '');

  return (
    menuUrl: '$publicBaseUrl/public/menu/$tenantSlug',
    tenantName: tenantProfile.tenant.name.isNotEmpty
        ? tenantProfile.tenant.name
        : (tenantProfile.tenant.ownerName.isNotEmpty
            ? tenantProfile.tenant.ownerName
            : 'LUMLUAY POS'),
  );
});

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งค่า'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.store_outlined), text: 'ร้านค้า'),
            Tab(icon: Icon(Icons.receipt_outlined), text: 'ภาษี'),
            Tab(icon: Icon(Icons.people_outline), text: 'ผู้ใช้'),
            Tab(icon: Icon(Icons.palette_outlined), text: 'ธีม/ภาษา'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _StoreSettingsTab(),
          _TaxRatesTab(),
          _UsersTab(),
          _ThemeLanguageTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Store Settings Tab
// ─────────────────────────────────────────────────────────────────────────────
class _StoreSettingsTab extends ConsumerStatefulWidget {
  const _StoreSettingsTab();

  @override
  ConsumerState<_StoreSettingsTab> createState() => _StoreSettingsTabState();
}

class _StoreSettingsTabState extends ConsumerState<_StoreSettingsTab> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameCtrl = TextEditingController();
  final _serviceChargeCtrl = TextEditingController();

  bool _taxEnabled = false;
  bool _serviceChargeEnabled = false;
  bool _receiptPrintEnabled = true;
  bool _saving = false;

  bool _initialized = false;

  void _initFrom(StoreSettings s) {
    if (_initialized) return;
    _initialized = true;
    _storeNameCtrl.text = s.storeName ?? '';
    _serviceChargeCtrl.text = s.serviceChargePercent.toString();
    _taxEnabled = s.taxEnabled;
    _serviceChargeEnabled = s.serviceChargeEnabled;
    _receiptPrintEnabled = s.receiptPrintEnabled;
  }

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _serviceChargeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(StoreSettings current) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updated = current.copyWith(
        storeName: _storeNameCtrl.text.trim(),
        taxEnabled: _taxEnabled,
        serviceChargeEnabled: _serviceChargeEnabled,
        serviceChargePercent:
            double.tryParse(_serviceChargeCtrl.text) ?? 0,
        receiptPrintEnabled: _receiptPrintEnabled,
      );
      await ref.read(settingsRepositoryProvider).updateSettings(updated);
      ref.invalidate(settingsDataProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('บันทึกการตั้งค่าแล้ว')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isSuperAdmin = authState is AuthAuthenticated &&
        authState.user.role == 'super_admin';
    final qrMenuLinkAsync = ref.watch(_qrMenuLinkProvider);

    final async = ref.watch(settingsDataProvider);
    return async.when(
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (data) {
        _initFrom(data.settings);
        return Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              _SectionHeader(title: 'ข้อมูลร้าน'),
              TextFormField(
                controller: _storeNameCtrl,
                decoration: const InputDecoration(
                    labelText: 'ชื่อร้าน', prefixIcon: Icon(Icons.storefront)),
                validator: (v) => v == null || v.isEmpty ? 'กรอกชื่อร้าน' : null,
              ),
              SizedBox(height: 24.h),
              _SectionHeader(title: 'การเงิน'),
              SwitchListTile(
                title: const Text('เรียกเก็บภาษี'),
                value: _taxEnabled,
                onChanged: (v) => setState(() => _taxEnabled = v),
              ),
              SwitchListTile(
                title: const Text('เรียกเก็บค่าบริการ'),
                value: _serviceChargeEnabled,
                onChanged: (v) => setState(() => _serviceChargeEnabled = v),
              ),
              if (_serviceChargeEnabled) ...[
                SizedBox(height: 4.h),
                TextFormField(
                  controller: _serviceChargeCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'ค่าบริการ (%)',
                    prefixIcon: Icon(Icons.percent),
                  ),
                  validator: (v) {
                    final d = double.tryParse(v ?? '');
                    if (d == null || d < 0 || d > 100) {
                      return 'กรอกตัวเลข 0–100';
                    }
                    return null;
                  },
                ),
              ],
              SizedBox(height: 24.h),
              _SectionHeader(title: 'การพิมพ์'),
              SwitchListTile(
                title: const Text('พิมพ์ใบเสร็จอัตโนมัติ'),
                value: _receiptPrintEnabled,
                onChanged: (v) => setState(() => _receiptPrintEnabled = v),
              ),
              SizedBox(height: 16.h),
              _SettingsTile(
                icon: Icons.auto_fix_high_outlined,
                title: 'Setup Wizard',
                subtitle: 'ตั้งค่าร้านแบบทีละขั้นตอน (5 ขั้น)',
                onTap: () => context.push('/setup-wizard'),
              ),
              SizedBox(height: 8.h),
              _SettingsTile(
                icon: Icons.map_outlined,
                title: 'จัดการโซนโต๊ะ',
                subtitle: 'CRUD โซน เช่น ชั้น 1, ระเบียง, VIP',
                onTap: () => context.push('/settings/zones'),
              ),
              SizedBox(height: 8.h),
              _SettingsTile(
                icon: Icons.backup_outlined,
                title: 'สำรองข้อมูล',
                subtitle: 'สร้างและตรวจสอบไฟล์สำรองข้อมูล',
                onTap: () => context.push('/settings/backup'),
              ),
              SizedBox(height: 8.h),
              _SettingsTile(
                icon: Icons.file_upload_outlined,
                title: 'นำเข้าข้อมูล',
                subtitle: 'อัปโหลด CSV เพื่อเติมข้อมูลสินค้า',
                onTap: () => context.push('/settings/import'),
              ),
              SizedBox(height: 8.h),
              _SettingsTile(
                icon: Icons.file_download_outlined,
                title: 'ส่งออกข้อมูล',
                subtitle: 'ดาวน์โหลดข้อมูลสินค้าและสมาชิกเป็น CSV',
                onTap: () => context.push('/settings/export'),
              ),
              SizedBox(height: 8.h),
              _SettingsTile(
                icon: Icons.monitor_outlined,
                title: 'จอลูกค้า',
                subtitle: 'เปิดหน้าจอแสดงผลฝั่งลูกค้า',
                onTap: () => context.push('/customer-display'),
              ),
              SizedBox(height: 8.h),
              _SettingsTile(
                icon: Icons.qr_code_2_outlined,
                title: 'QR Menu',
                subtitle: qrMenuLinkAsync.maybeWhen(
                  data: (value) => value == null
                      ? 'ยังไม่มี tenant slug สำหรับสร้างลิงก์เมนู'
                      : 'สร้าง QR ให้ลูกค้าเปิดเมนูร้านนี้',
                  orElse: () => 'กำลังเตรียมลิงก์เมนูสาธารณะ',
                ),
                trailing: qrMenuLinkAsync.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: qrMenuLinkAsync.maybeWhen(
                  data: (value) => value == null
                      ? null
                      : () => context.push(
                            '/qr-menu?url=${Uri.encodeComponent(value.menuUrl)}&name=${Uri.encodeComponent(value.tenantName)}',
                          ),
                  orElse: () => null,
                ),
              ),
              if (isSuperAdmin) ...[
                SizedBox(height: 24.h),
                _SectionHeader(title: 'ระบบส่วนกลาง'),
                _SettingsTile(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'ภาพรวมระบบ',
                  subtitle: 'ดูสถิติรวมของ tenant, users และ orders',
                  onTap: () => context.push('/admin/dashboard'),
                ),
                SizedBox(height: 8.h),
                _SettingsTile(
                  icon: Icons.apartment_outlined,
                  title: 'จัดการ Tenant',
                  subtitle: 'เปิด/ปิดการใช้งาน tenant และตรวจสอบสถานะ',
                  onTap: () => context.push('/admin/tenants'),
                ),
                SizedBox(height: 8.h),
                _SettingsTile(
                  icon: Icons.workspace_premium_outlined,
                  title: 'จัดการแพ็กเกจ',
                  subtitle: 'สร้างและปิดใช้งาน subscription plans',
                  onTap: () => context.push('/admin/plans'),
                ),
              ],
              SizedBox(height: 32.h),
              FilledButton(
                onPressed: _saving ? null : () => _save(data.settings),
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('บันทึก'),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tax Rates Tab
// ─────────────────────────────────────────────────────────────────────────────
class _TaxRatesTab extends ConsumerWidget {
  const _TaxRatesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(settingsDataProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (data) => ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          if (data.taxRates.isEmpty)
            Card(
              child: Padding(
                padding: EdgeInsets.all(24.h),
                child: const Center(
                    child: Text('ยังไม่มีอัตราภาษี',
                        style: TextStyle(color: Colors.black54))),
              ),
            )
          else
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.taxRates.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (context, i) {
                  final t = data.taxRates[i];
                  return ListTile(
                    title: Text(t.name),
                    subtitle: Text('${t.rate}%'),
                    trailing: t.isDefault
                        ? Chip(
                            label: const Text('ค่าเริ่มต้น',
                                style: TextStyle(fontSize: 11)),
                            backgroundColor: Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.15),
                            side: BorderSide.none,
                          )
                        : null,
                  );
                },
              ),
            ),
          SizedBox(height: 16.h),
          OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('เพิ่มอัตราภาษี'),
            onPressed: () => _showAddTaxDialog(context, ref),
          ),
        ],
      ),
    );
  }

  void _showAddTaxDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final rateCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('เพิ่มอัตราภาษี'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'ชื่อ'),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: rateCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'อัตรา (%)', suffixText: '%'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก')),
          FilledButton(
            onPressed: () async {
              final rate = double.tryParse(rateCtrl.text);
              if (nameCtrl.text.isNotEmpty && rate != null) {
                try {
                  await ref.read(settingsRepositoryProvider).createTaxRate(
                    name: nameCtrl.text,
                    rate: rate,
                  );
                  ref.invalidate(settingsDataProvider);
                } catch (_) {}
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Users Tab (quick nav to users page)
// ─────────────────────────────────────────────────────────────────────────────
class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        _SettingsTile(
          icon: Icons.manage_accounts_outlined,
          title: 'จัดการผู้ใช้งาน',
          subtitle: 'เพิ่ม ลบ แก้ไข กำหนดสิทธิ์',
          onTap: () => context.push('/settings/users'),
        ),
        _SettingsTile(
          icon: Icons.pin_outlined,
          title: 'ตั้ง PIN ของฉัน',
          subtitle: 'เปลี่ยน PIN สำหรับเข้าสู่ระบบด่วน',
          onTap: () => context.push('/settings/users'),
        ),
        _SettingsTile(
          icon: Icons.lock_outline,
          title: 'เปลี่ยนรหัสผ่านของฉัน',
          subtitle: 'เปลี่ยนรหัสผ่านบัญชีปัจจุบัน',
          onTap: () => context.push('/settings/users'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme / Language Tab
// ─────────────────────────────────────────────────────────────────────────────
final _themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);
final _localeProvider = StateProvider<String>((ref) => 'th');

class _ThemeLanguageTab extends ConsumerWidget {
  const _ThemeLanguageTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(_themeModeProvider);
    final locale = ref.watch(_localeProvider);

    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        _SectionHeader(title: 'ธีม'),
        Card(
          child: Column(
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('สว่าง'),
                secondary: const Icon(Icons.light_mode_outlined),
                value: ThemeMode.light,
                groupValue: themeMode,
                onChanged: (v) =>
                    ref.read(_themeModeProvider.notifier).state =
                        v ?? ThemeMode.light,
              ),
              RadioListTile<ThemeMode>(
                title: const Text('มืด'),
                secondary: const Icon(Icons.dark_mode_outlined),
                value: ThemeMode.dark,
                groupValue: themeMode,
                onChanged: (v) =>
                    ref.read(_themeModeProvider.notifier).state =
                        v ?? ThemeMode.light,
              ),
              RadioListTile<ThemeMode>(
                title: const Text('ตามระบบ'),
                secondary: const Icon(Icons.brightness_auto_outlined),
                value: ThemeMode.system,
                groupValue: themeMode,
                onChanged: (v) =>
                    ref.read(_themeModeProvider.notifier).state =
                        v ?? ThemeMode.light,
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),
        _SectionHeader(title: 'ภาษา'),
        Card(
          child: Column(
            children: [
              RadioListTile<String>(
                title: const Text('ภาษาไทย'),
                secondary: const Text('🇹🇭', style: TextStyle(fontSize: 22)),
                value: 'th',
                groupValue: locale,
                onChanged: (v) =>
                    ref.read(_localeProvider.notifier).state = v ?? 'th',
              ),
              RadioListTile<String>(
                title: const Text('English'),
                secondary: const Text('🇺🇸', style: TextStyle(fontSize: 22)),
                value: 'en',
                groupValue: locale,
                onChanged: (v) =>
                    ref.read(_localeProvider.notifier).state = v ?? 'th',
              ),
              RadioListTile<String>(
                title: const Text('ພາສາລາວ'),
                secondary: const Text('🇱🇦', style: TextStyle(fontSize: 22)),
                value: 'lo',
                groupValue: locale,
                onChanged: (v) =>
                    ref.read(_localeProvider.notifier).state = v ?? 'th',
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),
        _SectionHeader(title: 'อื่นๆ'),
        _SettingsTile(
          icon: Icons.timer_outlined,
          title: 'ล็อกอัตโนมัติ',
          subtitle: 'ออกจากระบบเมื่อไม่มีการใช้งาน',
          trailing: DropdownButton<int>(
            value: 15,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 0, child: Text('ปิด')),
              DropdownMenuItem(value: 5, child: Text('5 นาที')),
              DropdownMenuItem(value: 10, child: Text('10 นาที')),
              DropdownMenuItem(value: 15, child: Text('15 นาที')),
              DropdownMenuItem(value: 30, child: Text('30 นาที')),
            ],
            onChanged: (_) {},
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable settings tile
// ─────────────────────────────────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20.sp),
        ),
        title: Text(title, style: TextStyle(fontSize: 13.sp)),
        subtitle: subtitle != null
            ? Text(subtitle!,
                style: TextStyle(fontSize: 11.sp, color: Colors.black45))
            : null,
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

