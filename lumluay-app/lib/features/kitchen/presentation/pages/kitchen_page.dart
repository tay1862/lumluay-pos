import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/kitchen_repository.dart';
import '../../domain/models/kitchen_order.dart';
import '../../../../core/services/websocket_service.dart';
import '../../../../core/services/sound_player_util.dart';
import '../widgets/kitchen_order_card.dart';

// Polling fallback every 30 seconds (WebSocket is primary)
final _kitchenAutoRefreshProvider = StreamProvider<int>((ref) {
  return Stream.periodic(const Duration(seconds: 30), (i) => i);
});

final _selectedStationProvider = StateProvider<String?>((ref) => null);

// ─────────────────────────────────────────────────────────────────────────────
// Kitchen page — KDS (Kitchen Display System)
// ─────────────────────────────────────────────────────────────────────────────
class KitchenPage extends ConsumerWidget {
  const KitchenPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final station = ref.watch(_selectedStationProvider);

    // 9.2.6 — WebSocket listener for real-time new orders
    ref.listen(kitchenWsProvider, (_, next) {
      next.whenData((event) {
        if (event is WsKitchenTicket) {
          // 9.2.7 — Play sound on new order arrival
          ref.read(soundPlayerProvider).play(AppSound.newOrder);
        }
        ref.invalidate(kitchenTicketsProvider(station));
      });
    });

    // Polling fallback
    ref.watch(_kitchenAutoRefreshProvider);

    final ticketsAsync = ref.watch(kitchenTicketsProvider(station));

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: Row(
          children: [
            const Icon(Icons.restaurant, color: Colors.orange),
            SizedBox(width: 8.w),
            Text(
              'Kitchen Display',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          _StationFilter(selected: station),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () => ref.invalidate(kitchenTicketsProvider(station)),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: ticketsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red[300], size: 48.sp),
              SizedBox(height: 12.h),
              Text(
                'ไม่สามารถโหลดข้อมูลได้',
                style: TextStyle(color: Colors.white60, fontSize: 14.sp),
              ),
              SizedBox(height: 8.h),
              FilledButton(
                onPressed: () => ref.invalidate(kitchenTicketsProvider(station)),
                child: const Text('ลองใหม่'),
              ),
            ],
          ),
        ),
        data: (tickets) {
          if (tickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      color: Colors.green[400], size: 64.sp),
                  SizedBox(height: 16.h),
                  Text(
                    'ไม่มีรายการรอ',
                    style: TextStyle(color: Colors.white60, fontSize: 18.sp),
                  ),
                ],
              ),
            );
          }

          final sorted = List<KitchenTicket>.from(tickets)
            ..sort((a, b) {
              if (a.status == 'preparing' && b.status != 'preparing') return -1;
              if (b.status == 'preparing' && a.status != 'preparing') return 1;
              return a.createdAt.compareTo(b.createdAt);
            });

          // 9.2.8 — Responsive layout: 1 col phone, 2 col tablet, 3-4 col desktop
          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = switch (width) {
                > 1200 => 4,
                > 800 => 3,
                > 500 => 2,
                _ => 1,
              };
              return GridView.builder(
                padding: EdgeInsets.all(12.w),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisExtent: 340.h,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                ),
                itemCount: sorted.length,
                itemBuilder: (context, i) =>
                    _KdsCard(ticket: sorted[i]),
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Station filter strip
// ─────────────────────────────────────────────────────────────────────────────
class _StationFilter extends ConsumerWidget {
  const _StationFilter({required this.selected});
  final String? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const stations = ['hot', 'cold', 'grill', 'bar', 'dessert'];
    return SizedBox(
      height: 40.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        children: [
          Padding(
            padding: EdgeInsets.only(right: 6.w),
            child: FilterChip(
              label: const Text('ทั้งหมด'),
              selected: selected == null,
              onSelected: (_) =>
                  ref.read(_selectedStationProvider.notifier).state = null,
              selectedColor: Colors.orange,
              labelStyle: TextStyle(
                color: selected == null ? Colors.white : Colors.white70,
                fontSize: 11.sp,
              ),
              showCheckmark: false,
            ),
          ),
          ...stations.map(
            (s) => Padding(
              padding: EdgeInsets.only(right: 6.w),
              child: FilterChip(
                label: Text(s),
                selected: selected == s,
                onSelected: (_) =>
                    ref.read(_selectedStationProvider.notifier).state = s,
                selectedColor: Colors.orange,
                labelStyle: TextStyle(
                  color: selected == s ? Colors.white : Colors.white70,
                  fontSize: 11.sp,
                ),
                showCheckmark: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card wrapper — adapts KitchenTicket (repo model) → KitchenOrderCard widget
// ─────────────────────────────────────────────────────────────────────────────
class _KdsCard extends ConsumerStatefulWidget {
  const _KdsCard({required this.ticket});
  final KitchenTicket ticket;

  @override
  ConsumerState<_KdsCard> createState() => _KdsCardState();
}

class _KdsCardState extends ConsumerState<_KdsCard> {
  bool _loading = false;

  KitchenOrder get _order => KitchenOrder(
        id: widget.ticket.id,
        orderReceiptNumber: widget.ticket.orderReceiptNumber,
        tableName: widget.ticket.tableName,
        status: _parseStatus(widget.ticket.status),
        station: widget.ticket.station,
        items: widget.ticket.items
            .map(
              (e) => KitchenOrderItem(
                quantity: (e['quantity'] as num?)?.toInt() ?? 1,
                productName: e['productName'] as String? ?? '',
                note: e['note'] as String?,
              ),
            )
            .toList(),
        createdAt: widget.ticket.createdAt,
        startedAt: widget.ticket.startedAt,
      );

  static KitchenStatus _parseStatus(String v) {
    return switch (v) {
      'preparing' => KitchenStatus.preparing,
      'ready' => KitchenStatus.ready,
      'served' => KitchenStatus.served,
      'cancelled' => KitchenStatus.cancelled,
      _ => KitchenStatus.pending,
    };
  }

  Future<void> _handleNext(String status) async {
    setState(() => _loading = true);
    try {
      await ref
          .read(kitchenRepositoryProvider)
          .updateStatus(widget.ticket.id, status);
      ref.invalidate(kitchenTicketsProvider);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KitchenOrderCard(
      order: _order,
      loading: _loading,
      onNextStatus: _handleNext,
    );
  }
}
