import 'match.dart';
import 'seat.dart';

class Pembelian {
  final String orderId;
  final String namaLengkapPembeli;
  final String email;
  final String nomorTelepon;
  final int totalPrice;
  final String status;
  final String statusDisplay;
  final DateTime tanggalPembelian;
  final Match? match;
  final List<Seat> seats;

  Pembelian({
    required this.orderId,
    required this.namaLengkapPembeli,
    required this.email,
    required this.nomorTelepon,
    required this.totalPrice,
    required this.status,
    required this.statusDisplay,
    required this.tanggalPembelian,
    this.match,
    required this.seats,
  });

  factory Pembelian.fromJson(Map<String, dynamic> json) {
    return Pembelian(
      orderId: json['order_id'],
      namaLengkapPembeli: json['nama_lengkap_pembeli'],
      email: json['email'],
      nomorTelepon: json['nomor_telepon'],
      totalPrice: json['total_price'],
      status: json['status'],
      statusDisplay: json['status_display'],
      tanggalPembelian: DateTime.parse(json['tanggal_pembelian']),
      match: json['match'] != null ? Match.fromJson(json['match']) : null,
      seats: (json['seats'] as List?)
              ?.map((seat) => Seat.fromJson(seat))
              .toList() ??
          [],
    );
  }
}

