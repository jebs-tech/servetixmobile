import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:servetix/dashboard_page/dashboard_page.dart'; // Sesuaikan path
import 'package:servetix/auth/register_page.dart';   // Sesuaikan path

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;

  // Palet Warna ServeTix
  final Color _darkBlue = const Color(0xFF1E293B);
  final Color _orange = const Color(0xFFFFA726);
  final Color _creamTop = const Color(0xFFFFFDE7);
  final Color _creamBottom = const Color(0xFFFFE0B2);

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    // Mendapatkan ukuran layar agar responsif
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      // AppBar Mobile: Logo di tengah/kiri, simpel
      appBar: AppBar(
        backgroundColor: _darkBlue,
        elevation: 0,
        title: const Text(
          "SERVE.TIX",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_creamTop, _creamBottom],
          ),
        ),
        child: SingleChildScrollView(
          // Agar bisa discroll saat keyboard muncul
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenHeight - kToolbarHeight, // Minimal setinggi layar dikurang AppBar
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // --- AREA FORM ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text(
                              "Masuk Akun",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          _buildLabel("Username"),
                          TextFormField(
                            controller: _usernameController,
                            decoration: _inputDecoration("Masukkan username"),
                          ),

                          const SizedBox(height: 20),

                          _buildLabel("Password"),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscureText,
                            decoration: _inputDecoration("Masukkan password").copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                                  onPressed: () => setState(() => _obscureText = !_obscureText),
                                )
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Opsi Lupa Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text("Lupa Kata Sandi?", style: TextStyle(color: _darkBlue, fontSize: 13)),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Tombol Masuk
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _orange,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: _isLoading ? null : () => _handleLogin(request),
                              child: _isLoading
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text("MASUK", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),

                          const SizedBox(height: 16),
                          const Center(child: Text("atau", style: TextStyle(color: Colors.grey))),
                          const SizedBox(height: 16),

                          // Tombol Daftar
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: _darkBlue, width: 1.5),
                                foregroundColor: _darkBlue,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage()));
                              },
                              child: const Text("DAFTAR AKUN BARU", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Spacer agar footer terdorong ke bawah
                  const Spacer(),
                  const SizedBox(height: 40),

                  // --- FOOTER MOBILE ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    color: _darkBlue,
                    child: Column(
                      children: const [
                        Text("SERVE.TIX MOBILE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text("© 2025 All Rights Reserved", style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- LOGIKA LOGIN ---
  Future<void> _handleLogin(CookieRequest request) async {
    String username = _usernameController.text;
    String password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Isi semua field!"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    // Gunakan 10.0.2.2 untuk Emulator Android
    const String url = "http://127.0.0.1:8000/api/login/";

    try {
      final response = await request.login(url, {
        'username': username,
        'password': password,
      });

      if (request.loggedIn) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardPage()),
          );
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Login Berhasil!"),
            backgroundColor: Colors.green,
          ));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(response['message'] ?? "Login Gagal"),
            backgroundColor: Colors.red,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Koneksi gagal. Cek server Django."),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Styles
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFFFA726))),
    );
  }
}