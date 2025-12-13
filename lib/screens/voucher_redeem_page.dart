import 'package:flutter/material.dart';
import '../services/voucher_service.dart';

// Warna Brand ServeTix
class ServeTixColors {
  static const Color darkBlue = Color(0xFF1a2a4b); // brand-dark-blue
  static const Color lightBlue = Color(0xFF4A69BD); // brand-light-blue
  static const Color orange = Color(0xFFFFA043); // brand-orange
  static const Color gold = Color(0xFFFFC107); // brand-gold
  static const Color cream = Color(0xFFfdf4d9); // cream/yellow light
  static const Color yellow = Color(0xFFf6ca50); // yellow
  static const Color lightYellow = Color(0xFFFADF95); // background light yellow
  static const Color navBlue = Color(0xFF1e2c4f); // nav bar
}

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
      backgroundColor: ServeTixColors.lightYellow,
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'SERVE',
              style: TextStyle(
                color: ServeTixColors.cream,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              '.',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              'TIX',
              style: TextStyle(
                color: ServeTixColors.yellow,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        backgroundColor: ServeTixColors.navBlue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    size: 80,
                    color: ServeTixColors.lightBlue,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Masukkan Kode Voucher',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: ServeTixColors.darkBlue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gunakan voucher Anda untuk mendapatkan diskon',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Voucher Section (seperti di payment page)
                  Text(
                    'Kode Voucher (Opsional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ServeTixColors.darkBlue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _codeController,
                          decoration: InputDecoration(
                            hintText: 'Masukkan Kode Voucher jika ada',
                            border: OutlineInputBorder(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                bottomLeft: Radius.circular(8),
                              ),
                              borderSide: BorderSide(
                                color: ServeTixColors.lightBlue,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                bottomLeft: Radius.circular(8),
                              ),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                bottomLeft: Radius.circular(8),
                              ),
                              borderSide: BorderSide(
                                color: ServeTixColors.lightBlue,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
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
                      ),
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: ServeTixColors.lightBlue,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _redeemVoucher,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Center(
                                child: Text(
                                  'Cek',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
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
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_redeemedVoucher != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                      border: Border.all(
                        color: ServeTixColors.lightBlue.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Blue bar
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: ServeTixColors.lightBlue,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Text(
                            _redeemedVoucher!['code'] ?? '',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.local_offer,
                                    size: 20,
                                    color: ServeTixColors.darkBlue,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _redeemedVoucher!['discount_type'] == 'PERCENT'
                                        ? 'Diskon ${(_redeemedVoucher!['value'] as num).toStringAsFixed(0)}%'
                                        : 'Diskon Rp ${(_redeemedVoucher!['value'] as num).toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: ServeTixColors.darkBlue,
                                    ),
                                  ),
                                ],
                              ),
                              if (_redeemedVoucher!['min_purchase_amount'] != null &&
                                  (_redeemedVoucher!['min_purchase_amount'] as num) > 0) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.shopping_cart,
                                      size: 20,
                                      color: ServeTixColors.darkBlue,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Min. pembelian: Rp ${(_redeemedVoucher!['min_purchase_amount'] as num).toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: ServeTixColors.darkBlue,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: ServeTixColors.orange,
                  foregroundColor: Colors.white,
                  elevation: 2,
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
        ),
      ),
    );
  }
}

