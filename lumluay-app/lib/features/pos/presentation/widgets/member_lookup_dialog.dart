import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../members/data/members_repository.dart';
import '../../providers/cart_provider.dart';
class MemberLookupDialog extends ConsumerStatefulWidget {
  const MemberLookupDialog({super.key});

  @override
  ConsumerState<MemberLookupDialog> createState() =>
      _MemberLookupDialogState();
}

class _MemberLookupDialogState extends ConsumerState<MemberLookupDialog> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersListProvider);
    final cartMemberId = ref.watch(cartProvider).memberId;

    return Dialog(
      insetPadding: EdgeInsets.all(16.w),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 400.w, maxHeight: 520.h),
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 8.w, 8.h),
              child: Row(
                children: [
                  const Icon(Icons.person_search_outlined),
                  SizedBox(width: 8.w),
                  Text(
                    'ຄົ້ນຫາສະມາຊິກ',
                    style: TextStyle(
                        fontSize: 16.sp, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            // Search field
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'ຄົ້ນຫາຊື່ ຫຼືເບີໂທລ…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                            ref
                                .read(membersSearchProvider.notifier)
                                .state = '';
                          },
                        )
                      : null,
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r)),
                ),
                onChanged: (v) {
                  setState(() => _query = v);
                  ref.read(membersSearchProvider.notifier).state = v;
                },
              ),
            ),
            SizedBox(height: 8.h),

            // Current selection banner
            if (cartMemberId != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 16),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        'ຜູກກັບ: ${ref.watch(cartProvider).memberName ?? cartMemberId}',
                        style: TextStyle(
                            fontSize: 12.sp, color: Colors.green[700]),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(cartProvider.notifier).clearMember();
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          visualDensity: VisualDensity.compact),
                      child: const Text('ຍົກເລີກ'),
                    ),
                  ],
                ),
              ),

            const Divider(height: 1),

            // List
            Expanded(
              child: membersAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: Text('ເກີດຂໍ້ຜິດພາດ: $e')),
                data: (members) {
                  if (members.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_off_outlined,
                              size: 40.sp, color: Colors.grey[300]),
                          SizedBox(height: 8.h),
                          Text(
                            _query.isEmpty
                                ? 'ຍັງບໍ່ມີສະມາຊິກ'
                                : 'ບໍ່ພົບສະມາຊິກ "$_query"',
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 13.sp),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: members.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 56),
                    itemBuilder: (ctx, i) {
                      final m = members[i];
                      final isSelected = m.id == cartMemberId;
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 18.r,
                          backgroundColor: isSelected
                              ? Colors.green[100]
                              : Colors.grey[100],
                          child: Text(
                            m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                            style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.green
                                    : Colors.black54),
                          ),
                        ),
                        title: Text(m.name,
                            style:
                                TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
                        subtitle: m.phone != null
                            ? Text(m.phone!,
                                style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.black45))
                            : null,
                        trailing: isSelected
                            ? const Icon(Icons.check_circle,
                                color: Colors.green, size: 20)
                            : null,
                        onTap: () {
                          ref
                              .read(cartProvider.notifier)
                              .setMember(m.id, m.name);
                          Navigator.pop(context);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
