import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../main.dart';
import '../models/food_model.dart';
import '../models/order_model.dart';
import '../models/table_model.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../providers/table_provider.dart';
import 'order_detail_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key, required this.table, this.existingOrder});
  final RestaurantTable table;
  final Order? existingOrder;
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final cart = <String, OrderLine>{};
  String category = 'Tất cả';
  String search = '';
  bool submitting = false;
  List<Food> get visibleFoods => sampleFoods
      .where(
        (f) =>
            (category == 'Tất cả' || f.category == category) &&
            f.name.toLowerCase().contains(search.toLowerCase()),
      )
      .toList();
  int get total => cart.values.fold(0, (sum, line) => sum + line.total);
  void add(Food food) {
    setState(() {
      final line = cart[food.id];
      if (line == null) {
        cart[food.id] = OrderLine.fromFood(food);
      } else {
        line.quantity++;
      }
    });
  }

  void minus(Food food) {
    setState(() {
      final line = cart[food.id];
      if (line == null) return;
      if (line.quantity == 1) {
        cart.remove(food.id);
      } else {
        line.quantity--;
      }
    });
  }

  Future<void> note(Food food) async {
    final controller = TextEditingController(text: cart[food.id]?.note);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(food.name),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Ghi chú món'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('HỦY'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('LƯU'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null && cart[food.id] != null) {
      setState(() => cart[food.id]!.note = result);
    }
  }

  Future<void> submit() async {
    if (cart.isEmpty || submitting) return;
    setState(() => submitting = true);
    final orders = context.read<OrderProvider>();
    try {
      final current =
          widget.existingOrder ??
          await orders.getForTable(
            widget.table.id,
            widget.table.currentOrderId,
          );
      if (!mounted) return;
      final employeeId = context.read<AuthProvider>().employee?.id ?? 'demo';
      if (current == null) {
        final order = await orders.create(
          widget.table.id,
          cart.values.map((e) => e.clone()).toList(),
          employeeId,
        );
        if (!mounted) return;
        final table = widget.table.copyWith(
          status: TableStatus.occupied,
          currentOrderId: order.id,
        );
        context.read<TableProvider>().updateLocal(table);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(table: table, order: order),
          ),
        );
      } else {
        final updated = await orders.addLines(
          current,
          cart.values.map((e) => e.clone()).toList(),
        );
        if (mounted) Navigator.pop(context, updated);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Khong the them mon: $error')));
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = [
      'Tất cả',
      ...sampleFoods.map((e) => e.category).toSet(),
    ];
    final count = cart.values.fold(0, (sum, line) => sum + line.quantity);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.table.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          Badge(
            label: Text('${cart.length}'),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.shopping_bag_outlined),
            ),
          ),
        ],
      ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$count món',
                            style: const TextStyle(color: AppColors.muted),
                          ),
                          Text(
                            '${formatCurrency(total)} đ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: submitting ? null : submit,
                      child: const Text('XÁC NHẬN'),
                    ),
                  ],
                ),
              ),
            ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            onChanged: (value) => setState(() => search = value),
            decoration: const InputDecoration(
              hintText: 'Tìm món ăn...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final item in categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(item),
                      selected: category == item,
                      onSelected: (_) => setState(() => category = item),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          for (final food in visibleFoods)
            _FoodCard(
              food: food,
              quantity: cart[food.id]?.quantity ?? 0,
              onAdd: () => add(food),
              onMinus: () => minus(food),
              onNote: () => note(food),
            ),
        ],
      ),
    );
  }
}

class _FoodCard extends StatelessWidget {
  const _FoodCard({
    required this.food,
    required this.quantity,
    required this.onAdd,
    required this.onMinus,
    required this.onNote,
  });
  final Food food;
  final int quantity;
  final VoidCallback onAdd, onMinus, onNote;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.restaurant, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                food.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                food.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
              Text(
                '${formatCurrency(food.price)} đ',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: quantity == 0 ? null : onMinus,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('$quantity'),
                  IconButton(
                    onPressed: onAdd,
                    icon: const Icon(
                      Icons.add_circle,
                      color: AppColors.primary,
                    ),
                  ),
                  IconButton(
                    onPressed: quantity == 0 ? null : onNote,
                    icon: const Icon(Icons.edit_note_outlined),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
