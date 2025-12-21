import 'dart:convert';
import 'package:http/http.dart' as http;
import './models/seat_model.dart';

class CheckoutService {
  static const baseUrl = 'http://localhost:8000';

  static Future<List<Seat>> fetchSeats(int matchId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/matches/$matchId/seats/'),
    );

    final data = jsonDecode(res.body);
    return (data['seats'] as List)
        .map((e) => Seat.fromJson(e))
        .toList();
  }

  static Future<Map<String, dynamic>> bookWithSeats(
    Map<String, dynamic> body,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/book/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> bookByQuantity(
    Map<String, dynamic> body,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/book-quantity/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return jsonDecode(res.body);
  }
}
