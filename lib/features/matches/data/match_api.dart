import 'dart:convert';
import 'package:http/http.dart' as http;
import 'match_detail_model.dart';

class MatchApi {
  // Base URL (Gunakan 127.0.0.1 untuk Flutter Web)
  static const String _baseUrl = 'http://127.0.0.1:8000/api';

  // Header standar untuk komunikasi JSON
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// Mengambil detail informasi pertandingan
  Future<MatchDetail> fetchMatchDetail(int id) async {
    final url = Uri.parse('$_baseUrl/$id/');
    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        return MatchDetail.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Gagal memuat detail pertandingan');
      }
    } catch (e) {
      throw Exception('Kesalahan koneksi detail: $e');
    }
  }

  /// Mengambil daftar semua kursi (untuk Denah Stadium)
  Future<List<dynamic>> fetchMatchSeats(int id) async {
    final url = Uri.parse('$_baseUrl/$id/seats/');
    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        // Sesuai format response Django: {"seats": [...]}
        return data['seats'] as List<dynamic>;
      } else {
        throw Exception('Gagal memuat data kursi');
      }
    } catch (e) {
      throw Exception('Gagal terhubung ke server untuk data kursi: $e');
    }
  }
}