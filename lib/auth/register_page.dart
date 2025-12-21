import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:servetix/auth/login_page.dart'; // Pastikan path benar
import 'package:servetix/utils/toast.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Controllers
  final TextEditingController _usernameController = TextEditingController(); // Tambahan wajib untuk Django
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Warna sesuai desain
  final Color _darkBlue = const Color(0xFF1E293B);
  final Color _buttonBlue = const Color(0xFF3F51B5); // Biru tombol "Buat Akun"
  final Color _bgCreamTop = const Color(0xFFFFFDE7);
  final Color _bgCreamBottom = const Color(0xFFFFE0B2);

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      // Kita tidak pakai AppBar bawaan agar bisa custom header logo seperti gambar
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgCreamTop, _bgCreamBottom],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // 1. HEADER LOGO "SERVE.TIX" (Kotak Biru Gelap)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: _darkBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "SERVE.TIX",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Judul Halaman
                const Text(
                  "Daftar",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 24),

                // 2. CARD PUTIH FORMULIR
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Karena Django User butuh Username unik, saya tambahkan field ini
                      _buildLabel("Username"),
                      _buildTextField(_usernameController, "Buat username unik"),
                      const SizedBox(height: 16),

                      _buildLabel("Alamat Email"),
                      _buildTextField(_emailController, "Masukkan Alamat Email", inputType: TextInputType.emailAddress),
                      const SizedBox(height: 16),

                      _buildLabel("Nama Lengkap"),
                      _buildTextField(_nameController, "Masukkan Nama Lengkap"),
                      const SizedBox(height: 16),

                      _buildLabel("Nomor Telepon"),
                      _buildTextField(_phoneController, "Masukkan Nomor Telepon", inputType: TextInputType.phone),
                      const SizedBox(height: 16),

                      _buildLabel("Kata Sandi"),
                      _buildPasswordField(_passwordController, "Masukkan Kata Sandi", _obscurePassword, () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      }),
                      const SizedBox(height: 16),

                      _buildLabel("Konfirmasi Kata Sandi"),
                      _buildPasswordField(_confirmPasswordController, "Masukkan Kata Sandi Lagi", _obscureConfirmPassword, () {
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                      }),

                      const SizedBox(height: 12),

                      // Teks Syarat Password (Grey Text)
                      const Text(
                        "Password Anda tidak boleh terlalu mirip dengan informasi pribadi lainnya.\n"
                            "Password harus mengandung setidaknya 8 karakter.\n"
                            "Password tidak boleh sepenuhnya numerik.",
                        style: TextStyle(color: Colors.grey, fontSize: 11, height: 1.5),
                      ),

                      const SizedBox(height: 24),

                      // TOMBOL BUAT AKUN
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _buttonBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _isLoading ? null : () => _handleRegister(request),
                          child: _isLoading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                              : const Text("Buat Akun", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Footer Link Login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Sudah punya akun? ", style: TextStyle(color: Colors.black54)),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context); // Kembali ke Login Page
                            },
                            child: Text(
                              "Masuk di sini",
                              style: TextStyle(
                                color: _buttonBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 30), // Bottom spacer
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- LOGIKA REGISTER ---
  Future<void> _handleRegister(CookieRequest request) async {
    // 1. Validasi Input Dasar
    if (_usernameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      Toast.error("Username, Email, dan Password wajib diisi!");
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      Toast.error("Konfirmasi password tidak cocok!");
      return;
    }

    setState(() => _isLoading = true);

    // 2. Kirim ke Backend Django
    // URL Android Emulator: 10.0.2.2
    const String url = "http://127.0.0.1:8000/api/register/";

    try {
      final response = await request.postJson(url, jsonEncode({
        "username": _usernameController.text,
        "email": _emailController.text,
        "password": _passwordController.text,
        // Kirim data tambahan (Profil) meski API register basic mungkin belum handle ini, 
        // disiapkan saja untuk pengembangan backend selanjutnya.
        "nama_lengkap": _nameController.text,
        "nomor_telepon": _phoneController.text,
      }));

      if (mounted) {
        if (response['status'] == true) {
          Toast.success("Akun berhasil dibuat! Silakan Login.");
          Navigator.pop(context); // Balik ke Login
        } else {
          Toast.error(response['message'] ?? "Gagal membuat akun.");
        }
      }
    } catch (e) {
      if (mounted) {
        Toast.error("Terjadi kesalahan: $e");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- WIDGET HELPER STYLING ---

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
          text,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF333333)
          )
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {TextInputType inputType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(6)), borderSide: BorderSide(color: Colors.blue)),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String hint, bool isObscure, VoidCallback onToggle) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(6)), borderSide: BorderSide(color: Colors.blue)),
        suffixIcon: IconButton(
          icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
          onPressed: onToggle,
        ),
      ),
    );
  }
}