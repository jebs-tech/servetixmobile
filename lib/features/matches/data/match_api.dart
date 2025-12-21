import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'match_detail_model.dart';

class MatchApi {
  // Base URL (Gunakan 127.0.0.1 untuk Flutter Web)
  static const String _baseUrl = 'http://127.0.0.1:8000/api';

  /// Mengambil detail informasi pertandingan menggunakan CookieRequest
  Future<MatchDetail> fetchMatchDetail(CookieRequest request, int id) async {
    try {
      // CookieRequest.get langsung mengembalikan decoded JSON (Map/List)
      final response = await request.get('$_baseUrl/$id/');

      // Di CookieRequest, jika request gagal biasanya melempar error atau mengembalikan null
      if (response != null) {
        return MatchDetail.fromJson(response);
      } else {
        throw Exception('Gagal memuat detail pertandingan');
      }
    } catch (e) {
      throw Exception('Kesalahan koneksi detail: $e');
    }
  }

  /// Mengambil daftar semua kursi menggunakan CookieRequest
  Future<List<dynamic>> fetchMatchSeats(CookieRequest request, int id) async {
    try {
      final response = await request.get('$_baseUrl/$id/seats/');

      if (response != null && response.containsKey('seats')) {
        // Sesuai format response Django: {"seats": [...]}
        return response['seats'] as List<dynamic>;
      } else {
        throw Exception('Gagal memuat data kursi atau format salah');
      }
    } catch (e) {
      throw Exception('Gagal terhubung ke server untuk data kursi: $e');
    }
  }
}