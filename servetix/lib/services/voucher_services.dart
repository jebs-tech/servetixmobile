import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/voucher.dart';

class VoucherService {
final String baseUrl = "http://127.0.0.1:8000/vouchers/api";

  Future<List<Voucher>> getVouchers() async {
    final response = await http.get(Uri.parse("$baseUrl/list/"));

    final data = jsonDecode(response.body);

    List<Voucher> vouchers = [];

    for (var item in data["vouchers"]) {
      vouchers.add(Voucher.fromJson(item));
    }

    return vouchers;
  }

  Future<Map<String, dynamic>> redeemVoucher(String code) async {
    final response = await http.post(
      Uri.parse("$baseUrl/redeem/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"code": code}),
    );

    return jsonDecode(response.body);
  }
}
