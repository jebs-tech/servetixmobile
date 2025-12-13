import 'package:flutter/material.dart';
import '../services/voucher_service.dart';

class VoucherRedeemPage extends StatefulWidget {
  final String code;

  VoucherRedeemPage({required this.code});

  @override
  _VoucherRedeemPageState createState() => _VoucherRedeemPageState();
}

class _VoucherRedeemPageState extends State<VoucherRedeemPage> {
  final VoucherService _service = VoucherService();
  String? result;

  @override
  void initState() {
    super.initState();
    redeem();
  }

  void redeem() async {
    final res = await _service.redeemVoucher(widget.code);

    setState(() {
      result = res["message"];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Redeem Voucher")),
      body: Center(
        child: result == null
            ? CircularProgressIndicator()
            : Text(result!, style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
