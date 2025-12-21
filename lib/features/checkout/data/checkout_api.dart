import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models/seat_model.dart';

class CheckoutApi {
  static const baseUrl = 'http://localhost:8000/api';

  static Future<List<Seat>> fetchSeats(int matchId) async {
    final res = await http.get(Uri.parse('$baseUrl/matches/$matchId/seats/'));
    final data = json.decode(res.body);
    return (data['seats'] as List)
        .map((e) => Seat.fromJson(e))
        .toList();
  }

  static Future<Map<String, dynamic>> bookQuantity({
    required int matchId,
    required List passengers,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/book_quantity/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'match_id': matchId,
        'quantity': passengers.length,
        'passengers': passengers,
        'buyer_name': passengers.first['name'],
        'buyer_email': passengers.first['email'],
      }),
    );
    return json.decode(res.body);
  }

  static Future<Map<String, dynamic>> bookSeats({
    required int matchId,
    required List<int> seatIds,
    required List passengers,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/book/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'match_id': matchId,
        'seat_ids': seatIds,
        'passengers': passengers,
        'buyer_name': passengers.first['name'],
        'buyer_email': passengers.first['email'],
      }),
    );
    return json.decode(res.body);
  }
}
