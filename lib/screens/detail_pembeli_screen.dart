import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../payment/models/match.dart';
import '../payment/models/seat_category.dart';
import '../payment/models/ticket_holder.dart';
import '../payment/services/payment_api_service.dart';
import '../payment/theme/app_colors.dart';
import 'detail_pembayaran_screen.dart';

class DetailPembeliScreen extends StatefulWidget {
  final int matchId;

  const DetailPembeliScreen({super.key, required this.matchId});

  @override
  State<DetailPembeliScreen> createState() => _DetailPembeliScreenState();
}

class _DetailPembeliScreenState extends State<DetailPembeliScreen> {
  Match? _match;
  List<SeatCategory> _categories = [];
  SeatCategory? _selectedCategory;
  int _maxTiketPerTransaksi = 5;
  bool _isLoading = true;
  String? _errorMessage;

  // Form controllers
  final _namaLengkapController = TextEditingController();
  final _emailController = TextEditingController();
  final _nomorTeleponController = TextEditingController();
  final List<TextEditingController> _namaTiketControllers = [];
  final List<String> _jenisKelaminList = ['L'];

  int _jumlahTiket = 1;

  @override
  void initState() {
    super.initState();
    _loadMatchDetail();
    _namaTiketControllers.add(TextEditingController());
  }

  Future<void> _loadMatchDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await PaymentApiService.getMatchDetail(widget.matchId);

    if (result['status'] == 'success') {
      setState(() {
        _match = result['match'];
        _categories = result['categories'];
        _maxTiketPerTransaksi = result['maxTiketPerTransaksi'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['message'];
        _isLoading = false;
      });
    }
  }

  void _addTicket() {
    if (_jumlahTiket < _maxTiketPerTransaksi) {
      setState(() {
        _jumlahTiket++;
        _namaTiketControllers.add(TextEditingController());
        _jenisKelaminList.add('L');
      });
    }
  }

  void _removeTicket(int index) {
    if (_jumlahTiket > 1) {
      setState(() {
        _jumlahTiket--;
        _namaTiketControllers[index].dispose();
        _namaTiketControllers.removeAt(index);
        _jenisKelaminList.removeAt(index);
      });
    }
  }

  String _formatRupiah(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  Future<void> _handleKonfirmasi() async {
    // Validasi
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap pilih kategori tempat duduk')),
      );
      return;
    }

    if (_namaLengkapController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _nomorTeleponController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi semua kolom wajib')),
      );
      return;
    }

    // Validasi nama tiket
    for (int i = 0; i < _namaTiketControllers.length; i++) {
      if (_namaTiketControllers[i].text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Harap isi nama untuk tiket ${i + 1}')),
        );
        return;
      }
    }

    // Tampilkan dialog konfirmasi
    final totalHarga = _jumlahTiket * _selectedCategory!.price;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Pembelian'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Tiket: $_jumlahTiket'),
            Text('Kategori Kursi: ${_selectedCategory!.name}'),
            const SizedBox(height: 8),
            Text(
              'Total Harga: ${_formatRupiah(totalHarga)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lanjutkan ke Pembayaran'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _createPurchase();
    }
  }

  Future<void> _createPurchase() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Prepare tickets
    final tickets = <TicketHolder>[];
    for (int i = 0; i < _namaTiketControllers.length; i++) {
      tickets.add(TicketHolder(
        nama: _namaTiketControllers[i].text,
        jenisKelamin: _jenisKelaminList[i],
      ));
    }

    final result = await PaymentApiService.createPurchase(
      matchId: widget.matchId,
      kategoriId: _selectedCategory!.id,
      namaLengkap: _namaLengkapController.text,
      email: _emailController.text,
      nomorTelepon: _nomorTeleponController.text,
      tickets: tickets,
    );

    // Hide loading
    if (mounted) Navigator.pop(context);

    if (result['status'] == 'success') {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPembayaranScreen(
              orderId: result['orderId'],
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
  void dispose() {
    _namaLengkapController.dispose();
    _emailController.dispose();
    _nomorTeleponController.dispose();
    for (var controller in _namaTiketControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pembeli'),
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
                        onPressed: _loadMatchDetail,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '1. Detail Pembeli',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1a237e),
                            ),
                          ),
                          Text(
                            '2. Detail Pembayaran',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Match info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.yellow[100],
                          border: Border(
                            left: BorderSide(
                              color: Colors.amber[700]!,
                              width: 4,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pertandingan yang Dipilih:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _match!.title,
                              style: const TextStyle(
                                fontSize: 20,
                                color: Color(0xFF1a237e),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_match!.venue} - ${DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(_match!.startTime)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Category selection
                      const Text(
                        'Pilih Kategori Tiket',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<SeatCategory>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          hintText: 'Pilih Kategori Tempat Duduk',
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(
                              '${category.name} (${_formatRupiah(category.price)})',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                      ),
                      if (_selectedCategory != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Harga Satuan: ${_formatRupiah(_selectedCategory!.price)}',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      const Divider(),

                      // Contact information
                      const Text(
                        'Informasi Kontak',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _namaLengkapController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Lengkap (Sesuai KTP/Paspor)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'Masukkan Email untuk Pengiriman E-Ticket',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nomorTeleponController,
                        decoration: const InputDecoration(
                          labelText: 'Nomor Telepon',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 24),
                      const Divider(),

                      // Ticket holders
                      ...List.generate(_jumlahTiket, (index) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Detail Pemegang Tiket ${index + 1}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _namaTiketControllers[index],
                              decoration: InputDecoration(
                                labelText: 'Nama (Pada Tiket ${index + 1})',
                                border: const OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text('Jenis Kelamin'),
                            Row(
                              children: [
                                Radio<String>(
                                  value: 'L',
                                  groupValue: _jenisKelaminList[index],
                                  onChanged: (value) {
                                    setState(() {
                                      _jenisKelaminList[index] = value!;
                                    });
                                  },
                                ),
                                const Text('Laki-laki (L)'),
                                const SizedBox(width: 16),
                                Radio<String>(
                                  value: 'P',
                                  groupValue: _jenisKelaminList[index],
                                  onChanged: (value) {
                                    setState(() {
                                      _jenisKelaminList[index] = value!;
                                    });
                                  },
                                ),
                                const Text('Perempuan (P)'),
                              ],
                            ),
                            if (index > 0)
                              TextButton.icon(
                                onPressed: () => _removeTicket(index),
                                icon: const Icon(Icons.delete),
                                label: const Text('Hapus Tiket'),
                              ),
                            const SizedBox(height: 24),
                          ],
                        );
                      }),

                      // Add ticket button
                      if (_jumlahTiket < _maxTiketPerTransaksi)
                        OutlinedButton.icon(
                          onPressed: _addTicket,
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah Tiket'),
                        ),
                      if (_jumlahTiket >= _maxTiketPerTransaksi)
                        Text(
                          'Maksimum tiket tercapai.',
                          style: TextStyle(color: Colors.red[500]),
                        ),
                      const SizedBox(height: 24),

                      // Confirm button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _selectedCategory != null
                              ? _handleKonfirmasi
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandOrange,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Konfirmasi & Cek Harga Total',
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

