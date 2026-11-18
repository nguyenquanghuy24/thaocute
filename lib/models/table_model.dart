enum TableStatus { available, occupied }

class RestaurantTable {
  const RestaurantTable({
    required this.id,
    required this.name,
    required this.area,
    this.status = TableStatus.available,
    this.currentOrderId,
  });
  final String id;
  final String name;
  final String area;
  final TableStatus status;
  final String? currentOrderId;
  bool get isOccupied => status == TableStatus.occupied;
  factory RestaurantTable.fromMap(String id, Map<String, dynamic> map) =>
      RestaurantTable(
        id: id,
        name: map['name'] as String? ?? 'Bàn',
        area: map['area'] as String? ?? 'Tầng 1',
        status: map['status'] == 'occupied'
            ? TableStatus.occupied
            : TableStatus.available,
        currentOrderId: map['currentOrderId'] as String?,
      );
  Map<String, dynamic> toMap() => {
    'name': name,
    'area': area,
    'status': status.name,
    'currentOrderId': currentOrderId,
  };
  RestaurantTable copyWith({
    TableStatus? status,
    String? currentOrderId,
    bool clearOrderId = false,
  }) => RestaurantTable(
    id: id,
    name: name,
    area: area,
    status: status ?? this.status,
    currentOrderId: clearOrderId ? null : currentOrderId ?? this.currentOrderId,
  );
}
