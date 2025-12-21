// lib/models/dashboard_models.dart

class UserProfile {
  final String username;
  final String email;
  final String namaLengkap;
  final List<PreferredTeam> preferredTeams;

  UserProfile({
    required this.username,
    required this.email,
    required this.namaLengkap,
    required this.preferredTeams,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    var list = json['preferred_teams'] as List;
    List<PreferredTeam> teamsList = list.map((i) => PreferredTeam.fromJson(i)).toList();

    return UserProfile(
      username: json['username'],
      email: json['email'],
      namaLengkap: json['nama_lengkap'] ?? "", // Handle jika null
      preferredTeams: teamsList,
    );
  }
}

class PreferredTeam {
  final int id;
  final String name;
  final String logoUrl;

  PreferredTeam({required this.id, required this.name, required this.logoUrl});

  factory PreferredTeam.fromJson(Map<String, dynamic> json) {
    return PreferredTeam(
      id: json['id'],
      name: json['name'],
      logoUrl: json['logo'] ?? "",
    );
  }
}

class Ticket {
  final int id; // Bisa purchase_id atau match_id tergantung endpoint
  final String matchTitle;
  final String date;
  final String venue; // Hanya untuk tiket aktif
  final int totalTickets;

  Ticket({
    required this.id,
    required this.matchTitle,
    required this.date,
    this.venue = "",
    required this.totalTickets,
  });

  // Parser untuk Tiket Aktif
  factory Ticket.fromJsonActive(Map<String, dynamic> json) {
    return Ticket(
      id: json['purchase_id'],
      matchTitle: json['match_title'],
      date: json['date'],
      venue: json['venue'],
      totalTickets: json['total_tickets'],
    );
  }

  // Parser untuk Riwayat (History)
  factory Ticket.fromJsonHistory(Map<String, dynamic> json) {
    return Ticket(
      id: json['match_id'],
      matchTitle: json['match_title'],
      date: json['date'],
      totalTickets: json['ticket_count'],
    );
  }
}

class PurchaseDetail {
  final String matchTitle;
  final String venue;
  final String date;
  final int purchaseId;
  final int totalPrice;
  final List<SeatItem> tickets;

  PurchaseDetail({
    required this.matchTitle,
    required this.venue,
    required this.date,
    required this.purchaseId,
    required this.totalPrice,
    required this.tickets,
  });

  factory PurchaseDetail.fromJson(Map<String, dynamic> json) {
    var list = json['tickets'] as List;
    List<SeatItem> ticketsList = list.map((i) => SeatItem.fromJson(i)).toList();

    return PurchaseDetail(
      matchTitle: json['match_title'],
      venue: json['venue'],
      date: json['date'],
      purchaseId: json['purchase_id'],
      totalPrice: json['total_price'] ?? 0,
      tickets: ticketsList,
    );
  }
}

class SeatItem {
  final int id; // Ini ticket_id / seat_id
  final String row;
  final String col;
  final String category;
  final int price;
  final String seatCode;

  SeatItem({
    required this.id,
    required this.row,
    required this.col,
    required this.category,
    required this.price,
    required this.seatCode,
  });

  factory SeatItem.fromJson(Map<String, dynamic> json) {
    return SeatItem(
      id: json['id'],
      row: json['row'].toString(),
      col: json['col'].toString(),
      category: json['category'],
      price: json['price'],
      seatCode: json['seat_code'],
    );
  }
}

class TicketDetail {
  final int ticketId;
  final String matchTitle;
  final String qrCodeUrl;
  final String seatCode;
  final String category;

  TicketDetail({
    required this.ticketId,
    required this.matchTitle,
    required this.qrCodeUrl,
    required this.seatCode,
    required this.category,
  });

  factory TicketDetail.fromJson(Map<String, dynamic> json) {
    return TicketDetail(
      ticketId: json['ticket_id'],
      matchTitle: json['match_title'],
      qrCodeUrl: json['qr_code_url'] ?? "",
      seatCode: "${json['row']}${json['col']}",
      category: json['category'],
    );
  }
}
