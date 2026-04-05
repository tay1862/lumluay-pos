import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/services/auto_lock_service.dart';

class AutoLockSettingsPage extends ConsumerWidget {
  const AutoLockSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMinutes = ref.watch(autoLockMinutesProvider);
    final theme = Theme.of(context);

    const options = [
      (0, 'ປິດ', 'ບໍ່ລັອກອັດຕະໂນມັດ'),
      (5, '5 ນາທີ', 'ລັອກຫຼັງບໍ່ມີການໃຊ້ງານ 5 ນາທີ'),
      (10, '10 ນາທີ', 'ລັອກຫຼັງບໍ່ມີການໃຊ້ງານ 10 ນາທີ'),
      (15, '15 ນາທີ', 'ລັອກຫຼັງບໍ່ມີການໃຊ້ງານ 15 ນາທີ'),
      (30, '30 ນາທີ', 'ລັອກຫຼັງບໍ່ມີການໃຊ້ງານ 30 ນາທີ'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('ການລັອກອັດຕະໂນມັດ')),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // ── Info banner ───────────────────────────────────────────
          Card(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_clock_outlined,
                      color: theme.colorScheme.primary, size: 20.sp),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'ເມື່ອບໍ່ມີການໃຊ້ງານຕາມເວລາທີ່ກຳນົດ ແອັບຈະລັອກແລະຕ້ອງໃສ່ PIN ເພື່ອເຂົ້າໃຊ້ງານອີກຄັ້ງ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // ── Options ───────────────────────────────────────────────
          Text('ລະຍະເວລາລັອກ', style: theme.textTheme.titleSmall),
          SizedBox(height: 8.h),
          Card(
            child: Column(
              children: options.asMap().entries.map((entry) {
                final i = entry.key;
                final opt = entry.value;
                final minutes = opt.$1;
                final label = opt.$2;
                final subtitle = opt.$3;
                final isSelected = minutes == currentMinutes;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (i > 0) const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        minutes == 0
                            ? Icons.lock_open_outlined
                            : Icons.lock_clock_outlined,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      title: Text(
                        label,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(subtitle),
                      trailing: isSelected
                          ? Icon(Icons.check_circle,
                              color: theme.colorScheme.primary)
                          : const Icon(Icons.radio_button_unchecked),
                      selected: isSelected,
                      onTap: () {
                        ref.read(autoLockMinutesProvider.notifier).state =
                            minutes;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              minutes == 0
                                  ? 'ປິດການລັອກອັດຕະໂນມັດແລ້ວ'
                                  : 'ຕັ້ງການລັອກອັດຕະໂນມັດ $label ແລ້ວ',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                );
              }).toList(),
            ),
          ),

          if (currentMinutes > 0) ...[
            SizedBox(height: 16.h),
            Card(
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined,
                        color: theme.colorScheme.secondary, size: 20.sp),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'ຈະລັອກອັດຕະໂນມັດຫຼັງບໍ່ມີການໃຊ້ງານ $currentMinutes ນາທີ',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
