// lib/forums/create_thread_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:servetix/models/forum_models.dart';
import 'dart:convert';

class CreateThreadPage extends StatefulWidget {
  const CreateThreadPage({super.key});

  @override
  State<CreateThreadPage> createState() => _CreateThreadPageState();
}

class _CreateThreadPageState extends State<CreateThreadPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  List<Tag> _allTags = [];
  final List<int> _selectedTagIds = [];
  bool _isSubmitting = false;

  // Warna sesuai Django
  final Color _darkBlue = const Color(0xFF1a2a4b); // brand-dark-blue
  final Color _gold = const Color(0xFFFFC107); // brand-gold
  final Color _orange = const Color(0xFFFFA043); // brand-orange
  final Color _cream = const Color(0xFFfdf4d9); // cream background

  @override
  void initState() {
    super.initState();
    final request = Provider.of<CookieRequest>(context, listen: false);
    _loadTags(request);
  }

  Future<void> _loadTags(CookieRequest request) async {
    try {
      final response = await request.get("http://127.0.0.1:8000/forums/api/tags/");
      if (response['success'] == true) {
        setState(() {
          _allTags = (response['tags'] as List).map((tag) => Tag.fromJson(tag)).toList();
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _submitThread(CookieRequest request) async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Judul tidak boleh kosong"), backgroundColor: Colors.red),
      );
      return;
    }

    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Konten tidak boleh kosong"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await request.postJson(
        "http://127.0.0.1:8000/forums/api/threads/",
        jsonEncode({
          'title': _titleController.text.trim(),
          'content': _contentController.text.trim(),
          'tags': _selectedTagIds,
        }),
      );

      if (response['success'] == true) {
        if (mounted) {
          Navigator.pop(context, true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Thread berhasil dibuat"), backgroundColor: Colors.green),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['errors']?.toString() ?? "Gagal membuat thread"), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7D1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e2c4f),
        title: const Text("Buat Thread Baru", style: TextStyle(color: Color(0xFFfdf4d9))),
        iconTheme: const IconThemeData(color: Color(0xFFfdf4d9)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _cream,
                borderRadius: BorderRadius.circular(16),
                border: const Border(
                  left: BorderSide(color: Color(0xFFFFC107), width: 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Buat Thread Baru",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: _darkBlue,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: "Judul",
                      labelStyle: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700]),
                      hintText: "Tulis judul thread kamu...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: _gold, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _contentController,
                    decoration: InputDecoration(
                      labelText: "Isi Thread",
                      labelStyle: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700]),
                      hintText: "Tulis isi diskusi kamu di sini...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: _gold, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : () => _submitThread(request),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: _darkBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        "Kirim",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}

