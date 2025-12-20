import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../payment/models/pembelian.dart';
import '../payment/models/ticket.dart';
import '../payment/services/payment_api_service.dart';
import '../payment/theme/app_colors.dart';
import 'eticket_screen.dart';

class DetailPembayaranScreen extends StatefulWidget {
  final String orderId;

  const DetailPembayaranScreen({super.key, required this.orderId});

  @override
  State<DetailPembayaranScreen> createState() => _DetailPembayaranScreenState();
}

class _DetailPembayaranScreenState extends State<DetailPembayaranScreen> {
  Pembelian? _pembelian;
  bool _isLoading = true;
  String? _errorMessage;

  String? _selectedMetodePembayaran;
  File? _buktiTransfer;
  final ImagePicker _picker = ImagePicker();

  String? _voucherCode;
  double _discountAmount = 0;
  double _finalTotal = 0;

  @override
  void initState() {
    super.initState();
    _loadPaymentDetail();
  }

  Future<void> _loadPaymentDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await PaymentApiService.getPaymentDetail(widget.orderId);

    if (result['status'] == 'success') {
      setState(() {
        _pembelian = result['pembelian'];
        _finalTotal = _pembelian!.totalPrice.toDouble();
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['message'];
        _isLoading = false;
      });
    }
  }

  String _formatRupiah(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        // Check file size (max 5MB)
        final file = File(image.path);
        final fileSize = await file.length();
        if (fileSize > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ukuran file terlalu besar. Maksimal 5MB.'),
              ),
            );
          }
          return;
        }

        setState(() {
          _buktiTransfer = file;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error mengambil gambar: $e')),
        );
      }
    }
  }

  Future<void> _checkVoucher() async {
    if (_voucherCode == null || _voucherCode!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan kode voucher')),
      );
      return;
    }

    final result = await PaymentApiService.checkVoucher(
      code: _voucherCode!,
      total: _pembelian!.totalPrice.toDouble(),
    );

    if (result['status'] == 'success') {
      setState(() {
        _discountAmount = result['discountAmount'];
        _finalTotal = result['newTotal'];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Voucher berhasil diterapkan! Diskon: ${_formatRupiah(_discountAmount)}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _processPayment() async {
    if (_selectedMetodePembayaran == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih metode pembayaran terlebih dahulu')),
      );
      return;
    }

    final metodeBank = ['BRI', 'BCA', 'Mandiri'];
    if (metodeBank.contains(_selectedMetodePembayaran) && _buktiTransfer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload bukti transfer terlebih dahulu')),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await PaymentApiService.processPayment(
      orderId: widget.orderId,
      metodePembayaran: _selectedMetodePembayaran!,
      buktiTransfer: _buktiTransfer,
    );

    // Hide loading
    if (mounted) Navigator.pop(context);

    if (result['status'] == 'success') {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ETicketScreen(
              orderId: result['orderId'],
              matchTitle: result['matchTitle'],
              matchVenue: result['matchVenue'],
              matchDate: result['matchDate'],
              tickets: result['tickets'],
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pembayaran'),
        backgroundColor: AppColors.brandDarkBlue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPaymentDetail,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : _pembelian == null
                  ? const Center(child: Text('Data tidak ditemukan'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Progress indicator
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '1. Detail Pembeli',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const Text(
                                '2. Detail Pembayaran',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.brandDarkBlue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Order ID and status
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Order ID Anda:',
                                  style: TextStyle(fontSize: 12),
                                ),
                                Text(
                                  _pembelian!.orderId,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.brandOrange,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Status Pembayaran:',
                                  style: TextStyle(fontSize: 12),
                                ),
                                Text(
                                  _pembelian!.statusDisplay,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Total payment
                          const Text(
                            'Total Pembayaran',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.brandLightBlue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total yang Harus Dibayar:',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  _formatRupiah(_finalTotal),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Voucher section
                          const Text(
                            'Kode Voucher (Opsional)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: const InputDecoration(
                                    hintText: 'Masukkan kode voucher',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _voucherCode = value;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _checkVoucher,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.brandLightBlue,
                                ),
                                child: const Text('Cek'),
                              ),
                            ],
                          ),
                          if (_discountAmount > 0) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                border: Border.all(color: Colors.green[200]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Diskon Voucher ($_voucherCode)',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Text(
                                    '- ${_formatRupiah(_discountAmount)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          const Divider(),

                          // Payment method
                          const Text(
                            'Pilih Metode Pembayaran',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedMetodePembayaran,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              hintText: 'Pilih metode...',
                            ),
                            items: const [
                              DropdownMenuItem(value: 'BRI', child: Text('BRI')),
                              DropdownMenuItem(value: 'BCA', child: Text('BCA')),
                              DropdownMenuItem(
                                value: 'Mandiri',
                                child: Text('Mandiri'),
                              ),
                              DropdownMenuItem(
                                value: 'Gopay',
                                child: Text('GoPay'),
                              ),
                              DropdownMenuItem(value: 'QRIS', child: Text('QRIS')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedMetodePembayaran = value;
                                if (value != 'BRI' &&
                                    value != 'BCA' &&
                                    value != 'Mandiri') {
                                  _buktiTransfer = null;
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // QRIS display
                          if (_selectedMetodePembayaran == 'QRIS' ||
                              _selectedMetodePembayaran == 'Gopay')
                            Center(
                              child: Image.asset(
                                'assets/images/qris.png',
                                width: 200,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 200,
                                    height: 200,
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: Text('QRIS Image'),
                                    ),
                                  );
                                },
                              ),
                            ),

                          // Proof of transfer upload
                          if (_selectedMetodePembayaran == 'BRI' ||
                              _selectedMetodePembayaran == 'BCA' ||
                              _selectedMetodePembayaran == 'Mandiri') ...[
                            const Text(
                              'Upload Bukti Transfer *',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_buktiTransfer != null)
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _buktiTransfer!,
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () {
                                        setState(() {
                                          _buktiTransfer = null;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              )
                            else
                              OutlinedButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(Icons.upload_file),
                                label: const Text('Pilih Gambar'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.all(16),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              'Format: JPG, PNG, atau GIF (maks. 5MB)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),

                          // Submit button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _selectedMetodePembayaran != null &&
                                      (_selectedMetodePembayaran == 'QRIS' ||
                                          _selectedMetodePembayaran == 'Gopay' ||
                                          _buktiTransfer != null)
                                  ? _processPayment
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brandOrange,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                disabledBackgroundColor: Colors.grey[400],
                              ),
                              child: const Text(
                                'Selesaikan Pembayaran',
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

