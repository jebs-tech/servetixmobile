import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../data/payment_api.dart';
import '../data/models/payment_models.dart';
import 'detail_pembayaran_page.dart';
import '../../matches/data/match_api.dart';
import '../../matches/data/match_detail_model.dart';

class DetailPembeliPage extends StatefulWidget {
  final int matchId;

  const DetailPembeliPage({
    Key? key,
    required this.matchId,
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
  final List<String> _jenisKelaminList = ['L'];

  MatchDetail? _match;
  List<SeatCategory> _categories = [];
  SeatCategory? _selectedCategory;
  int _jumlahTiket = 1;
  bool _isLoading = false;
  bool _isLoadingData = true;

  static const Color brandDarkBlue = Color(0xFF1e3a5f);
  static const Color brandOrange = Color(0xFFFFA043);
  static const Color brandLightBlue = Color(0xFF4a90a4);

  @override
  void initState() {
    super.initState();
    _loadData();
    _namaTiketControllers.add(TextEditingController());
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final request = context.read<CookieRequest>();
      
      // Load match detail
      final match = await MatchApi().fetchMatchDetail(request, widget.matchId);
      
      // Load categories
      final categories = await PaymentApi.getCategories(request);

      if (mounted) {
        setState(() {
          _match = match;
          _categories = categories;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _tambahTiket() {
    if (_jumlahTiket < 5) {
      setState(() {
        _jumlahTiket++;
        _namaTiketControllers.add(TextEditingController());
        _jenisKelaminList.add('L');
      });
    }
  }

  void _showKonfirmasiDialog() {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap lengkapi semua data')),
      );
      return;
    }

    final totalHarga = _jumlahTiket * _selectedCategory!.price;
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Pembelian'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Tiket: ${_jumlahTiket}'),
            Text('Kategori Kursi: ${_selectedCategory!.name}'),
            const SizedBox(height: 8),
            Text(
              'Total Harga: ${formatCurrency.format(totalHarga)}',
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _simpanPembelian();
            },
            child: const Text('Lanjutkan ke Pembayaran'),
          ),
        ],
      ),
    );
  }

  Future<void> _simpanPembelian() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Kumpulkan data tiket
    final List<Map<String, dynamic>> tickets = [];
    for (int i = 0; i < _jumlahTiket; i++) {
      tickets.add({
        'nama': _namaTiketControllers[i].text,
        'jenis_kelamin': _jenisKelaminList[i],
      });
    }

    try {
      final request = context.read<CookieRequest>();
      final result = await PaymentApi.savePembelian(
        request,
        matchId: widget.matchId,
        kategoriId: _selectedCategory!.id,
        namaLengkap: _namaLengkapController.text,
        email: _emailController.text,
        nomorTelepon: _nomorTeleponController.text,
        tickets: tickets,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result['status'] == 'success') {
          // Pastikan order_id dikonversi ke String
          final orderId = result['order_id']?.toString() ?? '';
          if (orderId.isEmpty) {
            throw Exception('Order ID tidak ditemukan dalam response');
          }
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DetailPembayaranPage(
                orderId: orderId,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Terjadi kesalahan'),
              backgroundColor: Colors.red,
            ),
          );
        }
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

  String _formatCurrency(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detail Pembeli'),
          backgroundColor: brandDarkBlue,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pembeli'),
        backgroundColor: brandDarkBlue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
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
                      color: brandDarkBlue,
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
              if (_match != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.yellow[100],
                    border: Border(
                      left: BorderSide(color: Colors.amber, width: 4),
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: brandDarkBlue,
                        ),
                      ),
                      Text(
                        '${_match!.venue} - ${_match!.formattedDate} ${_match!.formattedTime}',
                        style: TextStyle(color: Colors.grey[700]),
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
                decoration: const InputDecoration(
                  labelText: 'Kategori Tempat Duduk',
                  border: OutlineInputBorder(),
                ),
                value: _selectedCategory,
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(
                      '${category.name} (${_formatCurrency(category.price)})',
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Harap pilih kategori tempat duduk';
                  }
                  return null;
                },
              ),
              if (_selectedCategory != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Harga Satuan: ${_formatCurrency(_selectedCategory!.price)}',
                  style: const TextStyle(
                    color: brandOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Contact information
              const Text(
                'Informasi Kontak',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _namaLengkapController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap (Sesuai KTP/Paspor)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harap isi nama lengkap';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  hintText: 'Masukkan Email untuk Pengiriman E-Ticket',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harap isi email';
                  }
                  if (!value.contains('@')) {
                    return 'Format email tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomorTeleponController,
                decoration: const InputDecoration(
                  labelText: 'Nomor Telepon',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harap isi nomor telepon';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Ticket holder details
              Text(
                'Detail Pemegang Tiket 1',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _namaTiketControllers[0],
                decoration: const InputDecoration(
                  labelText: 'Nama (Pada Tiket 1)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harap isi nama pemegang tiket';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('Jenis Kelamin'),
              Row(
                children: [
                  Radio<String>(
                    value: 'L',
                    groupValue: _jenisKelaminList[0],
                    onChanged: (value) {
                      setState(() {
                        _jenisKelaminList[0] = value!;
                      });
                    },
                  ),
                  const Text('Laki-laki (L)'),
                  const SizedBox(width: 16),
                  Radio<String>(
                    value: 'P',
                    groupValue: _jenisKelaminList[0],
                    onChanged: (value) {
                      setState(() {
                        _jenisKelaminList[0] = value!;
                      });
                    },
                  ),
                  const Text('Perempuan (P)'),
                ],
              ),

              // Additional tickets
              ...List.generate(_jumlahTiket - 1, (index) {
                final ticketNum = index + 2;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 32),
                    Text(
                      'Detail Pemegang Tiket $ticketNum',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _namaTiketControllers[ticketNum - 1],
                      decoration: InputDecoration(
                        labelText: 'Nama (Pada Tiket $ticketNum)',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Harap isi nama pemegang tiket';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Jenis Kelamin'),
                    Row(
                      children: [
                        Radio<String>(
                          value: 'L',
                          groupValue: _jenisKelaminList[ticketNum - 1],
                          onChanged: (value) {
                            setState(() {
                              _jenisKelaminList[ticketNum - 1] = value!;
                            });
                          },
                        ),
                        const Text('Laki-laki (L)'),
                        const SizedBox(width: 16),
                        Radio<String>(
                          value: 'P',
                          groupValue: _jenisKelaminList[ticketNum - 1],
                          onChanged: (value) {
                            setState(() {
                              _jenisKelaminList[ticketNum - 1] = value!;
                            });
                          },
                        ),
                        const Text('Perempuan (P)'),
                      ],
                    ),
                  ],
                );
              }),

              // Add ticket button
              if (_jumlahTiket < 5) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _tambahTiket,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Tiket'),
                ),
              ] else ...[
                const SizedBox(height: 16),
                Text(
                  'Maksimum tiket tercapai.',
                  style: TextStyle(color: Colors.red[700]),
                ),
              ],

              const SizedBox(height: 32),

              // Confirm button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isLoading || _selectedCategory == null)
                      ? null
                      : _showKonfirmasiDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandOrange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Konfirmasi & Cek Harga Total',
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
      ),
    );
  }
}

