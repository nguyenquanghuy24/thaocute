import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/order_model.dart';
import '../services/firebase_service.dart';

class OrderProvider extends ChangeNotifier {
  OrderProvider(this.service);
  final FirebaseService service;
  final Map<String, Order> ordersByTable = {};
  Future<Order?> getForTable(String tableId, String? orderId) async {
    if (ordersByTable.containsKey(tableId)) return ordersByTable[tableId];
    if (orderId == null) return null;
    try {
      final snapshot = await service.orders.doc(orderId).get();
      if (!snapshot.exists) return null;
      final order = Order.fromMap(snapshot.id, snapshot.data()!);
      ordersByTable[tableId] = order;
      notifyListeners();
      return order;
    } catch (_) {
      return null;
    }
  }

  Future<Order> create(
    String tableId,
    List<OrderLine> lines,
    String employeeId,
  ) async {
    try {
      final order = await service.createOrderForTable(
        tableId: tableId,
        lines: lines,
        employeeId: employeeId,
      );
      ordersByTable[tableId] = order;
      notifyListeners();
      return order;
    } catch (_) {
      if (Firebase.apps.isNotEmpty) rethrow;
      final fallback = Order(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        tableId: tableId,
        lines: lines,
        employeeId: employeeId,
        createdAt: DateTime.now(),
      );
      ordersByTable[tableId] = fallback;
      notifyListeners();
      return fallback;
    }
  }

  Future<Order> addLines(Order order, List<OrderLine> incoming) async {
    var result = order;
    try {
      final updated = await service.appendLinesToOrder(order, incoming);
      ordersByTable[order.tableId] = updated;
      result = updated;
    } catch (_) {
      if (Firebase.apps.isNotEmpty) rethrow;
      for (final newLine in incoming) {
        final old = order.lines
            .where((line) => line.foodId == newLine.foodId)
            .firstOrNull;
        if (old == null) {
          order.lines.add(newLine);
        } else {
          old.quantity += newLine.quantity;
          if (newLine.note.isNotEmpty) old.note = newLine.note;
        }
      }
      ordersByTable[order.tableId] = order;
    }
    notifyListeners();
    return result;
  }

  Future<void> save(Order order) async {
    try {
      await service.updateOrder(order);
    } catch (_) {}
    notifyListeners();
  }

  void removeLine(Order order, OrderLine line) {
    order.lines.remove(line);
    notifyListeners();
  }
}
