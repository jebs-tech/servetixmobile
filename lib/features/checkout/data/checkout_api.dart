import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

class CheckoutApi {
  // Getter dinamis untuk mendukung Android Emulator (10.0.2.2) dan Web/Desktop (127.0.0.1)
  static String get _baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://127.0.0.1:8000';
  }

  /// 1. Simpan Pembelian Utama (Sinkron dengan api_simpan_pembelian di payment/views.py)
  /// Digunakan saat "Lanjutkan Pembayaran" ditekan untuk membuat Order ID.
  Future<Map<String, dynamic>> saveOrder(
    CookieRequest request, {
    required int matchId,
    required int categoryId,
    required String namaLengkap,
    required String email,
    required String nomorTelepon,
    required List tickets,
  }) async {
    final payload = {
      'match_id': matchId,
      'kategori_id': categoryId,
      'nama_lengkap': namaLengkap,
      'email': email,
      'nomor_telepon': nomorTelepon,
      'tickets': tickets,
    };

    // Pastikan path URL sesuai dengan yang terdaftar di urls.py Django Anda
    final response = await request.post('$_baseUrl/payment/api/save-order/', payload);
    return response;
  }

  /// 2. Booking berdasarkan kursi spesifik (Path: /api/book/)
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
    return await request.post('$_baseUrl/api/book/', payload);
  }

  /// 3. Booking berdasarkan jumlah (Path: /api/book-quantity/)
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
    return await request.post('$_baseUrl/api/book-quantity/', payload);
  }
}