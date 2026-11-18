import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/invoice_model.dart';
import '../models/order_model.dart';
import '../models/table_model.dart';
import '../providers/table_provider.dart';
import '../services/firebase_service.dart';
import 'table_map_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.table, required this.order});
  final RestaurantTable table;
  final Order order;
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod method = PaymentMethod.cash;
  bool saving = false;
  Future<void> confirm() async {
    final service = context.read<FirebaseService>();
    final tableProvider = context.read<TableProvider>();
    setState(() => saving = true);
    final invoice = Invoice(
      id: 'invoice_${DateTime.now().millisecondsSinceEpoch}',
      orderId: widget.order.id,
      tableId: widget.table.id,
      total: widget.order.total,
      method: method,
      employeeId: widget.order.employeeId,
      paidAt: DateTime.now(),
    );
    try {
      await service.saveInvoiceAndReleaseTable(invoice);
    } catch (_) {
      tableProvider.updateLocal(
        widget.table.copyWith(
          status: TableStatus.available,
          clearOrderId: true,
        ),
      );
    }
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const TableMapScreen()),
      (_) => false,
    );
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Thanh toán thành công')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thanh toán',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tổng thanh toán',
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  '${formatCurrency(widget.order.total)} đ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Phương thức thanh toán',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _Option(
            title: 'Tiền mặt',
            icon: Icons.payments_outlined,
            selected: method == PaymentMethod.cash,
            onTap: () => setState(() => method = PaymentMethod.cash),
          ),
          _Option(
            title: 'Chuyển khoản',
            icon: Icons.account_balance_outlined,
            selected: method == PaymentMethod.bankTransfer,
            onTap: () => setState(() => method = PaymentMethod.bankTransfer),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: saving ? null : confirm,
              icon: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(saving ? 'ĐANG XỬ LÝ...' : 'XÁC NHẬN THANH TOÁN'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withValues(alpha: .08)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: selected ? AppColors.primary : AppColors.muted),
          const SizedBox(width: 12),
          Text(title),
          const Spacer(),
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? AppColors.primary : AppColors.muted,
          ),
        ],
      ),
    ),
  );
}
