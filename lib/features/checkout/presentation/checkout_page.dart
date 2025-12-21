import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; //
import 'package:pbp_django_auth/pbp_django_auth.dart'; //

import '../../matches/data/match_api.dart';
import '../../matches/data/match_detail_model.dart';
import '../data/checkout_api.dart'; // Pastikan path ke checkout_api.dart benar

// Model sederhana untuk menampung data input tiap tiket
class PassengerInput {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  String gender = ""; // "Laki-laki" atau "Perempuan"
  String? selectedCategory;
  int price = 0;
  String? seatLabel; 
  int? seatId;

  PassengerInput({this.selectedCategory, this.price = 0, this.seatLabel, this.seatId});
}

class CheckoutPage extends StatefulWidget {
  final int matchId;
  final List<int> selectedSeatIds; 

  const CheckoutPage({
    super.key,
    required this.matchId,
    required this.selectedSeatIds,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  static const Color serveNavy = Color(0xFF1A2A4B);
  static const Color brandOrange = Color(0xFFFFA043);
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray600 = Color(0xFF4B5563);

  late Future<Map<String, dynamic>> _dataFuture;
  List<PassengerInput> _passengers = [];
  List<dynamic> _availableCategories = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Mengambil data awal menggunakan instance request dari context
    _dataFuture = _loadInitialData();
  }

  Future<Map<String, dynamic>> _loadInitialData() async {
    // Mengambil CookieRequest dari Provider
    final request = context.read<CookieRequest>();
    
    // Sinkronisasi dengan update MatchApi yang membutuhkan parameter request
    final match = await MatchApi().fetchMatchDetail(request, widget.matchId);
    final seats = await MatchApi().fetchMatchSeats(request, widget.matchId);
    
    final categories = <String, int>{};
    for (var s in seats) {
      categories[s['category']] = s['price'];
    }

    _availableCategories = categories.entries
        .map((e) => {'name': e.key, 'price': e.value})
        .toList();

    if (widget.selectedSeatIds.isNotEmpty) {
      for (var sid in widget.selectedSeatIds) {
        final seat = seats.firstWhere((s) => s['id'] == sid);
        _passengers.add(PassengerInput(
          selectedCategory: seat['category'],
          price: seat['price'],
          seatLabel: seat['label'],
          seatId: sid,
        ));
      }
    } else {
      _passengers.add(PassengerInput());
    }

    return {'match': match, 'seats': seats};
  }

  int get _totalPrice {
    return _passengers.fold(0, (sum, p) => sum + p.price);
  }

  String _formatCurrency(int amount) {
    return NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0)
        .format(amount);
  }

