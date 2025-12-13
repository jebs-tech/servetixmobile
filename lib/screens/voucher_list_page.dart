import 'package:flutter/material.dart';
import '../models/voucher.dart';
import '../services/voucher_service.dart';
import 'voucher_redeem_page.dart';

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
      appBar: AppBar(
        title: const Text('Daftar Voucher'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVouchers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadVouchers,
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
                          const Icon(
                            Icons.card_giftcard,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Tidak ada voucher yang tersedia',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadVouchers,
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadVouchers,
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
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Redeem Voucher'),
      ),
    );
  }

  Widget _buildVoucherCard(Voucher voucher) {
    final isExpired = voucher.isExpired;
    final isValid = voucher.isValid;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isValid
              ? LinearGradient(
                  colors: [
                    Colors.blue.shade50,
                    Colors.blue.shade100,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isExpired ? Colors.grey.shade200 : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                          voucher.code,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
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
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isValid ? Colors.blue : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      voucher.discountDisplay,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      voucher.discountType == 'PERCENT'
                          ? 'Diskon ${voucher.value.toStringAsFixed(0)}%'
                          : 'Diskon ${voucher.discountDisplay}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (voucher.minPurchaseAmount > 0)
                Row(
                  children: [
                    const Icon(Icons.shopping_cart, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        voucher.minPurchaseDisplay,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Berlaku hingga: ${_formatDate(voucher.validUntil)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

