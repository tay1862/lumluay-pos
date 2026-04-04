import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../data/members_repository.dart';

class MembersPage extends ConsumerWidget {
  const MembersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(membersSearchProvider);
    final membersAsync = ref.watch(membersListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('สมาชิก'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () => _showMemberForm(context, ref, null),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(56.h),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            child: _SearchField(
              initial: search,
              onChanged: (v) =>
                  ref.read(membersSearchProvider.notifier).state = v,
            ),
          ),
        ),
      ),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (members) {
          if (members.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline,
                      size: 56.sp, color: Colors.black26),
                  SizedBox(height: 12.h),
                  Text(
                    search.isNotEmpty ? 'ไม่พบสมาชิก "$search"' : 'ยังไม่มีสมาชิก',
                    style:
                        const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            itemCount: members.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 72, endIndent: 16),
            itemBuilder: (ctx, i) => _MemberTile(
              member: members[i],
              onTap: () => _showMemberDetail(ctx, ref, members[i]),
              onEdit: () => _showMemberForm(ctx, ref, members[i]),
            ),
          );
        },
      ),
    );
  }

  void _showMemberDetail(
      BuildContext context, WidgetRef ref, Member member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
      builder: (_) => _MemberDetailSheet(
        member: member,
        onEdit: () {
          Navigator.pop(context);
          _showMemberForm(context, ref, member);
        },
        onDelete: () async {
          Navigator.pop(context);
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('ลบสมาชิก'),
              content:
                  Text('ต้องการลบ "${member.name}" ใช่หรือไม่?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('ยกเลิก')),
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: Colors.red),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('ลบ'),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            await ref.read(membersRepositoryProvider).deleteMember(member.id);
            ref.invalidate(membersListProvider);
          }
        },
      ),
    );
  }

  void _showMemberForm(
      BuildContext context, WidgetRef ref, Member? member) {
    showDialog(
      context: context,
      builder: (_) => _MemberFormDialog(member: member),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search field
// ─────────────────────────────────────────────────────────────────────────────
class _SearchField extends StatefulWidget {
  const _SearchField({required this.initial, required this.onChanged});
  final String initial;
  final ValueChanged<String> onChanged;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final _ctrl = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: _ctrl,
        decoration: InputDecoration(
          hintText: 'ค้นหาชื่อ / เบอร์โทร',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _ctrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _ctrl.clear();
                    widget.onChanged('');
                  })
              : null,
          isDense: true,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24.r)),
          contentPadding:
              EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
        ),
        onChanged: widget.onChanged,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Member tile
// ─────────────────────────────────────────────────────────────────────────────
class _MemberTile extends StatelessWidget {
  const _MemberTile(
      {required this.member,
      required this.onTap,
      required this.onEdit});
  final Member member;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final fmtMoney = NumberFormat('#,##0.00');
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.15),
        child: Text(
          member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
          style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w700),
        ),
      ),
      title: Text(member.name,
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
      subtitle: Text(
        member.phone ?? member.email ?? '',
        style: TextStyle(fontSize: 11.sp, color: Colors.black54),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('฿${fmtMoney.format(member.totalSpent)}',
              style: TextStyle(
                  fontSize: 13.sp, fontWeight: FontWeight.w700)),
          Text('${member.totalVisits} ครั้ง',
              style: TextStyle(fontSize: 10.sp, color: Colors.black45)),
        ],
      ),
      onTap: onTap,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Member detail bottom sheet
// ─────────────────────────────────────────────────────────────────────────────
class _MemberDetailSheet extends StatelessWidget {
  const _MemberDetailSheet(
      {required this.member,
      required this.onEdit,
      required this.onDelete});
  final Member member;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final fmtMoney = NumberFormat('#,##0.00');
    final dateFmt = DateFormat('d MMM yyyy');
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28.r,
                backgroundColor:
                    Theme.of(context).primaryColor.withValues(alpha: 0.15),
                child: Text(
                  member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                  style: TextStyle(
                      fontSize: 22.sp,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w700),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.name,
                        style: TextStyle(
                            fontSize: 18.sp, fontWeight: FontWeight.w700)),
                    if (member.phone != null)
                      Text(member.phone!,
                          style: TextStyle(
                              color: Colors.black54, fontSize: 13.sp)),
                    if (member.email != null)
                      Text(member.email!,
                          style: TextStyle(
                              color: Colors.black54, fontSize: 12.sp)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              _StatBox(
                  label: 'ยอดรวม',
                  value: '฿${fmtMoney.format(member.totalSpent)}'),
              SizedBox(width: 12.w),
              _StatBox(
                  label: 'จำนวนครั้ง',
                  value: '${member.totalVisits}'),
              SizedBox(width: 12.w),
              _StatBox(
                  label: 'สมาชิกตั้งแต่',
                  value: member.createdAt != null
                      ? dateFmt.format(member.createdAt!)
                      : '-'),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('แก้ไข'),
                  onPressed: onEdit,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('ลบ'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red),
                  onPressed: onDelete,
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 13.sp, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center),
              SizedBox(height: 2.h),
              Text(label,
                  style:
                      TextStyle(fontSize: 10.sp, color: Colors.black54),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Member form dialog (create / edit)
// ─────────────────────────────────────────────────────────────────────────────
class _MemberFormDialog extends ConsumerStatefulWidget {
  const _MemberFormDialog({this.member});
  final Member? member;

  @override
  ConsumerState<_MemberFormDialog> createState() =>
      _MemberFormDialogState();
}

class _MemberFormDialogState extends ConsumerState<_MemberFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl =
      TextEditingController(text: widget.member?.name ?? '');
  late final _phoneCtrl =
      TextEditingController(text: widget.member?.phone ?? '');
  late final _emailCtrl =
      TextEditingController(text: widget.member?.email ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = {
      'name': _nameCtrl.text.trim(),
      if (_phoneCtrl.text.trim().isNotEmpty) 'phone': _phoneCtrl.text.trim(),
      if (_emailCtrl.text.trim().isNotEmpty) 'email': _emailCtrl.text.trim(),
    };
    try {
      if (widget.member == null) {
        await ref.read(membersRepositoryProvider).createMember(data);
      } else {
        await ref
            .read(membersRepositoryProvider)
            .updateMember(widget.member!.id, data);
      }
      ref.invalidate(membersListProvider);
      if (mounted) Navigator.pop(context);
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
  Widget build(BuildContext context) => AlertDialog(
        title:
            Text(widget.member == null ? 'เพิ่มสมาชิก' : 'แก้ไขสมาชิก'),
        content: Form(
          key: _formKey,
          child: SizedBox(
            width: 320.w,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'ชื่อ *',
                      prefixIcon: Icon(Icons.person_outline)),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'กรอกชื่อ' : null,
                ),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'เบอร์โทร',
                      prefixIcon: Icon(Icons.phone_outlined)),
                ),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      labelText: 'อีเมล',
                      prefixIcon: Icon(Icons.email_outlined)),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก')),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('บันทึก'),
          ),
        ],
      );
}
