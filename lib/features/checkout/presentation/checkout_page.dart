import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

import '../../matches/data/match_api.dart';
import '../../matches/data/match_detail_model.dart';
import '../data/checkout_api.dart'; 
// Pastikan path import ini sesuai dengan struktur folder Anda
import '../../payment/presentation/detail_pembayaran_page.dart';

class PassengerInput {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  String gender = ""; 
  String? selectedCategory;
  int? selectedCategoryId; 
  int price = 0;
  String? seatLabel; 
  int? seatId;

  PassengerInput({this.selectedCategory, this.selectedCategoryId, this.price = 0, this.seatLabel, this.seatId});
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
    _dataFuture = _loadInitialData();
  }

  Future<Map<String, dynamic>> _loadInitialData() async {
    final request = context.read<CookieRequest>();
    
    final match = await MatchApi().fetchMatchDetail(request, widget.matchId);
    final seats = await MatchApi().fetchMatchSeats(request, widget.matchId);
    
    final categoriesMap = <String, Map<String, dynamic>>{};
    for (var s in seats) {
      // FIX 1: Pastikan konversi ke String dan int aman
      String catName = s['category'].toString();
      
      // Handle jika price dikirim sebagai String "50000" atau int 50000
      int priceVal = 0;
      if (s['price'] is int) {
        priceVal = s['price'];
      } else if (s['price'] is String) {
        priceVal = int.tryParse(s['price']) ?? 0;
      }

      categoriesMap[catName] = {
        'id': s['category_id'] ?? 0, 
        'price': priceVal
      };
    }

    _availableCategories = categoriesMap.entries
        .map((e) => {'name': e.key, 'id': e.value['id'], 'price': e.value['price']})
        .toList();

    if (widget.selectedSeatIds.isNotEmpty) {
      for (var sid in widget.selectedSeatIds) {
        // Cari data kursi, gunakan orElse untuk menghindari crash jika tidak ketemu
        final seat = seats.firstWhere((s) => s['id'] == sid, orElse: () => null);
        
        if (seat != null) {
          int priceVal = 0;
          if (seat['price'] is int) priceVal = seat['price'];
          else if (seat['price'] is String) priceVal = int.tryParse(seat['price']) ?? 0;

          _passengers.add(PassengerInput(
            selectedCategory: seat['category'].toString(),
            selectedCategoryId: seat['category_id'],
            price: priceVal,
            seatLabel: seat['label'].toString(),
            seatId: sid,
          ));
        }
      }
    } else {
      _passengers.add(PassengerInput());
    }

    return {'match': match, 'seats': seats};
  }

  int get _totalPrice => _passengers.fold(0, (sum, p) => sum + p.price);

  String _formatCurrency(int amount) {
    return NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0).format(amount);
  }

  // --- LOGIKA SUBMIT YANG DIPERBAIKI ---
  Future<void> _submitCheckout() async {
    final request = context.read<CookieRequest>();

    // 1. Validasi Input
    for (var p in _passengers) {
      if (p.nameController.text.trim().isEmpty || p.selectedCategory == null || p.gender.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Mohon lengkapi Nama, Kategori, dan Jenis Kelamin.")),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final List<Map<String, dynamic>> passengerData = _passengers.map((p) => {
        'name': p.nameController.text,
        'email': p.emailController.text,
        'phone': p.phoneController.text,
        'gender': p.gender,
        'category': p.selectedCategory,
      }).toList();

      Map<String, dynamic> result;
      final api = CheckoutApi();

      if (widget.selectedSeatIds.isNotEmpty) {
        // Mode 1: Booking Kursi Spesifik
        result = await api.bookSeats(
          request,
          matchId: widget.matchId,
          seatIds: widget.selectedSeatIds,
          passengers: passengerData,
        );
      } else {
        // Mode 2: Auto Allocation
        final int catId = _passengers.first.selectedCategoryId ?? 0;
        
        result = await api.saveOrder(
          request,
          matchId: widget.matchId,
          categoryId: catId,
          namaLengkap: _passengers.first.nameController.text,
          email: _passengers.first.emailController.text,
          nomorTelepon: _passengers.first.phoneController.text,
          tickets: passengerData,
        );
      }

      if ((result['status'] == 'success' || result['ok'] == true) && mounted) {
        
        // FIX UTAMA: Ubah order_id menjadi String secara paksa
        final String orderIdStr = result['order_id'].toString(); 

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPembayaranPage(orderId: orderIdStr),
          ),
        );
        
      } else {
        // Handle pesan error yang mungkin bukan string
        throw result['message']?.toString() ?? result['msg']?.toString() ?? "Gagal memproses pesanan.";
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Terjadi kesalahan: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _addTicket() { setState(() => _passengers.add(PassengerInput())); }
  void _removeLastTicket() { if (_passengers.length > 1) setState(() => _passengers.removeLast()); }

  @override
  Widget build(BuildContext context) {
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
                        label: Text("Kembali ke ${match.title}", style: const TextStyle(color: serveNavy)),
                      ),
                      const SizedBox(height: 16),
                      const Text("Detail Pembeli", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: serveNavy)),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white, 
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
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

  // --- WIDGET HELPERS ---

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitCheckout,
        style: ElevatedButton.styleFrom(
          backgroundColor: brandOrange,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        ),
        child: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("Lanjutkan Pembayaran", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              const Flexible(child: Text("Harga per tiket", style: TextStyle(fontSize: 12, color: gray600))),
              Text(_passengers.length == 1 ? _formatCurrency(_passengers[0].price) : "Bervariasi", style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total", style: TextStyle(color: gray600)),
              Text(_formatCurrency(_totalPrice), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: serveNavy)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerForm(int index, PassengerInput input) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Tiket #${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              if (input.seatLabel != null) 
                Text("Kursi: ${input.seatLabel}", style: const TextStyle(color: brandOrange, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField("Nama Lengkap", input.nameController, "Sesuai KTP"),
          const SizedBox(height: 12),
          _buildTextField("Email", input.emailController, "example@mail.com"),
          const SizedBox(height: 12),
          _buildTextField("Nomor Telepon", input.phoneController, "0812..."),
          const SizedBox(height: 16),
          const Text("Jenis Kelamin", style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              _genderButton("Laki-laki", input),
              const SizedBox(width: 8),
              _genderButton("Perempuan", input),
            ],
          ),
          const SizedBox(height: 16),
          const Text("Kategori", style: TextStyle(fontWeight: FontWeight.w600)),
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
              final cat = _availableCategories.firstWhere((c) => c['name'] == val);
              input.selectedCategory = val;
              input.selectedCategoryId = cat['id'];
              input.price = cat['price'];
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
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: gray600)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _genderButton(String value, PassengerInput input) {
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
      ),
      child: Text(label, style: TextStyle(color: isPrimary ? Colors.white : Colors.black, fontSize: 12)),
    );
  }
}