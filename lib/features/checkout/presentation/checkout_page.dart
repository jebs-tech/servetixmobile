import 'package:flutter/material.dart';
import '../data/checkout_api.dart';
import '../data/models/passenger_model.dart';
import '../data/models/seat_model.dart';

class CheckoutPage extends StatefulWidget {
  final int matchId;
  final List<int> selectedSeatIds;

  const CheckoutPage({
    super.key,
    required this.matchId,
    this.selectedSeatIds = const [],
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  List<Passenger> passengers = [
    Passenger(name: '', category: ''),
  ];

  List<Seat> seats = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadSeats();
  }

  Future<void> _loadSeats() async {
    try {
      seats = await CheckoutApi.fetchSeats(widget.matchId);
    } finally {
      setState(() => loading = false);
    }
  }

  int get totalPrice {
    if (widget.selectedSeatIds.isNotEmpty) {
      return widget.selectedSeatIds.fold(0, (sum, id) {
        final seat = seats.firstWhere((s) => s.id == id);
        return sum + seat.price;
      });
    }

    return passengers.fold(0, (sum, p) {
      final seat = seats.firstWhere(
        (s) => s.category == p.category,
        orElse: () => Seat(
          id: 0,
          label: '',
          category: '',
          price: 0,
          color: '',
        ),
      );
      return sum + seat.price;
    });
  }

  void addPassenger() {
    setState(() {
      passengers.add(Passenger(name: '', category: ''));
    });
  }

  void removePassenger() {
    if (passengers.length <= 1) return;
    setState(() {
      passengers.removeLast();
    });
  }

  Future<void> submit() async {
    final data = passengers.map((e) => e.toJson()).toList();

    if (widget.selectedSeatIds.isNotEmpty) {
      await CheckoutApi.bookSeats(
        matchId: widget.matchId,
        seatIds: widget.selectedSeatIds,
        passengers: data,
      );
    } else {
      await CheckoutApi.bookQuantity(
        matchId: widget.matchId,
        passengers: data,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking berhasil')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPassengerSection(),
          const SizedBox(height: 24),
          _buildSummaryCard(),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Bayar Sekarang'),
          )
        ],
      ),
    );
  }

  Widget _buildPassengerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Data Penonton',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...List.generate(passengers.length, (index) {
          final p = passengers[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                    ),
                    onChanged: (v) => p.name = v,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Email',
                    ),
                    onChanged: (v) => p.email = v,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Kategori Tiket',
                    ),
                    items: seats
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.category,
                            child: Text('${s.category} — Rp ${s.price}'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => p.category = v ?? '',
                  ),
                ],
              ),
            ),
          );
        }),
        Row(
          children: [
            TextButton.icon(
              onPressed: addPassenger,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Tiket'),
            ),
            const SizedBox(width: 8),
            if (passengers.length > 1)
              TextButton.icon(
                onPressed: removePassenger,
                icon: const Icon(Icons.remove),
                label: const Text('Hapus'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ringkasan Pembayaran',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total'),
                Text(
                  'Rp $totalPrice',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
