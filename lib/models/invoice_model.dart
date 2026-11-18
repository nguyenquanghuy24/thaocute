enum PaymentMethod { cash, bankTransfer }

class Invoice {
  const Invoice({
    required this.id,
    required this.orderId,
    required this.tableId,
    required this.total,
    required this.method,
    required this.employeeId,
    required this.paidAt,
  });
  final String id;
  final String orderId;
  final String tableId;
  final int total;
  final PaymentMethod method;
  final String employeeId;
  final DateTime paidAt;
  Map<String, dynamic> toMap() => {
    'orderId': orderId,
    'tableId': tableId,
    'total': total,
    'paymentMethod': method.name,
    'employeeId': employeeId,
    'paidAt': paidAt,
  };
}
