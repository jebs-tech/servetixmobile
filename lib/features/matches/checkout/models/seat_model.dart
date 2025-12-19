class Seat {
  final int id;
  final String label;
  final String category;
  final int price;
  final String color;

  Seat({
    required this.id,
    required this.label,
    required this.category,
    required this.price,
    required this.color,
  });

  factory Seat.fromJson(Map<String, dynamic> json) {
    return Seat(
      id: json['id'],
      label: json['label'],
      category: json['category'],
      price: json['price'],
      color: json['color'],
    );
  }
}