  // --- LOGIKA SUBMIT KE API MENGGUNAKAN COOKIEREQUEST ---
  Future<void> _submitCheckout() async {
    final request = context.read<CookieRequest>();

    // Validasi input
    for (var p in _passengers) {
      if (p.nameController.text.isEmpty || p.selectedCategory == null || p.gender.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Mohon lengkapi data semua tiket.")),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      // Menyiapkan data penumpang untuk payload API
      final List<Map<String, dynamic>> passengerData = _passengers.map((p) => {
        'name': p.nameController.text,
        'email': p.emailController.text,
        'phone': p.phoneController.text,
        'gender': p.gender,
        'category': p.selectedCategory,
      }).toList();

      Map<String, dynamic> result;

      if (widget.selectedSeatIds.isNotEmpty) {
        // Gunakan CheckoutApi untuk booking kursi spesifik
        result = await CheckoutApi().bookSeats(
          request,
          matchId: widget.matchId,
          seatIds: widget.selectedSeatIds,
          passengers: passengerData,
        );
      } else {
        // Gunakan CheckoutApi untuk booking berdasarkan jumlah
        result = await CheckoutApi().bookQuantity(
          request,
          matchId: widget.matchId,
          passengers: passengerData,
        );
      }

      // Mengecek flag 'ok' atau 'success' sesuai response dari views.py Django
      if ((result['ok'] == true || result['status'] == 'success') && mounted) {
        _showSuccessDialog();
      } else {
        throw result['msg'] ?? result['detail'] ?? "Gagal memproses pesanan.";
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan: $e")),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Berhasil!"),
        content: const Text("Pesanan Anda telah berhasil dibuat. Silakan cek menu pesanan untuk detail pembayaran."),
        actions: [
          TextButton(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst), 
            child: const Text("OK")
          )
        ],
      ),
    );
  }

  // ... (Widget Builder dan Helper UI tetap sama seperti kode Anda sebelumnya) ...

  void _addTicket() { setState(() => _passengers.add(PassengerInput())); }
  void _removeLastTicket() { if (_passengers.length > 1) setState(() => _passengers.removeLast()); }

  @override
  Widget build(BuildContext context) {
    // UI Code (Tetap sama seperti yang Anda berikan)
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: brandOrange));
          }
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));

          final MatchDetail match = snapshot.data!['match'];

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, size: 16, color: serveNavy),
                        label: Text("Kembali ke ${match.title}", style: const TextStyle(color: serveNavy, fontSize: 14)),
                      ),
                      const SizedBox(height: 16),
                      const Text("Detail Pembeli", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: serveNavy)),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
                        ),
                        child: Column(
                          children: [
                            ..._passengers.asMap().entries.map((entry) => _buildPassengerForm(entry.key, entry.value)).toList(),
                            if (widget.selectedSeatIds.isEmpty)
                              Row(
                                children: [
                                  _actionButton(label: "➕ Tambah Tiket", onPressed: _addTicket, isPrimary: true),
                                  const SizedBox(width: 8),
                                  _actionButton(label: "🗑️ Hapus", onPressed: _removeLastTicket, isPrimary: false),
                                  const Spacer(),
                                  Text("${_passengers.length} tiket", style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                            const SizedBox(height: 24),
                            _buildPriceSummary(),
                            const SizedBox(height: 32),
                            _buildSubmitButton(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: gray50, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(child: Text("Harga per tiket (berdasarkan kategori)", style: TextStyle(fontSize: 12, color: gray600))),
              Text(_passengers.length == 1 ? _formatCurrency(_passengers[0].price) : "Terlampir", style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total", style: TextStyle(color: gray600)),
              Text(_formatCurrency(_totalPrice), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitCheckout,
        style: ElevatedButton.styleFrom(
          backgroundColor: brandOrange,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("Lanjutkan Pembayaran", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  // (Helper widget _buildPassengerForm, _buildTextField, _genderButton, _actionButton diletakkan di sini...)
  // ... (Sesuai dengan kode UI Anda sebelumnya) ...
  
  Widget _buildPassengerForm(int index, PassengerInput input) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Tiket #${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(input.seatLabel != null ? "Kursi: ${input.seatLabel}" : "Isilah data pembeli", style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField("Nama Lengkap", input.nameController, "Nama sesuai KTP"),
          const SizedBox(height: 12),
          _buildTextField("Email (opsional)", input.emailController, "example@mail.com"),
          const SizedBox(height: 12),
          _buildTextField("Nomor Telepon (opsional)", input.phoneController, "0812..."),
          const SizedBox(height: 16),
          const Text("Jenis Kelamin", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              _genderButton("Laki-laki", input, index),
              const SizedBox(width: 8),
              _genderButton("Perempuan", input, index),
            ],
          ),
          const SizedBox(height: 16),
          const Text("Kategori Tempat Duduk", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _buildCategoryDropdown(input),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown(PassengerInput input) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: input.selectedCategory,
          hint: const Text("Pilih kategori"),
          onChanged: input.seatId != null ? null : (val) {
            setState(() {
              input.selectedCategory = val;
              input.price = _availableCategories.firstWhere((c) => c['name'] == val)['price'];
            });
          },
          items: _availableCategories.map((cat) {
            return DropdownMenuItem<String>(
              value: cat['name'],
              child: Text("${cat['name']} — ${_formatCurrency(cat['price'])}"),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          ),
        ),
      ],
    );
  }

  Widget _genderButton(String value, PassengerInput input, int index) {
    bool isSelected = input.gender == value;
    return Expanded(
      child: OutlinedButton(
        onPressed: () => setState(() => input.gender = value),
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? brandOrange : Colors.white,
          side: BorderSide(color: isSelected ? brandOrange : Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        ),
        child: Text(value, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontSize: 13)),
      ),
    );
  }

  Widget _actionButton({required String label, required VoidCallback onPressed, required bool isPrimary}) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: isPrimary ? brandOrange : Colors.white,
        side: BorderSide(color: isPrimary ? brandOrange : Colors.grey.shade300),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      child: Text(label, style: TextStyle(color: isPrimary ? Colors.white : Colors.black, fontSize: 12)),
    );
  }
}