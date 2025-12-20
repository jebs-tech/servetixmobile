/// Unified Payment Service
/// Service ini akan otomatis menggunakan MockDataService atau PaymentApiService
/// berdasarkan konfigurasi di PaymentServiceConfig

import 'payment_service_config.dart';
import 'mock_data_service.dart';
import 'payment_api_service.dart';
import '../models/ticket_holder.dart';
import 'dart:io';

/// Unified Payment Service
/// Service ini akan otomatis menggunakan MockDataService atau PaymentApiService
/// berdasarkan konfigurasi di PaymentServiceConfig
/// 
/// Untuk testing: set USE_MOCK_DATA = true di payment_service_config.dart
/// Untuk production: set USE_MOCK_DATA = false di payment_service_config.dart
class PaymentService {
  /// Get match detail and categories
  static Future<Map<String, dynamic>> getMatchDetail(int matchId) async {
    if (PaymentServiceConfig.USE_MOCK_DATA) {
      return await MockDataService.getMatchDetail(matchId);
    } else {
      return await PaymentApiService.getMatchDetail(matchId);
    }
  }

  /// Create purchase
  static Future<Map<String, dynamic>> createPurchase({
    required int matchId,
    required int kategoriId,
    required String namaLengkap,
    required String email,
    required String nomorTelepon,
    required List<TicketHolder> tickets,
  }) async {
    if (PaymentServiceConfig.USE_MOCK_DATA) {
      return await MockDataService.createPurchase(
        matchId: matchId,
        kategoriId: kategoriId,
        namaLengkap: namaLengkap,
        email: email,
        nomorTelepon: nomorTelepon,
        tickets: tickets,
      );
    } else {
      return await PaymentApiService.createPurchase(
        matchId: matchId,
        kategoriId: kategoriId,
        namaLengkap: namaLengkap,
        email: email,
        nomorTelepon: nomorTelepon,
        tickets: tickets,
      );
    }
  }

  /// Get payment detail
  static Future<Map<String, dynamic>> getPaymentDetail(String orderId) async {
    if (PaymentServiceConfig.USE_MOCK_DATA) {
      return await MockDataService.getPaymentDetail(orderId);
    } else {
      return await PaymentApiService.getPaymentDetail(orderId);
    }
  }

  /// Process payment
  static Future<Map<String, dynamic>> processPayment({
    required String orderId,
    required String metodePembayaran,
    File? buktiTransfer,
  }) async {
    if (PaymentServiceConfig.USE_MOCK_DATA) {
      return await MockDataService.processPayment(
        orderId: orderId,
        metodePembayaran: metodePembayaran,
        buktiTransfer: buktiTransfer,
      );
    } else {
      return await PaymentApiService.processPayment(
        orderId: orderId,
        metodePembayaran: metodePembayaran,
        buktiTransfer: buktiTransfer,
      );
    }
  }

  /// Check voucher
  static Future<Map<String, dynamic>> checkVoucher({
    required String code,
    required double total,
  }) async {
    if (PaymentServiceConfig.USE_MOCK_DATA) {
      return await MockDataService.checkVoucher(
        code: code,
        total: total,
      );
    } else {
      return await PaymentApiService.checkVoucher(
        code: code,
        total: total,
      );
    }
  }
}

