import 'food_model.dart';

class OrderLine {
  OrderLine({
    required this.foodId,
    required this.name,
    required this.unitPrice,
    this.quantity = 1,
    this.note = '',
  });
  final String foodId;
  final String name;
  final int unitPrice;
  int quantity;
  String note;
  int get total => unitPrice * quantity;
  factory OrderLine.fromMap(Map<String, dynamic> map) => OrderLine(
    foodId: map['foodId'] as String? ?? '',
    name: map['name'] as String? ?? '',
    unitPrice: (map['unitPrice'] as num?)?.toInt() ?? 0,
    quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    note: map['note'] as String? ?? '',
  );
  factory OrderLine.fromFood(Food food, {int quantity = 1, String note = ''}) =>
      OrderLine(
        foodId: food.id,
        name: food.name,
        unitPrice: food.price,
        quantity: quantity,
        note: note,
      );
  Map<String, dynamic> toMap() => {
    'foodId': foodId,
    'name': name,
    'unitPrice': unitPrice,
    'quantity': quantity,
    'note': note,
  };
  OrderLine clone() => OrderLine(
    foodId: foodId,
    name: name,
    unitPrice: unitPrice,
    quantity: quantity,
    note: note,
  );
}

enum OrderStatus { serving, paid, cancelled }

class Order {
  Order({
    required this.id,
    required this.tableId,
    required this.lines,
    this.status = OrderStatus.serving,
    this.employeeId = '',
    this.createdAt,
  });
  final String id;
  final String tableId;
  final List<OrderLine> lines;
  OrderStatus status;
  final String employeeId;
  final DateTime? createdAt;
  int get total => lines.fold(0, (sum, line) => sum + line.total);
  int get itemCount => lines.fold(0, (sum, line) => sum + line.quantity);
  factory Order.fromMap(String id, Map<String, dynamic> map) => Order(
    id: id,
    tableId: map['tableId'] as String? ?? '',
    lines: ((map['lines'] as List<dynamic>?) ?? const [])
        .map((e) => OrderLine.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList(),
    status: OrderStatus.values.firstWhere(
      (s) => s.name == map['status'],
      orElse: () => OrderStatus.serving,
    ),
    employeeId: map['employeeId'] as String? ?? '',
    createdAt: (map['createdAt'] as dynamic)?.toDate(),
  );
  Map<String, dynamic> toMap() => {
    'tableId': tableId,
    'lines': lines.map((line) => line.toMap()).toList(),
    'status': status.name,
    'employeeId': employeeId,
    'createdAt': createdAt,
  };
  Order clone() => Order(
    id: id,
    tableId: tableId,
    lines: lines.map((line) => line.clone()).toList(),
    status: status,
    employeeId: employeeId,
    createdAt: createdAt,
  );
}
