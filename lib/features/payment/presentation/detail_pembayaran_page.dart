import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../data/payment_api.dart';
import '../data/models/payment_models.dart';
import 'eticket_page.dart';

class DetailPembayaranPage extends StatefulWidget {
  final String orderId;

  const DetailPembayaranPage({
    Key? key,
    required this.orderId,
  }) : super(key: key);

  @override
  State<DetailPembayaranPage> createState() => _DetailPembayaranPageState();
}

class _DetailPembayaranPageState extends State<DetailPembayaranPage> {
  Pembelian? _pembelian;
  bool _isLoading = true;
  bool _isProcessing = false;

  String? _selectedMetodePembayaran;
  File? _buktiTransferFile;
  final ImagePicker _picker = ImagePicker();

  final _voucherController = TextEditingController();
  double _discountAmount = 0;
  double _finalTotal = 0;
  String? _voucherCodeApplied;

  static const Color brandDarkBlue = Color(0xFF1e3a5f);
  static const Color brandOrange = Color(0xFFFFA043);
  static const Color brandLightBlue = Color(0xFF4a90a4);

  @override
  void initState() {
    super.initState();
    _loadPaymentDetail();
  }

  Future<void> _loadPaymentDetail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final request = context.read<CookieRequest>();
      final pembelian = await PaymentApi.getPaymentDetail(request, widget.orderId);
      
      if (mounted) {
        setState(() {
          _pembelian = pembelian;
          _finalTotal = pembelian?.totalPrice.toDouble() ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }


  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _buktiTransferFile = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _checkVoucher() async {
    if (_voucherController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap masukkan kode voucher')),
      );
      return;
    }

    try {
      final request = context.read<CookieRequest>();
      final response = await PaymentApi.checkVoucher(
        request,
        code: _voucherController.text.trim(),
        total: _finalTotal,
      );

      if (response.status == 'success') {
        setState(() {
          _discountAmount = response.discountAmount ?? 0;
          _finalTotal = response.newTotal ?? _finalTotal;
          _voucherCodeApplied = response.code;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voucher berhasil! Diskon: ${_formatCurrency(_discountAmount)}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Voucher tidak valid'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _prosesPembayaran() async {
    if (_selectedMetodePembayaran == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap pilih metode pembayaran')),
      );
      return;
    }

    final metodeBank = ['BRI', 'BCA', 'Mandiri'];
    if (metodeBank.contains(_selectedMetodePembayaran) && _buktiTransferFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap upload bukti transfer')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final request = context.read<CookieRequest>();
      final response = await PaymentApi.processPayment(
        request,
        orderId: widget.orderId,
        metodePembayaran: _selectedMetodePembayaran!,
        buktiTransferFile: _buktiTransferFile,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        if (response.status == 'success') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ETicketPage(
                paymentResponse: response,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Terjadi kesalahan'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detail Pembayaran'),
          backgroundColor: brandDarkBlue,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_pembelian == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Pembayaran')),
        body: const Center(child: Text('Data pembayaran tidak ditemukan')),
      );
    }

    final metodeBank = ['BRI', 'BCA', 'Mandiri'];
    final metodeQRIS = ['QRIS', 'Gopay'];
    final showBuktiTransfer = _selectedMetodePembayaran != null &&
        metodeBank.contains(_selectedMetodePembayaran);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pembayaran'),
        backgroundColor: brandDarkBlue,
      ),
      body: SingleChildScrollView(
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
                    color: brandDarkBlue,
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
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    _pembelian!.orderId,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: brandOrange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Status Pembayaran:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
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
                color: brandLightBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total yang Harus Dibayar:',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    _formatCurrency(_finalTotal),
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
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _voucherController,
                    decoration: const InputDecoration(
                      hintText: 'Masukkan kode voucher',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _checkVoucher,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandLightBlue,
                  ),
                  child: const Text('Cek'),
                ),
              ],
            ),

            // Discount display
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
                      'Diskon Voucher (${_voucherCodeApplied ?? ""})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      '- ${_formatCurrency(_discountAmount)}',
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
            const SizedBox(height: 24),

            // Payment method selection
            const Text(
              'Pilih Metode Pembayaran',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Metode Pembayaran',
                border: OutlineInputBorder(),
              ),
              value: _selectedMetodePembayaran,
              items: const [
                DropdownMenuItem(value: 'BRI', child: Text('BRI')),
                DropdownMenuItem(value: 'BCA', child: Text('BCA')),
                DropdownMenuItem(value: 'Mandiri', child: Text('Mandiri')),
                DropdownMenuItem(value: 'Gopay', child: Text('GoPay')),
                DropdownMenuItem(value: 'QRIS', child: Text('QRIS')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedMetodePembayaran = value;
                  if (!metodeBank.contains(value)) {
                    _buktiTransferFile = null;
                  }
                });
              },
            ),

            // QRIS Display
            if (_selectedMetodePembayaran != null &&
                metodeQRIS.contains(_selectedMetodePembayaran)) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Scan QR Code untuk Pembayaran',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/qris.png',
                          width: 200,
                          height: 200,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback jika gambar tidak ditemukan
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.qr_code, size: 100),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Bukti transfer upload
            if (showBuktiTransfer) ...[
              const SizedBox(height: 24),
              const Text(
                'Upload Bukti Transfer',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              if (_buktiTransferFile != null) ...[
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _buktiTransferFile!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.upload_file),
                label: Text(_buktiTransferFile == null
                    ? 'Pilih File Bukti Transfer'
                    : 'Ganti File'),
              ),
              const SizedBox(height: 8),
              Text(
                'Format: JPG, PNG, atau GIF (maks. 5MB)',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],

            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isProcessing ||
                        _selectedMetodePembayaran == null ||
                        (showBuktiTransfer && _buktiTransferFile == null))
                    ? null
                    : _prosesPembayaran,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Selesaikan Pembayaran',
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

