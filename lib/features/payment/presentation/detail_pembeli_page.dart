import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

// Import yang BENAR
import '../data/payment_api.dart';
import '../data/models/payment_models.dart';
import '../../matches/data/match_api.dart';
import '../../matches/data/match_detail_model.dart';
import 'detail_pembayaran_page.dart';

class DetailPembeliPage extends StatefulWidget {
  final int matchId;
  final List<int> selectedSeatIds; 

  const DetailPembeliPage({
    Key? key,
    required this.matchId,
    this.selectedSeatIds = const [], 
  }) : super(key: key);

  @override
  State<DetailPembeliPage> createState() => _DetailPembeliPageState();
}

class _DetailPembeliPageState extends State<DetailPembeliPage> {
  final _formKey = GlobalKey<FormState>();
  
  final _namaLengkapController = TextEditingController();
  final _emailController = TextEditingController();
  final _nomorTeleponController = TextEditingController();
  
  final List<TextEditingController> _namaTiketControllers = [];
  final List<String> _jenisKelaminList = [];

  MatchDetail? _match;
  List<SeatCategory> _categories = [];
  SeatCategory? _selectedCategory;
  
  int _jumlahTiket = 1;
  bool _isLoading = false;
  bool _isLoadingData = true;

  static const Color brandDarkBlue = Color(0xFF1e3a5f);
  static const Color brandOrange = Color(0xFFFFA043);

  @override
  void initState() {
    super.initState();
    _initForm();
    _loadData();
  }

  void _initForm() {
    if (widget.selectedSeatIds.isNotEmpty) {
      _jumlahTiket = widget.selectedSeatIds.length;
    } else {
      _jumlahTiket = 1;
    }

    for (int i = 0; i < _jumlahTiket; i++) {
      _namaTiketControllers.add(TextEditingController());
      _jenisKelaminList.add('L'); 
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    try {
      final request = context.read<CookieRequest>();
      final results = await Future.wait([
        MatchApi().fetchMatchDetail(request, widget.matchId),
        PaymentApi.getCategories(request),
      ]);

      if (mounted) {
        setState(() {
          _match = results[0] as MatchDetail;
          _categories = results[1] as List<SeatCategory>;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _tambahTiket() {
    if (widget.selectedSeatIds.isNotEmpty) return;
    if (_jumlahTiket < 5) {
      setState(() {
        _jumlahTiket++;
        _namaTiketControllers.add(TextEditingController());
        _jenisKelaminList.add('L');
      });
    }
  }

  void _kurangTiket() {
    if (widget.selectedSeatIds.isNotEmpty) return;
    if (_jumlahTiket > 1) {
      setState(() {
        _jumlahTiket--;
        _namaTiketControllers.last.dispose();
        _namaTiketControllers.removeLast();
        _jenisKelaminList.removeLast();
      });
    }
  }

  void _showKonfirmasiDialog() {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap lengkapi semua data')));
      return;
    }

    final totalHarga = _jumlahTiket * _selectedCategory!.price;
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Pembelian'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Tiket: $_jumlahTiket'),
            Text('Kategori: ${_selectedCategory!.name}'),
            const Divider(),
            Text('Total Bayar: ${formatCurrency.format(totalHarga)}', 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _prosesBooking();
            },
            child: const Text('Bayar Sekarang'),
          ),
        ],
      ),
    );
  }

  // --- BAGIAN KRUSIAL PENYELESAIAN ERROR ---
  Future<void> _prosesBooking() async {
    setState(() => _isLoading = true);

    try {
      final request = context.read<CookieRequest>();
      
      // 1. Siapkan List Tiket yang BERSIH
      // Pastikan Key sesuai dengan apa yang Django harapkan di views.py
      final List<Map<String, dynamic>> ticketsPayload = [];
      
      for (int i = 0; i < _jumlahTiket; i++) {
        final ticketData = {
          'nama': _namaTiketControllers[i].text,
          'jenis_kelamin': _jenisKelaminList[i],
          // Jangan kirim data lain yang tidak diminta PaymentApi
        };
        ticketsPayload.add(ticketData);
      }

      // 2. Panggil API
      final result = await PaymentApi.savePembelian(
        request,
        matchId: widget.matchId,
        kategoriId: _selectedCategory!.id,
        namaLengkap: _namaLengkapController.text,
        email: _emailController.text,
        nomorTelepon: _nomorTeleponController.text,
        tickets: ticketsPayload,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (result['status'] == 'success') {
          // [FIX] Konversi order_id ke String agar tidak TypeError
          final String orderIdStr = result['order_id'].toString();
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DetailPembayaranPage(orderId: orderIdStr),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message']?.toString() ?? 'Gagal memproses'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void dispose() {
    _namaLengkapController.dispose();
    _emailController.dispose();
    _nomorTeleponController.dispose();
    for (var c in _namaTiketControllers) c.dispose();
    super.dispose();
  }

  String _formatCurrency(int amount) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) return Scaffold(appBar: AppBar(title: const Text('Detail Pembeli')), body: const Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pembeli'), backgroundColor: brandDarkBlue),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_match != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue[50],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_match!.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('${_match!.venue} • ${_match!.formattedDate}'),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<SeatCategory>(
                decoration: const InputDecoration(labelText: 'Kategori Tiket', border: OutlineInputBorder()),
                value: _selectedCategory,
                items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text('${cat.name} - ${_formatCurrency(cat.price)}'))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
                validator: (val) => val == null ? 'Wajib dipilih' : null,
              ),
              
              const SizedBox(height: 20),
              const Text('Informasi Kontak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _namaLengkapController,
                decoration: const InputDecoration(labelText: 'Nama Lengkap', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Isi nama' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nomorTeleponController,
                decoration: const InputDecoration(labelText: 'No. Telepon', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),

              ...List.generate(_jumlahTiket, (index) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Penumpang ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextFormField(
                      controller: _namaTiketControllers[index],
                      decoration: InputDecoration(labelText: 'Nama Penumpang'),
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    Row(
                      children: [
                        Radio<String>(value: 'L', groupValue: _jenisKelaminList[index], onChanged: (v) => setState(() => _jenisKelaminList[index] = v!)),
                        const Text('Laki-laki'),
                        Radio<String>(value: 'P', groupValue: _jenisKelaminList[index], onChanged: (v) => setState(() => _jenisKelaminList[index] = v!)),
                        const Text('Perempuan'),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                );
              }),

              if (widget.selectedSeatIds.isEmpty)
                Row(children: [
                  if (_jumlahTiket < 5) TextButton.icon(onPressed: _tambahTiket, icon: const Icon(Icons.add), label: const Text('Tambah')),
                  if (_jumlahTiket > 1) TextButton.icon(onPressed: _kurangTiket, icon: const Icon(Icons.remove), label: const Text('Kurang')),
                ]),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _showKonfirmasiDialog,
                  style: ElevatedButton.styleFrom(backgroundColor: brandOrange, padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Lanjutkan Pembayaran', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}