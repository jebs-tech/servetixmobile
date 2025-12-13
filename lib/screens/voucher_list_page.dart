import 'package:flutter/material.dart';
import '../models/voucher.dart';
import '../services/voucher_service.dart';
import 'voucher_redeem_page.dart';

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

class VoucherListPage extends StatefulWidget {
  const VoucherListPage({super.key});

  @override
  State<VoucherListPage> createState() => _VoucherListPageState();
}

class _VoucherListPageState extends State<VoucherListPage> {
  List<Voucher> _vouchers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final vouchers = await VoucherService.fetchVouchers();
      setState(() {
        _vouchers = vouchers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
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
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: ServeTixColors.cream),
            onPressed: () {},
            tooltip: 'Keranjang',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: ServeTixColors.cream),
            onPressed: () {},
            tooltip: 'Notifikasi',
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: ServeTixColors.cream),
            onPressed: () {},
            tooltip: 'Profil',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: ServeTixColors.yellow,
                foregroundColor: ServeTixColors.navBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: ServeTixColors.lightBlue,
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: $_errorMessage',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadVouchers,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ServeTixColors.lightBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : _vouchers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.card_giftcard,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak ada voucher yang tersedia',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadVouchers,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ServeTixColors.lightBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadVouchers,
                      color: ServeTixColors.lightBlue,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _vouchers.length,
                        itemBuilder: (context, index) {
                          final voucher = _vouchers[index];
                          return _buildVoucherCard(voucher);
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const VoucherRedeemPage(),
            ),
          ).then((_) => _loadVouchers());
        },
        backgroundColor: ServeTixColors.orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text(
          'Redeem Voucher',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildVoucherCard(Voucher voucher) {
    final isExpired = voucher.isExpired;
    final isValid = voucher.isValid;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Blue bar untuk total/diskon (seperti di payment page)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: ServeTixColors.lightBlue,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Diskon Voucher:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  voucher.discountDisplay,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Content card
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kode Voucher
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            voucher.code,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                              color: ServeTixColors.darkBlue,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isValid
                                  ? Colors.green
                                  : isExpired
                                      ? Colors.red
                                      : Colors.orange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isValid
                                  ? 'Aktif'
                                  : isExpired
                                      ? 'Kadaluarsa'
                                      : 'Belum Berlaku',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.grey, thickness: 1),
                const SizedBox(height: 16),
                // Info detail
                Row(
                  children: [
                    Icon(
                      Icons.local_offer,
                      size: 18,
                      color: ServeTixColors.darkBlue,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        voucher.discountType == 'PERCENT'
                            ? 'Diskon ${voucher.value.toStringAsFixed(0)}%'
                            : 'Diskon ${voucher.discountDisplay}',
                        style: TextStyle(
                          fontSize: 15,
                          color: ServeTixColors.darkBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (voucher.minPurchaseAmount > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.shopping_cart,
                        size: 18,
                        color: ServeTixColors.darkBlue,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          voucher.minPurchaseDisplay,
                          style: TextStyle(
                            fontSize: 15,
                            color: ServeTixColors.darkBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: ServeTixColors.darkBlue,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Berlaku hingga: ${_formatDate(voucher.validUntil)}',
                        style: TextStyle(
                          fontSize: 15,
                          color: ServeTixColors.darkBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

