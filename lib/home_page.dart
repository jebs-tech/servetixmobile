import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:servetix/auth/login_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Panggil endpoint logout
              final response = await request.logout(
                  "http://10.0.2.2:8000/api/logout/"
              );

              String message = response["message"];
              if (response['status']) {
                if (context.mounted) {
                  String uname = response["username"] ?? "User";
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("$message Sampai jumpa, $uname."),
                  ));
                  // Kembali ke Login dan hapus route history
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                        (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Text("Selamat Datang! Status Login: ${request.loggedIn}"),
      ),
    );
  }
}