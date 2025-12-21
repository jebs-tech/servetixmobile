// To parse this JSON data, do
//
//     final matchEntry = matchEntryFromJson(jsonString);

import 'dart:convert';

List<MatchEntry> matchEntryFromJson(String str) => List<MatchEntry>.from(json.decode(str).map((x) => MatchEntry.fromJson(x)));

String matchEntryToJson(List<MatchEntry> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class MatchEntry {
    int id;
    String title;
    Team teamA;
    Team teamB;
    Venue venue;
    DateTime startTime;
    String description;
    int priceFrom;

    MatchEntry({
        required this.id,
        required this.title,
        required this.teamA,
        required this.teamB,
        required this.venue,
        required this.startTime,
        required this.description,
        required this.priceFrom,
    });

    factory MatchEntry.fromJson(Map<String, dynamic> json) => MatchEntry(
        id: json["id"],
        title: json["title"],
        teamA: Team.fromJson(json["team_a"]),
        teamB: Team.fromJson(json["team_b"]),
        venue: Venue.fromJson(json["venue"]),
        startTime: DateTime.parse(json["start_time"]),
        description: json["description"],
        priceFrom: json["price_from"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "team_a": teamA.toJson(),
        "team_b": teamB.toJson(),
        "venue": venue.toJson(),
        "start_time": startTime.toIso8601String(),
        "description": description,
        "price_from": priceFrom,
    };
}

class Team {
    String name;
    dynamic logo;

    Team({
        required this.name,
        required this.logo,
    });

    factory Team.fromJson(Map<String, dynamic> json) => Team(
        name: json["name"],
        logo: json["logo"],
    );

    Map<String, dynamic> toJson() => {
        "name": name,
        "logo": logo,
    };
}

class Venue {
    String name;
    String address;

    Venue({
        required this.name,
        required this.address,
    });

    factory Venue.fromJson(Map<String, dynamic> json) => Venue(
        name: json["name"],
        address: json["address"],
    );

    Map<String, dynamic> toJson() => {
        "name": name,
        "address": address,
    };
}
