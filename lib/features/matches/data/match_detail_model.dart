// lib/features/matches/data/match_detail_model.dart

class MatchDetail {
  final int id;
  final String teamA;
  final String teamB;
  final String venue;
  final DateTime startTime;
  final String description;
  final String venueAddress;
  final int priceFrom;

  MatchDetail({
    required this.id,
    required this.teamA,
    required this.teamB,
    required this.venue,
    required this.startTime,
    required this.description,
    required this.venueAddress,
    required this.priceFrom,
  });

  factory MatchDetail.fromJson(Map<String, dynamic> json) {
    return MatchDetail(
      id: json['id'],
      teamA: json['team_a'],
      teamB: json['team_b'],
      venue: json['venue'],
      startTime: DateTime.parse(json['start_time']),
      description: json['description'] ?? '',
      venueAddress: json['venue_address'] ?? '-',
      priceFrom: json['price_from'] ?? 0,
    );
  }

  String get formattedDate => '${startTime.day}/${startTime.month}/${startTime.year}';

  String get formattedTime {
    final hour = startTime.hour.toString().padLeft(2, '0');
    final minute = startTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get title => '$teamA vs $teamB';
}