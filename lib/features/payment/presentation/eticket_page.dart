import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../data/models/payment_models.dart';

class ETicketPage extends StatelessWidget {
  final PaymentResponse paymentResponse;

  const ETicketPage({
    Key? key,
    required this.paymentResponse,
  }) : super(key: key);

  static const Color brandDarkBlue = Color(0xFF1e3a5f);
  static const Color brandOrange = Color(0xFFFFA043);
  static const Color brandLightBlue = Color(0xFF4a90a4);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Ticket Anda Siap!'),
        backgroundColor: brandDarkBlue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order ID:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    paymentResponse.orderId ?? '',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: brandOrange,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pertandingan:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    paymentResponse.matchTitle ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (paymentResponse.matchVenue != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      paymentResponse.matchVenue!,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                  if (paymentResponse.matchDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      paymentResponse.matchDate!,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tickets list
            if (paymentResponse.tickets != null &&
                paymentResponse.tickets!.isNotEmpty) ...[
              ...paymentResponse.tickets!.asMap().entries.map((entry) {
                final index = entry.key;
                final ticket = entry.value;
                final ticketNum = index + 1;
                final totalTickets = paymentResponse.tickets!.length;

                return Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: brandLightBlue, width: 2),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ticket header
                      Text(
                        'Tiket ${paymentResponse.orderId}-${ticket.seat} ($ticketNum/$totalTickets)',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: brandDarkBlue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kursi: ${ticket.seat} | Kategori: ${ticket.category}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // QR Code
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'SCAN TIKET ANDA',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: brandDarkBlue,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: QrImageView(
                                data: ticket.qrData,
                                version: QrVersions.auto,
                                size: 200.0,
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ] else ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('Tidak ada tiket ditemukan'),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandLightBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Tutup',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

