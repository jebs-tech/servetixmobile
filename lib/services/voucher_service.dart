import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/voucher.dart';

class VoucherService {
  // Base URL untuk Django backend
  // Untuk Android emulator, gunakan: 'http://10.0.2.2:8000'
  // Untuk iOS simulator, gunakan: 'http://localhost:8000'
  // Untuk device fisik, gunakan IP komputer: 'http://192.168.x.x:8000'
  static const String baseUrl = 'http://localhost:8000';
  
  /// Fetch daftar voucher aktif
  static Future<List<Voucher>> fetchVouchers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/voucher/api/list/'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['success'] == true && data['vouchers'] != null) {
          final List<dynamic> vouchersJson = data['vouchers'];
          return vouchersJson
              .map((json) => Voucher.fromJson(json))
              .toList();
        } else {
          throw Exception('Format response tidak valid');
        }
      } else {
        throw Exception('Gagal memuat voucher: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  /// Redeem voucher berdasarkan kode
  static Future<Map<String, dynamic>> redeemVoucher({
    required String code,
    int? userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/voucher/api/redeem/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'code': code.toUpperCase().trim(),
          if (userId != null) 'user_id': userId,
        }),
      );

      final Map<String, dynamic> data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Voucher berhasil digunakan',
          'voucher': data['voucher'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal menggunakan voucher',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }
}

