class Match {
  final int id;
  final String title;
  final String venue;
  final String venueAddress;
  final DateTime startTime;
  final String? description;

  Match({
    required this.id,
    required this.title,
    required this.venue,
    required this.venueAddress,
    required this.startTime,
    this.description,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'],
      title: json['title'],
      venue: json['venue'],
      venueAddress: json['venue_address'] ?? '',
      startTime: DateTime.parse(json['start_time']),
      description: json['description'],
    );
  }
}

