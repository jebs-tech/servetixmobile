import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:servetix/models/dashboard_models.dart';

class PurchaseDetailPage extends StatefulWidget {
  final int matchId; // Kita butuh ID Match untuk fetch detail

  const PurchaseDetailPage({super.key, required this.matchId});

  @override
  State<PurchaseDetailPage> createState() => _PurchaseDetailPageState();
}

class _PurchaseDetailPageState extends State<PurchaseDetailPage> {
  Future<PurchaseDetail>? _detailFuture;

  // URL Helper (Sama seperti dashboard)
  final String _baseUrl = kIsWeb ? "http://127.0.0.1:8000" : "http://10.0.2.2:8000";

  @override
  void initState() {
    super.initState();
    final request = Provider.of<CookieRequest>(context, listen: false);
    _detailFuture = fetchPurchaseDetail(request);
  }

  Future<PurchaseDetail> fetchPurchaseDetail(CookieRequest request) async {
    // Panggil API yang baru kita buat
    final response = await request.get("$_baseUrl/api/purchase/detail/${widget.matchId}/");

    if (response['status'] == true) {
      return PurchaseDetail.fromJson(response['data']);
    } else {
      throw Exception(response['message'] ?? "Gagal mengambil detail pembelian");
    }
  }

  // --- MODAL QR CODE ---
  void _showQrCodeModal(BuildContext context, int ticketId) {
    showDialog(
      context: context,
      builder: (context) => TicketQrDialog(ticketId: ticketId, baseUrl: _baseUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9E6), // Cream background
      appBar: AppBar(
        title: const Text("Detail Tiket"),
        backgroundColor: const Color(0xFF1E293B), // Dark Blue
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<PurchaseDetail>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData) {
            return const Center(child: Text("Data tidak ditemukan"));
          }

          final data = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. INFO PERTANDINGAN
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data.matchTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(children: [
                          const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(data.date),
                        ]),
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(data.venue),
                        ]),
                        const Divider(height: 24),
                        Text("Total Pembelian: Rp ${data.totalPrice}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Text("Daftar Kursi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                // 2. LIST TIKET / KURSI
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: data.tickets.length,
                  itemBuilder: (context, index) {
                    final ticket = data.tickets[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.blue.shade100)),
                      child: ListTile(
                        leading: const Icon(Icons.chair, color: Colors.blue),
                        title: Text("Kursi: ${ticket.seatCode}"),
                        subtitle: Text("${ticket.category} • Rp ${ticket.price}"),
                        trailing: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E293B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          icon: const Icon(Icons.qr_code, size: 18),
                          label: const Text("QR Code"),
                          onPressed: () => _showQrCodeModal(context, ticket.id),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// --- WIDGET MODAL QR CODE TERPISAH ---
class TicketQrDialog extends StatefulWidget {
  final int ticketId;
  final String baseUrl;

  const TicketQrDialog({super.key, required this.ticketId, required this.baseUrl});

  @override
  State<TicketQrDialog> createState() => _TicketQrDialogState();
}

class _TicketQrDialogState extends State<TicketQrDialog> {
  Future<TicketDetail>? _ticketFuture;

  @override
  void initState() {
    super.initState();
    final request = Provider.of<CookieRequest>(context, listen: false);
    _ticketFuture = fetchTicketDetail(request);
  }

  Future<TicketDetail> fetchTicketDetail(CookieRequest request) async {
    final response = await request.get("${widget.baseUrl}/api/ticket/detail/${widget.ticketId}/");
    if (response['status'] == true) {
      return TicketDetail.fromJson(response['data']);
    } else {
      throw Exception("Gagal load tiket");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: FutureBuilder<TicketDetail>(
          future: _ticketFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
            } else if (snapshot.hasError) {
              return SizedBox(height: 150, child: Center(child: Text("Gagal memuat QR Code.\n${snapshot.error}", textAlign: TextAlign.center)));
            }

            final ticket = snapshot.data!;

            // Susun URL Gambar Full
            // Jika ticket.qrCodeUrl sudah lengkap (jarang di Django), pakai langsung.
            // Biasanya Django return "/media/...", jadi harus digabung.
            String fullQrUrl = ticket.qrCodeUrl.startsWith("http")
                ? ticket.qrCodeUrl
                : "${widget.baseUrl}${ticket.qrCodeUrl}";

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("E-Ticket", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue[900])),
                const SizedBox(height: 8),
                Text(ticket.matchTitle, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w500)),
                const Divider(height: 32),

                // Tampilkan Gambar QR Code
                ticket.qrCodeUrl.isEmpty
                    ? const SizedBox(height: 150, child: Center(child: Text("QR Code belum tersedia")))
                    : Image.network(
                  fullQrUrl,
                  height: 200,
                  width: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Column(
                    children: [
                      Icon(Icons.broken_image, size: 50, color: Colors.grey),
                      Text("Gagal memuat gambar", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    children: [
                      const Text("Nomor Kursi", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(ticket.seatCode, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                      Text(ticket.category, style: TextStyle(fontSize: 14, color: Colors.blue[800])),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Tutup"),
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }
}