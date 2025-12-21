// lib/features/payment/data/models/payment_models.dart

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
      name: json['name']?.toString() ?? 'Unknown',
      // Pastikan price selalu int, meskipun server mengirim string
      price: json['price'] is String ? int.tryParse(json['price']) ?? 0 : json['price'] ?? 0,
      color: json['color']?.toString() ?? '#d3a15a',
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
      // [PENTING] Gunakan .toString() di sini untuk mencegah error Int vs String
      orderId: json['order_id']?.toString() ?? '', 
      namaLengkapPembeli: json['nama_lengkap_pembeli']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      // Nomor telepon sering dikirim sebagai Int oleh Django, paksa jadi String
      nomorTelepon: json['nomor_telepon']?.toString() ?? '', 
      
      // Handle Total Price (bisa Int atau String angka)
      totalPrice: json['total_price'] is String 
          ? int.tryParse(json['total_price']) ?? 0 
          : json['total_price'] ?? 0,
          
      status: json['status']?.toString() ?? '',
      statusDisplay: json['status_display']?.toString() ?? '',
      metodePembayaran: json['metode_pembayaran']?.toString(),
      tanggalPembelian: json['tanggal_pembelian']?.toString(),
      match: json['match'] != null ? MatchInfo.fromJson(json['match']) : null,
      kodeVoucher: json['kode_voucher']?.toString(),
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
      title: json['title']?.toString() ?? 'Unknown Match',
      venue: json['venue']?.toString(),
      startTime: json['start_time']?.toString(),
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
      // Seat mungkin angka (misal: 101), paksa jadi string
      seat: json['seat']?.toString() ?? '', 
      category: json['category']?.toString() ?? '',
      qrUrl: json['qr_url']?.toString(),
      qrData: json['qr_data']?.toString() ?? '',
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
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString(),
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
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString(),
      discountAmount: json['discount_amount'] is int 
          ? (json['discount_amount'] as int).toDouble() 
          : json['discount_amount']?.toDouble(),
      newTotal: json['new_total'] is int 
          ? (json['new_total'] as int).toDouble() 
          : json['new_total']?.toDouble(),
      code: json['code']?.toString(),
    );
  }
}