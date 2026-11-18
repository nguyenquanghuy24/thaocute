import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';

import '../models/employee_model.dart';
import '../models/food_model.dart';
import '../models/invoice_model.dart';
import '../models/order_model.dart';
import '../models/table_model.dart';

class FirebaseService {
  FirebaseService({this._firestore, this._auth});

  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;
  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;
  FirebaseAuth get auth => _auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get employees =>
      firestore.collection('employees');
  CollectionReference<Map<String, dynamic>> get tables =>
      firestore.collection('tables');
  CollectionReference<Map<String, dynamic>> get foods =>
      firestore.collection('foods');
  CollectionReference<Map<String, dynamic>> get orders =>
      firestore.collection('orders');
  CollectionReference<Map<String, dynamic>> get invoices =>
      firestore.collection('invoices');

  Future<Employee?> findEmployee(String code) async {
    final snapshot = await employees
        .where('employeeCode', isEqualTo: code.trim().toUpperCase())
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return Employee.fromMap(snapshot.docs.first.id, snapshot.docs.first.data());
  }

  Future<UserCredential> signIn(Employee employee, String password) => auth
      .signInWithEmailAndPassword(email: employee.email, password: password);

  Future<List<RestaurantTable>> fetchTables() async {
    final snapshot = await tables.orderBy('name').get();
    return snapshot.docs
        .map((doc) => RestaurantTable.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<List<Food>> fetchFoods() async {
    final snapshot = await foods.where('available', isEqualTo: true).get();
    return snapshot.docs
        .map((doc) => Food.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<Order> createOrderForTable({
    required String tableId,
    required List<OrderLine> lines,
    required String employeeId,
  }) async {
    final tableRef = tables.doc(tableId);
    final orderRef = orders.doc();
    final order = Order(
      id: orderRef.id,
      tableId: tableId,
      lines: lines,
      employeeId: employeeId,
      createdAt: DateTime.now(),
    );
    await firestore.runTransaction((transaction) async {
      final tableSnapshot = await transaction.get(tableRef);
      if (!tableSnapshot.exists) throw StateError('Không tìm thấy bàn.');
      final data = tableSnapshot.data() ?? <String, dynamic>{};
      if (data['status'] == TableStatus.occupied.name &&
          data['currentOrderId'] != null) {
        throw StateError('Bàn này vừa được nhân viên khác nhận.');
      }
      transaction.set(orderRef, {
        ...order.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(tableRef, {
        'status': TableStatus.occupied.name,
        'currentOrderId': order.id,
      });
    });
    return order;
  }

  Future<Order> appendLinesToOrder(
    Order order,
    List<OrderLine> incoming,
  ) async {
    final orderRef = orders.doc(order.id);
    Order updated = order.clone();
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(orderRef);
      if (!snapshot.exists) throw StateError('Không tìm thấy order.');
      final remote = Order.fromMap(snapshot.id, snapshot.data()!);
      for (final line in incoming) {
        final existing = remote.lines
            .where((item) => item.foodId == line.foodId)
            .firstOrNull;
        if (existing == null) {
          remote.lines.add(line.clone());
        } else {
          existing.quantity += line.quantity;
          if (line.note.isNotEmpty) existing.note = line.note;
        }
      }
      updated = remote;
      transaction.update(orderRef, {
        'lines': remote.lines.map((line) => line.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    return updated;
  }

  Future<void> updateOrder(Order order) => orders.doc(order.id).set({
    ...order.toMap(),
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  Future<void> saveInvoiceAndReleaseTable(Invoice invoice) async {
    final invoiceRef = invoices.doc(invoice.id);
    final orderRef = orders.doc(invoice.orderId);
    final tableRef = tables.doc(invoice.tableId);
    await firestore.runTransaction((transaction) async {
      final orderSnapshot = await transaction.get(orderRef);
      final tableSnapshot = await transaction.get(tableRef);
      if (!orderSnapshot.exists || !tableSnapshot.exists) {
        throw StateError('Không tìm thấy order hoặc bàn.');
      }
      final orderData = orderSnapshot.data()!;
      final tableData = tableSnapshot.data()!;
      if (orderData['status'] == OrderStatus.paid.name) {
        throw StateError('Order đã được thanh toán.');
      }
      if (tableData['currentOrderId'] != invoice.orderId) {
        throw StateError('Bàn không còn liên kết với order này.');
      }
      transaction.set(invoiceRef, invoice.toMap());
      transaction.update(orderRef, {
        'status': OrderStatus.paid.name,
        'paidAt': FieldValue.serverTimestamp(),
      });
      transaction.update(tableRef, {
        'status': TableStatus.available.name,
        'currentOrderId': null,
      });
    });
  }
}
