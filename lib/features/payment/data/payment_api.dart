import 'dart:io';
import 'dart:convert'; // [PENTING] Untuk jsonEncode
import 'package:flutter/foundation.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'models/payment_models.dart';

class PaymentApi {
  static String get _baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000/payment/api-flutter';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000/payment/api-flutter';
    return 'http://127.0.0.1:8000/payment/api-flutter';
  }

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

  // --- [BAGIAN YANG DIPERBAIKI] ---
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
      // 1. Susun data dalam bentuk Map
      final Map<String, dynamic> payload = {
        'match_id': matchId,
        'kategori_id': kategoriId,
        'nama_lengkap': namaLengkap,
        'email': email,
        'nomor_telepon': nomorTelepon,
        'tickets': tickets,
      };

      // 2. [FIX UTAMA] Encode ke JSON String sebelum dikirim
      // Ini mencegah error "int not subtype of String" karena http package
      // tidak akan mencoba mem-parsingnya sebagai form fields.
      final String jsonBody = jsonEncode(payload);

      // 3. Kirim sebagai JSON
      final response = await request.post(
        '$_baseUrl/simpan-pembelian/',
        jsonBody, // Kirim String JSON, bukan Map mentah
      );
      
      return response;
    } catch (e) {
      print('Error saving pembelian: $e');
      // Kembalikan pesan error agar bisa ditampilkan di Snackbar
      return {'status': 'error', 'message': 'Terjadi kesalahan: $e'};
    }
  }

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

  static Future<PaymentResponse> processPayment(
    CookieRequest request, {
    required String orderId,
    required String metodePembayaran,
    File? buktiTransferFile,
  }) async {
    try {
      final metodeBank = ['BRI', 'BCA', 'Mandiri'];
      
      if (metodeBank.contains(metodePembayaran) && buktiTransferFile != null) {
        final uri = Uri.parse('$_baseUrl/proses-bayar/$orderId/');
        var multipartRequest = http.MultipartRequest('POST', uri);
        
        multipartRequest.fields['metode_pembayaran'] = metodePembayaran;
        
        final fileName = buktiTransferFile.path.split('/').last.toLowerCase();
        MediaType contentType = MediaType('image', 'jpeg');
        if (fileName.endsWith('.png')) contentType = MediaType('image', 'png');
        
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
        
        final streamedResponse = await multipartRequest.send();
        final response = await http.Response.fromStream(streamedResponse);
        
        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
          return PaymentResponse.fromJson(jsonResponse);
        } else {
          return PaymentResponse(status: 'error', message: 'Gagal upload: ${response.statusCode}');
        }
      } else {
        final payload = {'metode_pembayaran': metodePembayaran};
        // Encode JSON juga di sini untuk keamanan
        final response = await request.post('$_baseUrl/proses-bayar/$orderId/', jsonEncode(payload));
        return PaymentResponse.fromJson(response);
      }
    } catch (e) {
      print('Error processing payment: $e');
      return PaymentResponse(status: 'error', message: 'Terjadi kesalahan: $e');
    }
  }

  static Future<VoucherResponse> checkVoucher(
    CookieRequest request, {
    required String code,
    required double total,
  }) async {
    try {
      final payload = {'code': code, 'total': total};
      // Encode JSON juga di sini
      final response = await request.post('$_baseUrl/check-voucher/', jsonEncode(payload));
      return VoucherResponse.fromJson(response);
    } catch (e) {
      print('Error checking voucher: $e');
      return VoucherResponse(status: 'error', message: 'Terjadi kesalahan: $e');
    }
  }
}