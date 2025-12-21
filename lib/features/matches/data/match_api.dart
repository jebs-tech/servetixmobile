import 'dart:convert';
import 'package:http/http.dart' as http;
import 'match_detail_model.dart';

class MatchApi {
  // Base URL untuk API Django
  static const String _baseUrl = 'http://127.0.0.1:8000/api';

  /// Mengambil detail informasi pertandingan
  Future<MatchDetail> fetchMatchDetail(int id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/matches/$id/'),
    );

    if (response.statusCode == 200) {
      return MatchDetail.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load match');
    }
  }

  /// Mengambil daftar semua kursi untuk pertandingan tertentu
  /// Digunakan untuk menentukan kursi mana yang sudah di-book (warna hitam)
  Future<List<dynamic>> fetchMatchSeats(int id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/matches/$id/seats/'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      // Mengambil list kursi dari key 'seats' sesuai format response Django
      return data['seats'] as List<dynamic>;
    } else {
      throw Exception('Failed to load match seats');
    }
  }
}