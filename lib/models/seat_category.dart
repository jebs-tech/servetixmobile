class SeatCategory {
  final int id;
  final String name;
  final int price;
  final String color;

  SeatCategory({
    required this.id,
    required this.name,
    required this.price,
    required this.color,
  });

  factory SeatCategory.fromJson(Map<String, dynamic> json) {
    return SeatCategory(
      id: json['id'],
      name: json['name'],
      price: json['price'],
      color: json['color'] ?? '#d3a15a',
    );
  }
}

