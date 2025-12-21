import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'models/seat_model.dart';

class CheckoutApi {
  // Menggunakan 127.0.0.1 agar konsisten dengan MatchApi sebelumnya
  static const String _baseUrl = 'http://127.0.0.1:8000/api';

  /// 1. Mengambil daftar kursi
  /// Sinkron dengan: path('<int:match_id>/seats/', MatchSeatsAPI)
  Future<List<Seat>> fetchSeats(CookieRequest request, int matchId) async {
    // CookieRequest.get mengembalikan Map yang sudah di-decode
    final response = await request.get('$_baseUrl/$matchId/seats/');

    if (response != null && response.containsKey('seats')) {
      return (response['seats'] as List)
          .map((e) => Seat.fromJson(e))
          .toList();
    } else {
      throw Exception('Gagal memuat data kursi');
    }
  }

  /// 2. Booking berdasarkan jumlah (Auto Allocation)
  /// Sinkron dengan: path('book-quantity/', BookByQuantityAPI)
  Future<Map<String, dynamic>> bookQuantity(
    CookieRequest request, {
    required int matchId,
    required List passengers,
  }) async {
    final payload = {
      'match_id': matchId,
      'quantity': passengers.length,
      'passengers': passengers,
      'buyer_name': passengers.first['name'],
      'buyer_email': passengers.first['email'] ?? "",
    };

    // CookieRequest.post mengirimkan Map sebagai JSON secara otomatis
    final response = await request.post('$_baseUrl/book-quantity/', payload);
    return response;
  }

  /// 3. Booking berdasarkan kursi spesifik
  /// Sinkron dengan: path('book/', BookWithSeatsAPI)
  Future<Map<String, dynamic>> bookSeats(
    CookieRequest request, {
    required int matchId,
    required List<int> seatIds,
    required List passengers,
  }) async {
    final payload = {
      'match_id': matchId,
      'seat_ids': seatIds,
      'passengers': passengers,
      'buyer_name': passengers.first['name'],
      'buyer_email': passengers.first['email'] ?? "",
    };

    final response = await request.post('$_baseUrl/book/', payload);
    return response;
  }
}