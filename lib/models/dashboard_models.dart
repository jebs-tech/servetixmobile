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