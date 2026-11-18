class Food {
  const Food({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.description = '',
    this.imageUrl = '',
    this.available = true,
  });
  final String id;
  final String name;
  final String category;
  final int price;
  final String description;
  final String imageUrl;
  final bool available;
  factory Food.fromMap(String id, Map<String, dynamic> map) => Food(
    id: id,
    name: map['name'] as String? ?? '',
    category: map['category'] as String? ?? 'Khác',
    price: (map['price'] as num?)?.toInt() ?? 0,
    description: map['description'] as String? ?? '',
    imageUrl: map['imageUrl'] as String? ?? '',
    available: map['available'] as bool? ?? true,
  );
  Map<String, dynamic> toMap() => {
    'name': name,
    'category': category,
    'price': price,
    'description': description,
    'imageUrl': imageUrl,
    'available': available,
  };
}
