import 'dart:convert';
import 'package:http/http.dart' as http;
import 'match_detail_model.dart';

class MatchApi {
  Future<MatchDetail> fetchMatchDetail(int id) async {
    final response = await http.get(
      Uri.parse('http://127.0.0.1:8000/api/matches/$id/'),
    );

    if (response.statusCode == 200) {
      return MatchDetail.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load match');
    }
  }
}
