import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/currency_formatter.dart';
import '../models/order_model.dart';
import '../models/table_model.dart';
import '../providers/order_provider.dart';
import 'menu_screen.dart';
import 'payment_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({
    super.key,
    required this.table,
    required this.order,
  });
  final RestaurantTable table;
  final Order order;
  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Order draft;
  @override
  void initState() {
    super.initState();
    draft = widget.order.clone();
  }

  void adjust(OrderLine line, int amount) {
    setState(() {
      line.quantity += amount;
      if (line.quantity <= 0) draft.lines.remove(line);
    });
  }

  Future<void> remove(OrderLine line) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hủy món?'),
        content: Text('Bạn muốn hủy ${line.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('GIỮ LẠI'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('HỦY MÓN'),
          ),
        ],
      ),
    );
    if (result == true) setState(() => draft.lines.remove(line));
  }

  Future<void> save() async {
    await context.read<OrderProvider>().save(draft);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final itemWidgets = <Widget>[];
    for (final line in draft.lines) {
      itemWidgets.add(
        _OrderLine(
          line: line,
          onMinus: () => adjust(line, -1),
          onPlus: () => adjust(line, 1),
          onDelete: () => remove(line),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.table.name),
        actions: [TextButton(onPressed: save, child: const Text('LƯU'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Tổng tạm tính', style: Theme.of(context).textTheme.bodySmall),
          Text(
            '${formatCurrency(draft.total)} đ',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          ...itemWidgets,
          OutlinedButton.icon(
            onPressed: () async {
              final updated = await Navigator.push<Order>(
                context,
                MaterialPageRoute(
                  builder: (_) => MenuScreen(
                    table: widget.table,
                    existingOrder: widget.order,
                  ),
                ),
              );
              if (updated != null && mounted) {
                setState(() => draft = updated.clone());
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('THÊM MÓN'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: draft.lines.isEmpty
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PaymentScreen(table: widget.table, order: draft),
                    ),
                  ),
            icon: const Icon(Icons.receipt_long),
            label: const Text('IN HÓA ĐƠN / THANH TOÁN'),
          ),
        ],
      ),
    );
  }
}

class _OrderLine extends StatelessWidget {
  const _OrderLine({
    required this.line,
    required this.onMinus,
    required this.onPlus,
    required this.onDelete,
  });
  final OrderLine line;
  final VoidCallback onMinus, onPlus, onDelete;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (line.note.isNotEmpty) Text(line.note),
                Text('${formatCurrency(line.total)} đ'),
              ],
            ),
          ),
          IconButton(
            onPressed: onMinus,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text('${line.quantity}'),
          IconButton(
            onPressed: onPlus,
            icon: const Icon(Icons.add_circle_outline),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    ),
  );
}
