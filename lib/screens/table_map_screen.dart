import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../models/table_model.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../providers/table_provider.dart';
import 'login_screen.dart';
import 'menu_screen.dart';
import 'order_detail_screen.dart';

class TableMapScreen extends StatefulWidget {
  const TableMapScreen({super.key});
  @override
  State<TableMapScreen> createState() => _TableMapScreenState();
}

class _TableMapScreenState extends State<TableMapScreen> {
  String area = 'Tất cả';
  Future<void> open(RestaurantTable table) async {
    final order = await context.read<OrderProvider>().getForTable(
      table.id,
      table.currentOrderId,
    );
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => table.isOccupied && order != null
            ? OrderDetailScreen(table: table, order: order)
            : MenuScreen(table: table),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tables = context.watch<TableProvider>().tables;
    final visible = tables
        .where((t) => area == 'Tất cả' || t.area == area)
        .toList();
    final available = tables.where((t) => !t.isOccupied).length;
    final areas = ['Tất cả', ...tables.map((t) => t.area).toSet()];
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sơ đồ bàn',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: context.read<TableProvider>().load,
            icon: const Icon(Icons.refresh),
          ),
          PopupMenuButton<String>(
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'logout', child: Text('Đăng xuất')),
            ],
            onSelected: (value) async {
              if (value == 'logout') {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
      body: context.watch<TableProvider>().isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: context.read<TableProvider>().load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Xin chào, ${context.watch<AuthProvider>().employee?.name ?? 'nhân viên'}',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _Summary(
                        label: 'Bàn trống',
                        value: '$available',
                        color: AppColors.available,
                      ),
                      const SizedBox(width: 12),
                      _Summary(
                        label: 'Đang phục vụ',
                        value: '${tables.length - available}',
                        color: AppColors.occupied,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Khu vực',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final item in areas)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(item),
                              selected: area == item,
                              onSelected: (_) => setState(() => area = item),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Danh sách bàn',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        '${visible.length} bàn',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: visible.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.15,
                        ),
                    itemBuilder: (_, index) => _TableCard(
                      table: visible[index],
                      onTap: () => open(visible[index]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label, value;
  final Color color;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class _TableCard extends StatelessWidget {
  const _TableCard({required this.table, required this.onTap});
  final RestaurantTable table;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final color = table.isOccupied ? AppColors.occupied : AppColors.available;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: .3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.table_restaurant, color: color, size: 30),
              Text(
                table.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Text(
                table.isOccupied ? 'Đang phục vụ' : 'Bàn trống',
                style: TextStyle(color: color, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
