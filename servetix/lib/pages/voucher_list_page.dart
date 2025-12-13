import 'package:flutter/material.dart';
import '../services/voucher_service.dart';
import '../models/voucher.dart';

class VoucherListPage extends StatefulWidget {
  @override
  _VoucherListPageState createState() => _VoucherListPageState();
}

class _VoucherListPageState extends State<VoucherListPage> {
  final VoucherService _service = VoucherService();
  late Future<List<Voucher>> vouchers;

  @override
  void initState() {
    super.initState();
    vouchers = _service.getVouchers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Daftar Voucher")),
      body: FutureBuilder<List<Voucher>>(
        future: vouchers,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, i) {
              final v = data[i];

              return ListTile(
                title: Text(v.code),
                subtitle: Text("${v.discountType} — ${v.value}"),
                trailing: Text(v.isActive ? "Aktif" : "Nonaktif"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VoucherRedeemPage(code: v.code),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
