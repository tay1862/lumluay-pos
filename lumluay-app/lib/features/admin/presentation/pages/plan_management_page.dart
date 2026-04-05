import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../admin/data/admin_repository.dart';

class PlanManagementPage extends ConsumerWidget {
  const PlanManagementPage({super.key});

  static const routePath = '/admin/plans';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(adminPlansProvider);
    final repo = ref.read(adminRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Plans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showPlanDialog(context, ref),
            tooltip: 'Add Plan',
          ),
        ],
      ),
      body: plansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (plans) => RefreshIndicator(
          onRefresh: () => ref.refresh(adminPlansProvider.future),
          child: ListView.builder(
            padding: EdgeInsets.all(8.r),
            itemCount: plans.length,
            itemBuilder: (_, i) {
              final plan = plans[i];
              return Card(
                child: ListTile(
                  title: Text(plan.name),
                  subtitle: Text(
                    '₭${plan.monthlyPrice.toStringAsFixed(0)}/month'
                    '${plan.yearlyPrice != null ? " · ₭${plan.yearlyPrice!.toStringAsFixed(0)}/year" : ""}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        plan.isActive ? Icons.check_circle : Icons.cancel,
                        color: plan.isActive ? Colors.green : Colors.red,
                        size: 20.r,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        tooltip: 'Deactivate plan',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Deactivate Plan?'),
                              content: Text(
                                  'Are you sure you want to deactivate "${plan.name}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  child: const Text('Deactivate'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await repo.deletePlan(plan.id);
                            ref.invalidate(adminPlansProvider);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showPlanDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final slugCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: slugCtrl,
              decoration: const InputDecoration(labelText: 'Slug'),
            ),
            TextField(
              controller: priceCtrl,
              decoration: const InputDecoration(labelText: 'Monthly Price'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final repo = ref.read(adminRepositoryProvider);
              await repo.createPlan(
                name: nameCtrl.text,
                slug: slugCtrl.text,
                monthlyPrice: double.tryParse(priceCtrl.text) ?? 0,
              );
              ref.invalidate(adminPlansProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
