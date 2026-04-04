import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../data/users_repository.dart';
import '../../../../core/theme/app_theme.dart';

class UsersPage extends ConsumerWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(title: const Text('จัดการผู้ใช้')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserDialog(context, ref),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('เพิ่มผู้ใช้'),
        backgroundColor: AppColors.primary,
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
        data: (users) {
          if (users.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.black26),
                  SizedBox(height: 12),
                  Text('ยังไม่มีผู้ใช้งาน',
                      style: TextStyle(color: Colors.black45)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(usersListProvider),
            child: ListView.separated(
              padding: EdgeInsets.all(12.w),
              itemCount: users.length,
              separatorBuilder: (_, __) => SizedBox(height: 8.h),
              itemBuilder: (ctx, i) => _UserCard(user: users[i]),
            ),
          );
        },
      ),
    );
  }

  void _showUserDialog(BuildContext context, WidgetRef ref,
      {AppUser? existing}) {
    showDialog(
      context: context,
      builder: (_) => _UserFormDialog(existing: existing, ref: ref),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// User card
// ─────────────────────────────────────────────────────────────────────────────
class _UserCard extends ConsumerWidget {
  const _UserCard({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFmt = DateFormat('d MMM y', 'th_TH');

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 46.w,
            height: 46.w,
            decoration: BoxDecoration(
              color: _roleColor(user.role).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Center(
              child: Text(
                user.displayName.isNotEmpty
                    ? user.displayName[0].toUpperCase()
                    : 'U',
                style: TextStyle(
                    color: _roleColor(user.role),
                    fontWeight: FontWeight.w700,
                    fontSize: 18.sp),
              ),
            ),
          ),
          SizedBox(width: 12.w),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(user.displayName,
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14.sp)),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: _roleColor(user.role).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        _roleName(user.role),
                        style: TextStyle(
                            fontSize: 10.sp,
                            color: _roleColor(user.role),
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (!user.isActive)
                      Container(
                        margin: EdgeInsets.only(left: 6.w),
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text('ปิดใช้งาน',
                            style: TextStyle(
                                fontSize: 9.sp,
                                color: Colors.grey.shade600)),
                      ),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  '@${user.username}${user.createdAt != null ? ' · ${dateFmt.format(user.createdAt!)}' : ''}',
                  style: TextStyle(fontSize: 11.sp, color: Colors.black45),
                ),
              ],
            ),
          ),

          // Actions
          PopupMenuButton<String>(
            onSelected: (v) => _onAction(context, ref, v),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  Icon(Icons.edit_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('แก้ไข'),
                ]),
              ),
              const PopupMenuItem(
                value: 'pin',
                child: Row(children: [
                  Icon(Icons.pin_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('ตั้ง PIN'),
                ]),
              ),
              const PopupMenuItem(
                value: 'password',
                child: Row(children: [
                  Icon(Icons.lock_outline, size: 18),
                  SizedBox(width: 8),
                  Text('เปลี่ยนรหัสผ่าน'),
                ]),
              ),
              PopupMenuItem(
                value: user.isActive ? 'deactivate' : 'activate',
                child: Row(children: [
                  Icon(
                    user.isActive ? Icons.block : Icons.check_circle_outline,
                    size: 18,
                    color: user.isActive ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(user.isActive ? 'ระงับการใช้งาน' : 'เปิดใช้งาน'),
                ]),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('ลบผู้ใช้', style: TextStyle(color: Colors.red)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onAction(BuildContext context, WidgetRef ref, String action) async {
    switch (action) {
      case 'edit':
        showDialog(
          context: context,
          builder: (_) => _UserFormDialog(existing: user, ref: ref),
        );
      case 'pin':
        showDialog(
          context: context,
          builder: (_) => _SetPinDialog(userId: user.id, ref: ref),
        );
      case 'password':
        showDialog(
          context: context,
          builder: (_) => _ChangePasswordDialog(userId: user.id, ref: ref),
        );
      case 'deactivate':
      case 'activate':
        await ref
            .read(usersRepositoryProvider)
            .updateUser(user.id, {'isActive': action == 'activate'});
        ref.invalidate(usersListProvider);
      case 'delete':
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('ยืนยันการลบ'),
            content: Text('ต้องการลบผู้ใช้ "${user.displayName}" ?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('ยกเลิก')),
              FilledButton(
                style:
                    FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('ลบ'),
              ),
            ],
          ),
        );
        if (ok == true) {
          await ref.read(usersRepositoryProvider).deleteUser(user.id);
          ref.invalidate(usersListProvider);
        }
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'owner':
        return Colors.purple;
      case 'manager':
        return Colors.indigo;
      case 'cashier':
        return AppColors.primary;
      case 'waiter':
        return Colors.teal;
      case 'kitchen':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _roleName(String role) {
    switch (role) {
      case 'owner':
        return 'เจ้าของ';
      case 'manager':
        return 'ผู้จัดการ';
      case 'cashier':
        return 'แคชเชียร์';
      case 'waiter':
        return 'พนักงาน';
      case 'kitchen':
        return 'ครัว';
      default:
        return role;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// User form dialog (create / edit)
// ─────────────────────────────────────────────────────────────────────────────
class _UserFormDialog extends ConsumerStatefulWidget {
  const _UserFormDialog({this.existing, required this.ref});
  final AppUser? existing;
  final WidgetRef ref;

  @override
  ConsumerState<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends ConsumerState<_UserFormDialog> {
  final _usernameCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _role = 'cashier';
  bool _isActive = true;
  bool _loading = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _usernameCtrl.text = widget.existing!.username;
      _displayNameCtrl.text = widget.existing!.displayName;
      _role = widget.existing!.role;
      _isActive = widget.existing!.isActive;
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _displayNameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(usersRepositoryProvider);
      final body = <String, dynamic>{
        'username': _usernameCtrl.text.trim(),
        'displayName': _displayNameCtrl.text.trim(),
        'role': _role,
        'isActive': _isActive,
        if (!_isEdit && _passwordCtrl.text.isNotEmpty)
          'password': _passwordCtrl.text,
      };
      if (_isEdit) {
        await repo.updateUser(widget.existing!.id, body);
      } else {
        await repo.createUser(body);
      }
      ref.invalidate(usersListProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'แก้ไขผู้ใช้' : 'เพิ่มผู้ใช้ใหม่'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _displayNameCtrl,
              decoration: const InputDecoration(
                  labelText: 'ชื่อแสดง *',
                  border: OutlineInputBorder()),
            ),
            SizedBox(height: 10.h),
            TextField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(
                  labelText: 'ชื่อผู้ใช้ *',
                  border: OutlineInputBorder()),
              readOnly: _isEdit,
            ),
            if (!_isEdit) ...[
              SizedBox(height: 10.h),
              TextField(
                controller: _passwordCtrl,
                decoration: const InputDecoration(
                    labelText: 'รหัสผ่าน *',
                    border: OutlineInputBorder()),
                obscureText: true,
              ),
            ],
            SizedBox(height: 10.h),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(
                  labelText: 'ตำแหน่ง',
                  border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'owner', child: Text('เจ้าของ')),
                DropdownMenuItem(
                    value: 'manager', child: Text('ผู้จัดการ')),
                DropdownMenuItem(
                    value: 'cashier', child: Text('แคชเชียร์')),
                DropdownMenuItem(
                    value: 'waiter', child: Text('พนักงาน')),
                DropdownMenuItem(value: 'kitchen', child: Text('ครัว')),
              ],
              onChanged: (v) => setState(() => _role = v ?? 'cashier'),
            ),
            SizedBox(height: 8.h),
            SwitchListTile.adaptive(
              title: const Text('เปิดใช้งาน'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก')),
        FilledButton(
          onPressed: _loading ? null : _save,
          style:
              FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: _loading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text('บันทึก'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Set PIN dialog
// ─────────────────────────────────────────────────────────────────────────────
class _SetPinDialog extends ConsumerStatefulWidget {
  const _SetPinDialog({required this.userId, required this.ref});
  final String userId;
  final WidgetRef ref;

  @override
  ConsumerState<_SetPinDialog> createState() => _SetPinDialogState();
}

class _SetPinDialogState extends ConsumerState<_SetPinDialog> {
  final _pinCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_pinCtrl.text.length < 4) return;
    setState(() => _loading = true);
    try {
      await ref.read(usersRepositoryProvider).setPin(widget.userId, _pinCtrl.text);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ตั้ง PIN สำเร็จแล้ว')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ตั้ง PIN'),
      content: TextField(
        controller: _pinCtrl,
        decoration: const InputDecoration(
            labelText: 'PIN (4-6 หลัก)',
            border: OutlineInputBorder()),
        obscureText: true,
        keyboardType: TextInputType.number,
        maxLength: 6,
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก')),
        FilledButton(
          onPressed: _loading ? null : _save,
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('บันทึก'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Change password dialog
// ─────────────────────────────────────────────────────────────────────────────
class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog({required this.userId, required this.ref});
  final String userId;
  final WidgetRef ref;

  @override
  ConsumerState<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState
    extends ConsumerState<_ChangePasswordDialog> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_newCtrl.text.length < 6) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(usersRepositoryProvider)
          .changePassword(widget.userId, _currentCtrl.text, _newCtrl.text);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('เปลี่ยนรหัสผ่านสำเร็จ')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('เปลี่ยนรหัสผ่าน'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _currentCtrl,
            decoration: const InputDecoration(
                labelText: 'รหัสผ่านปัจจุบัน',
                border: OutlineInputBorder()),
            obscureText: true,
          ),
          SizedBox(height: 10.h),
          TextField(
            controller: _newCtrl,
            decoration: const InputDecoration(
                labelText: 'รหัสผ่านใหม่ (อย่างน้อย 6 ตัว)',
                border: OutlineInputBorder()),
            obscureText: true,
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก')),
        FilledButton(
          onPressed: _loading ? null : _save,
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('บันทึก'),
        ),
      ],
    );
  }
}
