class Ticket {
  final int seatId;
  final String seat;
  final String category;
  final String? qrUrl;
  final String? qrData;

  Ticket({
    required this.seatId,
    required this.seat,
    required this.category,
    this.qrUrl,
    this.qrData,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      seatId: json['seat_id'],
      seat: json['seat'],
      category: json['category'],
      qrUrl: json['qr_url'],
      qrData: json['qr_data'],
    );
  }
}

