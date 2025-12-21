import 'dart:io';
import 'dart:convert';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'models/payment_models.dart';

class PaymentApi {
  static const String _baseUrl = 'http://127.0.0.1:8000/payment/api-flutter';

  /// Get list of seat categories
  static Future<List<SeatCategory>> getCategories(CookieRequest request) async {
    try {
      final response = await request.get('$_baseUrl/categories/');
      
      if (response != null && response['status'] == 'success') {
        return (response['data'] as List)
            .map((cat) => SeatCategory.fromJson(cat))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }

  /// Save pembelian (create order)
  static Future<Map<String, dynamic>> savePembelian(
    CookieRequest request, {
    required int matchId,
    required int kategoriId,
    required String namaLengkap,
    required String email,
    required String nomorTelepon,
    required List<Map<String, dynamic>> tickets,
  }) async {
    try {
      final payload = {
        'match_id': matchId,
        'kategori_id': kategoriId,
        'nama_lengkap': namaLengkap,
        'email': email,
        'nomor_telepon': nomorTelepon,
        'tickets': tickets,
      };

      final response = await request.post('$_baseUrl/simpan-pembelian/', payload);
      return response;
    } catch (e) {
      print('Error saving pembelian: $e');
      return {'status': 'error', 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Get payment detail by order_id
  static Future<Pembelian?> getPaymentDetail(
    CookieRequest request,
    String orderId,
  ) async {
    try {
      final response = await request.get('$_baseUrl/payment/$orderId/');
      
      if (response != null && response['status'] == 'success') {
        return Pembelian.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      print('Error getting payment detail: $e');
      return null;
    }
  }

  /// Process payment (with optional file upload for bank methods)
  static Future<PaymentResponse> processPayment(
    CookieRequest request, {
    required String orderId,
    required String metodePembayaran,
    File? buktiTransferFile,
  }) async {
    try {
      final metodeBank = ['BRI', 'BCA', 'Mandiri'];
      
      // Jika metode bank dan ada file, gunakan multipart request dengan http package
      if (metodeBank.contains(metodePembayaran) && buktiTransferFile != null) {
        // Buat multipart request untuk upload file
        final uri = Uri.parse('$_baseUrl/proses-bayar/$orderId/');
        var multipartRequest = http.MultipartRequest('POST', uri);
        
        // Tambahkan fields
        multipartRequest.fields['metode_pembayaran'] = metodePembayaran;
        
        // Tambahkan file - detect content type dari extension
        final fileName = buktiTransferFile.path.split('/').last.toLowerCase();
        MediaType contentType;
        if (fileName.endsWith('.png')) {
          contentType = MediaType('image', 'png');
        } else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
          contentType = MediaType('image', 'jpeg');
        } else {
          contentType = MediaType('image', 'jpeg'); // default
        }
        
        final fileStream = http.ByteStream(buktiTransferFile.openRead());
        final fileLength = await buktiTransferFile.length();
        final multipartFile = http.MultipartFile(
          'bukti_transfer',
          fileStream,
          fileLength,
          filename: fileName,
          contentType: contentType,
        );
        multipartRequest.files.add(multipartFile);
        
        // Untuk cookies, kita akan mengandalkan bahwa endpoint menggunakan @csrf_exempt
        // atau kita bisa menambahkan header jika diperlukan
        
        // Send request
        final streamedResponse = await multipartRequest.send();
        final response = await http.Response.fromStream(streamedResponse);
        
        if (response.statusCode == 200) {
          // Parse JSON response
          final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
          return PaymentResponse.fromJson(jsonResponse);
        } else {
          try {
            final errorJson = json.decode(response.body) as Map<String, dynamic>;
            return PaymentResponse(
              status: 'error',
              message: errorJson['message'] ?? 'Terjadi kesalahan: ${response.statusCode}',
            );
          } catch (_) {
            return PaymentResponse(
              status: 'error',
              message: 'Terjadi kesalahan: ${response.statusCode}',
            );
          }
        }
      } else {
        // Jika bukan metode bank atau tidak ada file, gunakan CookieRequest biasa
        final payload = {
          'metode_pembayaran': metodePembayaran,
        };

        final response = await request.post('$_baseUrl/proses-bayar/$orderId/', payload);
        return PaymentResponse.fromJson(response);
      }
    } catch (e) {
      print('Error processing payment: $e');
      return PaymentResponse(
        status: 'error',
        message: 'Terjadi kesalahan: $e',
      );
    }
  }

  /// Check voucher code
  static Future<VoucherResponse> checkVoucher(
    CookieRequest request, {
    required String code,
    required double total,
  }) async {
    try {
      final payload = {
        'code': code,
        'total': total,
      };

      final response = await request.post('$_baseUrl/check-voucher/', payload);
      return VoucherResponse.fromJson(response);
    } catch (e) {
      print('Error checking voucher: $e');
      return VoucherResponse(
        status: 'error',
        message: 'Terjadi kesalahan: $e',
      );
    }
  }
}

