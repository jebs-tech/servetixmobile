import 'dart:io'; // Import untuk Platform
import 'package:flutter/foundation.dart'; // Import untuk kIsWeb
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'match_detail_model.dart';

class MatchApi {
  // Gunakan getter untuk menentukan URL berdasarkan platform
  static String get _baseUrl {
    if (kIsWeb) {
      // Jika di Web Browser
      return 'http://127.0.0.1:8000/api';
    } else if (Platform.isAndroid) {
      // Jika di Android Emulator
      return 'http://10.0.2.2:8000/api';
    }
    // Fallback default
    return 'http://127.0.0.1:8000/api';
  }

  Future<MatchDetail> fetchMatchDetail(CookieRequest request, int id) async {
    try {
      final response = await request.get('$_baseUrl/$id/');
      if (response != null) {
        return MatchDetail.fromJson(response);
      } else {
        throw Exception('Gagal memuat detail pertandingan');
      }
    } catch (e) {
      throw Exception('Kesalahan koneksi detail: $e');
    }
  }

  Future<List<dynamic>> fetchMatchSeats(CookieRequest request, int id) async {
    try {
      final response = await request.get('$_baseUrl/$id/seats/');
      if (response != null && response.containsKey('seats')) {
        return response['seats'] as List<dynamic>;
      } else {
        throw Exception('Gagal memuat data kursi atau format salah');
      }
    } catch (e) {
      throw Exception('Gagal terhubung ke server untuk data kursi: $e');
    }
  }
}