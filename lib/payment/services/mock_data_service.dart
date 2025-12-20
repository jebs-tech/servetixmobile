/// Mock Data Service untuk testing payment module
/// Digunakan saat modul matches dan seat belum selesai
/// 
/// Cara menggunakan:
/// 1. Ganti PaymentApiService dengan MockDataService di screens untuk testing
/// 2. Atau buat flag USE_MOCK_DATA untuk switch antara real API dan mock data

import '../models/match.dart';
import '../models/seat_category.dart';
import '../models/pembelian.dart';
import '../models/seat.dart';
import '../models/ticket.dart';
import '../models/ticket_holder.dart';
import 'dart:math';

class MockDataService {
  // Dummy Match Data
  static Match getDummyMatch() {
    return Match(
      id: 1,
      title: 'Persija vs Persib',
      venue: 'Istora Senayan',
      venueAddress: 'Jl. Pintu Satu Senayan, Jakarta',
      startTime: DateTime.now().add(const Duration(days: 7)),
      description: 'Pertandingan sepak bola antara Persija Jakarta vs Persib Bandung',
    );
  }

  // Dummy Seat Categories (4 kategori sesuai Django)
  static List<SeatCategory> getDummyCategories() {
    return [
      SeatCategory(
        id: 1,
        name: 'VIP',
        price: 500000,
        color: '#FFD700', // Gold
      ),
      SeatCategory(
        id: 2,
        name: 'PREMIUM',
        price: 350000,
        color: '#C0C0C0', // Silver
      ),
      SeatCategory(
        id: 3,
        name: 'REGULAR',
        price: 200000,
        color: '#CD7F32', // Bronze
      ),
      SeatCategory(
        id: 4,
        name: 'ECONOMY',
        price: 100000,
        color: '#808080', // Gray
      ),
    ];
  }

  // Simulasi get match detail
  static Future<Map<String, dynamic>> getMatchDetail(int matchId) async {
    // Simulasi network delay
    await Future.delayed(const Duration(seconds: 1));

    return {
      'status': 'success',
      'match': getDummyMatch(),
      'categories': getDummyCategories(),
      'maxTiketPerTransaksi': 5,
    };
  }

  // Simulasi create purchase
  static Future<Map<String, dynamic>> createPurchase({
    required int matchId,
    required int kategoriId,
    required String namaLengkap,
    required String email,
    required String nomorTelepon,
    required List<TicketHolder> tickets,
  }) async {
    // Simulasi network delay
    await Future.delayed(const Duration(seconds: 1));

    // Generate random order ID
    final random = Random();
    final orderId = 'AII${random.nextInt(900000) + 100000}';

    // Hitung total harga berdasarkan kategori yang dipilih
    SeatCategory? selectedCategory;
    try {
      selectedCategory = getDummyCategories().firstWhere((cat) => cat.id == kategoriId);
    } catch (e) {
      // Fallback ke kategori pertama jika tidak ditemukan
      selectedCategory = getDummyCategories().first;
    }
    
    final totalPrice = tickets.length * selectedCategory.price;

    return {
      'status': 'success',
      'orderId': orderId,
      'totalPrice': totalPrice,
      'message': 'Pembelian berhasil dibuat',
    };
  }

  // Simulasi get payment detail
  static Future<Map<String, dynamic>> getPaymentDetail(String orderId) async {
    // Simulasi network delay
    await Future.delayed(const Duration(seconds: 1));

    final match = getDummyMatch();
    final category = getDummyCategories().first;

    // Generate dummy seats
    final seatsData = List.generate(2, (index) {
      return {
        'id': index + 1,
        'row': String.fromCharCode(65 + index), // A, B, C, ...
        'col': index + 1,
        'seat_code': '${String.fromCharCode(65 + index)}${index + 1}',
        'category': category.name,
        'category_price': category.price,
      };
    });

    final pembelianData = {
      'order_id': orderId,
      'nama_lengkap_pembeli': 'John Doe',
      'email': 'john@example.com',
      'nomor_telepon': '081234567890',
      'total_price': 1000000,
      'status': 'PENDING',
      'status_display': 'Menunggu Pembayaran',
      'tanggal_pembelian': DateTime.now().toIso8601String(),
      'match': {
        'id': match.id,
        'title': match.title,
        'venue': match.venue,
        'venue_address': match.venueAddress,
        'start_time': match.startTime.toIso8601String(),
        'description': match.description,
      },
      'seats': seatsData,
    };

    return {
      'status': 'success',
      'pembelian': Pembelian.fromJson(pembelianData),
    };
  }

  // Simulasi process payment
  static Future<Map<String, dynamic>> processPayment({
    required String orderId,
    required String metodePembayaran,
    dynamic buktiTransfer, // Changed from File? to dynamic for mock
  }) async {
    // Simulasi network delay
    await Future.delayed(const Duration(seconds: 2));

    final match = getDummyMatch();
    final category = getDummyCategories().first;

    // Generate dummy tickets dengan QR code
    final tickets = List.generate(2, (index) {
      return {
        'seat_id': index + 1,
        'seat': '${String.fromCharCode(65 + index)}${index + 1}',
        'category': category.name,
        'qr_url': 'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=SERVETIX|$orderId|SEAT-${index + 1}',
        'qr_data': 'SERVETIX|$orderId|SEAT-${index + 1}',
      };
    });

    return {
      'status': 'success',
      'orderId': orderId,
      'matchTitle': match.title,
      'matchVenue': match.venue,
      'matchDate': '${match.startTime.day} ${_getMonthName(match.startTime.month)} ${match.startTime.year}, ${match.startTime.hour.toString().padLeft(2, '0')}:${match.startTime.minute.toString().padLeft(2, '0')}',
      'tickets': tickets,
      'message': 'Pembayaran berhasil, e-ticket siap.',
    };
  }

  // Simulasi check voucher
  static Future<Map<String, dynamic>> checkVoucher({
    required String code,
    required double total,
  }) async {
    // Simulasi network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Dummy voucher codes untuk testing
    final validVouchers = {
      'DISKON10': 0.10, // 10% discount
      'DISKON20': 0.20, // 20% discount
      'DISKON50': 0.50, // 50% discount
      'PROMO100K': 100000, // Fixed discount 100k
    };

    if (validVouchers.containsKey(code.toUpperCase())) {
      final discount = validVouchers[code.toUpperCase()]!;
      double discountAmount;
      
      if (discount < 1) {
        // Percentage discount
        discountAmount = total * discount;
      } else {
        // Fixed discount
        discountAmount = discount.toDouble();
      }

      final newTotal = total - discountAmount;

      return {
        'status': 'success',
        'discountAmount': discountAmount,
        'newTotal': newTotal > 0 ? newTotal : 0,
        'code': code.toUpperCase(),
      };
    } else {
      return {
        'status': 'error',
        'message': 'Kode voucher tidak valid atau sudah kadaluarsa',
      };
    }
  }

  static String _getMonthName(int month) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return months[month - 1];
  }
}

