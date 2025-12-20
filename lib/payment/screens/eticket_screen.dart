import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/ticket.dart';
import '../theme/app_colors.dart';

class ETicketScreen extends StatelessWidget {
  final String orderId;
  final String matchTitle;
  final String matchVenue;
  final String matchDate;
  final List<Ticket> tickets;

  const ETicketScreen({
    super.key,
    required this.orderId,
    required this.matchTitle,
    required this.matchVenue,
    required this.matchDate,
    required this.tickets,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Ticket Anda Siap!'),
        backgroundColor: AppColors.brandDarkBlue,
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
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    orderId,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandOrange,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Pertandingan:',
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    matchTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    matchVenue,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    matchDate,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tickets
            ...tickets.asMap().entries.map((entry) {
              final index = entry.key;
              final ticket = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: AppColors.brandLightBlue,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tiket $orderId-${ticket.seat} (${index + 1}/${tickets.length})',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.brandDarkBlue,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Kursi: ${ticket.seat} | Kategori: ${ticket.category}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
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
                              color: Color(0xFF1a237e),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (ticket.qrUrl != null)
                            CachedNetworkImage(
                              imageUrl: ticket.qrUrl!,
                              width: 200,
                              height: 200,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) {
                                // Fallback to QR code generation if image fails
                                if (ticket.qrData != null) {
                                  return QrImageView(
                                    data: ticket.qrData!,
                                    size: 200,
                                    backgroundColor: Colors.white,
                                  );
                                }
                                return const Icon(Icons.error);
                              },
                            )
                          else if (ticket.qrData != null)
                            QrImageView(
                              data: ticket.qrData!,
                              size: 200,
                              backgroundColor: Colors.white,
                            )
                          else
                            const Text('QR Code tidak tersedia'),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandLightBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Tutup',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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

