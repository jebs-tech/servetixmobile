// Models untuk Payment Module

class SeatCategory {
  final int id;
  final String name;
  final int price;
  final String color;

  SeatCategory({
    required this.id,
    required this.name,
    required this.price,
    required this.color,
  });

  factory SeatCategory.fromJson(Map<String, dynamic> json) {
    return SeatCategory(
      id: json['id'],
      name: json['name'],
      price: json['price'],
      color: json['color'] ?? '#d3a15a',
    );
  }
}

class Pembelian {
  final String orderId;
  final String namaLengkapPembeli;
  final String email;
  final String nomorTelepon;
  final int totalPrice;
  final String status;
  final String statusDisplay;
  final String? metodePembayaran;
  final String? tanggalPembelian;
  final MatchInfo? match;
  final String? kodeVoucher;

  Pembelian({
    required this.orderId,
    required this.namaLengkapPembeli,
    required this.email,
    required this.nomorTelepon,
    required this.totalPrice,
    required this.status,
    required this.statusDisplay,
    this.metodePembayaran,
    this.tanggalPembelian,
    this.match,
    this.kodeVoucher,
  });

  factory Pembelian.fromJson(Map<String, dynamic> json) {
    return Pembelian(
      orderId: json['order_id']?.toString() ?? '',
      namaLengkapPembeli: json['nama_lengkap_pembeli'] ?? '',
      email: json['email'] ?? '',
      nomorTelepon: json['nomor_telepon'] ?? '',
      totalPrice: json['total_price'] ?? 0,
      status: json['status'] ?? '',
      statusDisplay: json['status_display'] ?? '',
      metodePembayaran: json['metode_pembayaran'],
      tanggalPembelian: json['tanggal_pembelian'],
      match: json['match'] != null ? MatchInfo.fromJson(json['match']) : null,
      kodeVoucher: json['kode_voucher'],
    );
  }
}

class MatchInfo {
  final int id;
  final String title;
  final String? venue;
  final String? startTime;

  MatchInfo({
    required this.id,
    required this.title,
    this.venue,
    this.startTime,
  });

  factory MatchInfo.fromJson(Map<String, dynamic> json) {
    return MatchInfo(
      id: json['id'],
      title: json['title'],
      venue: json['venue'],
      startTime: json['start_time'],
    );
  }
}

class Ticket {
  final int seatId;
  final String seat;
  final String category;
  final String? qrUrl;
  final String qrData;

  Ticket({
    required this.seatId,
    required this.seat,
    required this.category,
    this.qrUrl,
    required this.qrData,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      seatId: json['seat_id'],
      seat: json['seat'],
      category: json['category'],
      qrUrl: json['qr_url'],
      qrData: json['qr_data'],
    );
  }
}

class PaymentResponse {
  final String status;
  final String? message;
  final String? orderId;
  final String? matchTitle;
  final String? matchVenue;
  final String? matchDate;
  final List<Ticket>? tickets;

  PaymentResponse({
    required this.status,
    this.message,
    this.orderId,
    this.matchTitle,
    this.matchVenue,
    this.matchDate,
    this.tickets,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    List<Ticket>? ticketsList;
    if (json['data'] != null && json['data']['tickets'] != null) {
      ticketsList = (json['data']['tickets'] as List)
          .map((t) => Ticket.fromJson(t))
          .toList();
    }

    return PaymentResponse(
      status: json['status'] ?? '',
      message: json['message'],
      orderId: json['data']?['order_id']?.toString(),
      matchTitle: json['data']?['match_title']?.toString(),
      matchVenue: json['data']?['match_venue']?.toString(),
      matchDate: json['data']?['match_date']?.toString(),
      tickets: ticketsList,
    );
  }
}

class VoucherResponse {
  final String status;
  final String? message;
  final double? discountAmount;
  final double? newTotal;
  final String? code;

  VoucherResponse({
    required this.status,
    this.message,
    this.discountAmount,
    this.newTotal,
    this.code,
  });

  factory VoucherResponse.fromJson(Map<String, dynamic> json) {
    return VoucherResponse(
      status: json['status'],
      message: json['message'],
      discountAmount: json['discount_amount']?.toDouble(),
      newTotal: json['new_total']?.toDouble(),
      code: json['code'],
    );
  }
}

