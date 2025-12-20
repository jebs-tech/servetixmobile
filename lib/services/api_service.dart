import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/match.dart';
import '../models/seat_category.dart';
import '../models/pembelian.dart';
import '../models/ticket.dart';
import '../models/ticket_holder.dart';

class ApiService {
  // Ganti dengan base URL Django Anda
  // Untuk Web Browser (Chrome/Edge): gunakan http://localhost:8000
  // Untuk Android Emulator: gunakan http://10.0.2.2:8000
  // Untuk iOS Simulator: gunakan http://localhost:8000
  // Untuk device fisik: gunakan IP address komputer Anda (misalnya http://192.168.1.100:8000)
  // Untuk production: gunakan domain Anda
  static const String baseUrl = 'http://localhost:8000/payment/api/flutter';
  // Contoh lainnya:
  // static const String baseUrl = 'http://10.0.2.2:8000/payment/api/flutter'; // Android Emulator
  // static const String baseUrl = 'http://192.168.1.100:8000/payment/api/flutter'; // Device Fisik
  // static const String baseUrl = 'https://your-domain.com/payment/api/flutter'; // Production

  // Get match detail and categories
  static Future<Map<String, dynamic>> getMatchDetail(int matchId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/match/$matchId/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'status': 'success',
          'match': Match.fromJson(data['match']),
          'categories': (data['categories'] as List)
              .map((cat) => SeatCategory.fromJson(cat))
              .toList(),
          'maxTiketPerTransaksi': data['max_tiket_per_transaksi'],
        };
      } else {
        final error = json.decode(response.body);
        return {
          'status': 'error',
          'message': error['message'] ?? 'Gagal mengambil data match',
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Create purchase
  static Future<Map<String, dynamic>> createPurchase({
    required int matchId,
    required int kategoriId,
    required String namaLengkap,
    required String email,
    required String nomorTelepon,
    required List<TicketHolder> tickets,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/purchase/create/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'match_id': matchId,
          'kategori_id': kategoriId,
          'nama_lengkap': namaLengkap,
          'email': email,
          'nomor_telepon': nomorTelepon,
          'tickets': tickets.map((t) => t.toJson()).toList(),
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {
          'status': 'success',
          'orderId': data['order_id'],
          'totalPrice': data['total_price'],
          'message': data['message'],
        };
      } else {
        return {
          'status': 'error',
          'message': data['message'] ?? 'Gagal membuat pembelian',
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Get payment detail
  static Future<Map<String, dynamic>> getPaymentDetail(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payment/$orderId/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return {
            'status': 'success',
            'pembelian': Pembelian.fromJson(data['pembelian']),
          };
        } else {
          return {
            'status': 'error',
            'message': data['message'] ?? 'Gagal mengambil data pembayaran',
          };
        }
      } else {
        final error = json.decode(response.body);
        return {
          'status': 'error',
          'message': error['message'] ?? 'Gagal mengambil data pembayaran',
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Process payment
  static Future<Map<String, dynamic>> processPayment({
    required String orderId,
    required String metodePembayaran,
    File? buktiTransfer,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/payment/$orderId/process/'),
      );

      request.fields['metode_pembayaran'] = metodePembayaran;

      // If bukti transfer is provided, add it
      if (buktiTransfer != null) {
        // Convert file to base64 for API
        final bytes = await buktiTransfer.readAsBytes();
        final base64Image = base64Encode(bytes);
        final extension = buktiTransfer.path.split('.').last;
        request.fields['bukti_transfer_base64'] =
            'data:image/$extension;base64,$base64Image';
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {
          'status': 'success',
          'orderId': data['order_id'],
          'matchTitle': data['match_title'],
          'matchVenue': data['match_venue'],
          'matchDate': data['match_date'],
          'tickets': (data['tickets'] as List)
              .map((ticket) => Ticket.fromJson(ticket))
              .toList(),
          'message': data['message'],
        };
      } else {
        return {
          'status': 'error',
          'message': data['message'] ?? 'Gagal memproses pembayaran',
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Check voucher
  static Future<Map<String, dynamic>> checkVoucher({
    required String code,
    required double total,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/voucher/check/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'code': code,
          'total': total,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {
          'status': 'success',
          'discountAmount': data['discount_amount'].toDouble(),
          'newTotal': data['new_total'].toDouble(),
          'code': data['code'],
        };
      } else {
        return {
          'status': 'error',
          'message': data['message'] ?? 'Voucher tidak valid',
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
}

