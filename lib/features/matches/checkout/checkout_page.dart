import 'package:flutter/material.dart';
import 'models/passenger_model.dart';
import 'checkout_service.dart';

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
  List<Passenger> passengers = [Passenger()];
  bool loading = false;
  String message = '';

  void addPassenger() {
    setState(() => passengers.add(Passenger()));
  }

  void removePassenger() {
    if (passengers.length > 1) {
      setState(() => passengers.removeLast());
    }
  }

  Future<void> submit() async {
    setState(() {
      loading = true;
      message = '';
    });

    final body = {
      "match_id": widget.matchId,
      "buyer_name": passengers.first.name,
      "buyer_email": passengers.first.email,
      "passengers": passengers.map((p) => p.toJson()).toList(),
      if (widget.selectedSeatIds.isNotEmpty)
        "seat_ids": widget.selectedSeatIds
      else
        "quantity": passengers.length,
    };

    final res = widget.selectedSeatIds.isNotEmpty
        ? await CheckoutService.bookWithSeats(body)
        : await CheckoutService.bookByQuantity(body);

    setState(() {
      loading = false;
      message = res['ok'] == true
          ? 'Booking berhasil #${res['booking_id']}'
          : res['msg'] ?? 'Gagal booking';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            ...passengers.asMap().entries.map((e) {
              final i = e.key;
              final p = e.value;

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Text('Tiket #${i + 1}'),
                      TextField(
                        decoration:
                            const InputDecoration(labelText: 'Nama'),
                        onChanged: (v) => p.name = v,
                      ),
                      TextField(
                        decoration:
                            const InputDecoration(labelText: 'Email'),
                        onChanged: (v) => p.email = v,
                      ),
                      TextField(
                        decoration:
                            const InputDecoration(labelText: 'Kategori'),
                        onChanged: (v) => p.category = v,
                      ),
                    ],
                  ),
                ),
              );
            }),
            Row(
              children: [
                ElevatedButton(
                  onPressed: addPassenger,
                  child: const Text('Tambah Tiket'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: removePassenger,
                  child: const Text('Hapus'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loading ? null : submit,
              child: Text(loading ? 'Memproses...' : 'Lanjutkan Pembayaran'),
            ),
            if (message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(message),
              )
          ],
        ),
      ),
    );
  }
}
