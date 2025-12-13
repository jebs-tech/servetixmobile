import 'package:flutter/material.dart';
import '../services/voucher_service.dart';

class VoucherRedeemPage extends StatefulWidget {
  const VoucherRedeemPage({super.key});

  @override
  State<VoucherRedeemPage> createState() => _VoucherRedeemPageState();
}

class _VoucherRedeemPageState extends State<VoucherRedeemPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  Map<String, dynamic>? _redeemedVoucher;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _redeemVoucher() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
      _redeemedVoucher = null;
    });

    try {
      final result = await VoucherService.redeemVoucher(
        code: _codeController.text.trim(),
        // userId: null, // Optional: bisa ditambahkan jika ada user authentication
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        setState(() {
          _successMessage = result['message'] ?? 'Voucher berhasil digunakan';
          _redeemedVoucher = result['voucher'];
        });
        // Clear form setelah berhasil
        _codeController.clear();
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Gagal menggunakan voucher';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Redeem Voucher'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.qr_code_scanner,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Masukkan Kode Voucher',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Gunakan voucher Anda untuk mendapatkan diskon',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: 'Kode Voucher',
                  hintText: 'Masukkan kode voucher',
                  prefixIcon: const Icon(Icons.card_giftcard),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Kode voucher tidak boleh kosong';
                  }
                  if (value.trim().length < 3) {
                    return 'Kode voucher terlalu pendek';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _redeemVoucher(),
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_successMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: const TextStyle(color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_redeemedVoucher != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade50,
                            Colors.blue.shade100,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _redeemedVoucher!['code'] ?? '',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.local_offer, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                _redeemedVoucher!['discount_type'] == 'PERCENT'
                                    ? 'Diskon ${(_redeemedVoucher!['value'] as num).toStringAsFixed(0)}%'
                                    : 'Diskon Rp ${(_redeemedVoucher!['value'] as num).toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          if (_redeemedVoucher!['min_purchase_amount'] != null &&
                              _redeemedVoucher!['min_purchase_amount'] > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.shopping_cart, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Min. pembelian: Rp ${(_redeemedVoucher!['min_purchase_amount'] as num).toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _redeemVoucher,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Redeem Voucher',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

