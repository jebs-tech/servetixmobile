class Seat {
  final int id;
  final String row;
  final int col;
  final String seatCode;
  final String category;
  final int categoryPrice;

  Seat({
    required this.id,
    required this.row,
    required this.col,
    required this.seatCode,
    required this.category,
    required this.categoryPrice,
  });

  factory Seat.fromJson(Map<String, dynamic> json) {
    return Seat(
      id: json['id'],
      row: json['row'],
      col: json['col'],
      seatCode: json['seat_code'],
      category: json['category'],
      categoryPrice: json['category_price'],
    );
  }
}

