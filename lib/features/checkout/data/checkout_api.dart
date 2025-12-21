import 'dart:io'; // Untuk mengecek Platform.isAndroid
import 'package:flutter/foundation.dart'; // Untuk mengecek kIsWeb
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'models/seat_model.dart';

class CheckoutApi {
  // Getter dinamis untuk menentukan URL berdasarkan platform
  static String get _baseUrl {
    if (kIsWeb) {
      // Jika dijalankan di browser (localhost)
      return 'http://127.0.0.1:8000/api';
    } else if (Platform.isAndroid) {
      // Jika dijalankan di Android Emulator (IP khusus untuk akses localhost komputer)
      return 'http://10.0.2.2:8000/api';
    }
    // Default untuk Windows/Desktop/Lainnya
    return 'http://127.0.0.1:8000/api';
  }

  /// 1. Mengambil daftar kursi
  Future<List<Seat>> fetchSeats(CookieRequest request, int matchId) async {
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

    final response = await request.post('$_baseUrl/book-quantity/', payload);
    return response;
  }

  /// 3. Booking berdasarkan kursi spesifik
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