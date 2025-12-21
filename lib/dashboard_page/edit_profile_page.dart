import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:servetixmobile/models/dashboard_models.dart'; // Pastikan path benar

class EditProfilePage extends StatefulWidget {
  // Kita butuh data user saat ini untuk pre-fill form
  final UserProfile userProfile;

  const EditProfilePage({super.key, required this.userProfile});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  // Data Tim
  List<dynamic> _allTeams = []; // Daftar semua tim dari server
  List<int> _selectedTeamIds = []; // Tim yang dipilih user
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 1. Isi form dengan data yang sudah ada
    _nameController = TextEditingController(text: widget.userProfile.namaLengkap);
    _emailController = TextEditingController(text: widget.userProfile.email);
    // Asumsi di UserProfile model ada field phone, jika belum ada kasih string kosong dulu
    _phoneController = TextEditingController(text: "");

    // 2. Isi checklist dengan tim favorit yang sudah dipilih user sebelumnya
    _selectedTeamIds = widget.userProfile.preferredTeams.map((e) => e.id).toList();

    // 3. Ambil daftar semua tim dari API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAllTeams();
    });
  }

  Future<void> _fetchAllTeams() async {
    final request = Provider.of<CookieRequest>(context, listen: false);
    try {
      // Ganti URL sesuai endpoint kamu
      final response = await request.get("http://127.0.0.1:8000/api/teams/");
      if (response['status'] == true) {
        setState(() {
          _allTeams = response['teams'];
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching teams: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Background abu-abu muda bersih
      appBar: AppBar(
        title: const Text("Edit Profil", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel("Nama Lengkap"),
              _buildTextField(_nameController, "Nama Lengkap"),

              const SizedBox(height: 16),
              _buildLabel("Nomor Telepon"),
              _buildTextField(_phoneController, "Contoh: 08123456789", isNumber: true),

              const SizedBox(height: 16),
              _buildLabel("Alamat Email"),
              _buildTextField(_emailController, "admin@gmail.com"),

              const SizedBox(height: 24),
              _buildLabel("Tim Favorit Saya"),
              const SizedBox(height: 8),

              // Container Checkbox List
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                height: 300, // Fixed height dengan scroll
                child: _allTeams.isEmpty
                    ? const Center(child: Text("Tidak ada data tim."))
                    : ListView.separated(
                  itemCount: _allTeams.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final team = _allTeams[index];
                    final int teamId = team['id'];
                    final String teamName = team['name'];
                    final bool isChecked = _selectedTeamIds.contains(teamId);

                    return CheckboxListTile(
                      title: Text(teamName),
                      value: isChecked,
                      activeColor: const Color(0xFF1E293B), // Warna biru tua
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedTeamIds.add(teamId);
                          } else {
                            _selectedTeamIds.remove(teamId);
                          }
                        });
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B), // Dark Blue sesuai gambar
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      // Kirim Data ke Django
                      final response = await request.postJson(
                        "http://127.0.0.1:8000/api/profile/edit/",
                        jsonEncode({
                          "nama_lengkap": _nameController.text,
                          "nomor_telepon": _phoneController.text,
                          "email": _emailController.text,
                          "preferred_teams": _selectedTeamIds, // Kirim array ID
                        }),
                      );

                      if (context.mounted) {
                        if (response['status'] == true) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text("Perubahan berhasil disimpan!"),
                            backgroundColor: Colors.green,
                          ));
                          Navigator.pop(context, true); // Balik ke dashboard & refresh
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(response['message'] ?? "Gagal menyimpan"),
                            backgroundColor: Colors.red,
                          ));
                        }
                      }
                    }
                  },
                  child: const Text("Simpan Perubahan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widget untuk Label
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
    );
  }

  // Helper Widget untuk TextField
  Widget _buildTextField(TextEditingController controller, String hint, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Field ini tidak boleh kosong';
        }
        return null;
      },
    );
  }
}