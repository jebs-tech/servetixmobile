// lib/forums/forums_list_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:servetixmobile/models/forum_models.dart';
import 'package:servetixmobile/forums/thread_detail_page.dart';
import 'package:servetixmobile/forums/create_thread_page.dart';
import 'dart:convert';

class ForumsListPage extends StatefulWidget {
  const ForumsListPage({super.key});

  @override
  State<ForumsListPage> createState() => _ForumsListPageState();
}

class _ForumsListPageState extends State<ForumsListPage> {
  Future<List<Thread>>? _threadsFuture;
  List<Tag> _tags = [];
  int? _selectedTagId;
  final TextEditingController _createTitleController = TextEditingController();
  final TextEditingController _createContentController = TextEditingController();
  bool _isSubmittingThread = false;

  // Warna sesuai Django
  final Color _darkBlue = const Color(0xFF1a2a4b); // brand-dark-blue
  final Color _gold = const Color(0xFFFFC107); // brand-gold
  final Color _orange = const Color(0xFFFFA043); // brand-orange
  final Color _cream = const Color(0xFFfdf4d9); // cream background
  final Color _creamTop = const Color(0xFFFFF7D1); // cream top gradient

  @override
  void initState() {
    super.initState();
    final request = Provider.of<CookieRequest>(context, listen: false);
    _loadThreads(request);
    _loadTags(request);
  }

  @override
  void dispose() {
    _createTitleController.dispose();
    _createContentController.dispose();
    super.dispose();
  }

  Future<void> _submitCreateThread(CookieRequest request) async {
    if (_createTitleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Judul tidak boleh kosong"), backgroundColor: Colors.red),
      );
      return;
    }

    if (_createContentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Konten tidak boleh kosong"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmittingThread = true);

    try {
      final response = await request.postJson(
        "http://127.0.0.1:8000/forums/api/threads/",
        jsonEncode({
          'title': _createTitleController.text.trim(),
          'content': _createContentController.text.trim(),
          'tags': [],
        }),
      );

      if (response['success'] == true) {
        _createTitleController.clear();
        _createContentController.clear();
        _loadThreads(request);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Thread berhasil dibuat"), backgroundColor: Colors.green),
          );
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
      if (mounted) setState(() => _isSubmittingThread = false);
    }
  }

  void _loadThreads(CookieRequest request) {
    setState(() {
      _threadsFuture = fetchThreads(request);
    });
  }

  void _loadTags(CookieRequest request) async {
    try {
      final response = await request.get("http://127.0.0.1:8000/forums/api/tags/");
      if (response['success'] == true) {
        setState(() {
          _tags = (response['tags'] as List).map((tag) => Tag.fromJson(tag)).toList();
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<List<Thread>> fetchThreads(CookieRequest request) async {
    try {
      final response = await request.get("http://127.0.0.1:8000/forums/api/threads/");
      if (response['success'] == true) {
        List<dynamic> list = response['threads'] ?? [];
        return list.map((d) => Thread.fromJson(d)).toList();
      } else {
        throw Exception('Gagal load threads: ${response['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('Error fetching threads: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      backgroundColor: _creamTop,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e2c4f), // Navbar color dari Django
        title: const Text("Forum Penggemar", style: TextStyle(color: Color(0xFFfdf4d9), fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFFfdf4d9)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFFfdf4d9)),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateThreadPage()),
              );
              if (result == true) {
                _loadThreads(request);
              }
            },
            tooltip: "Buat Thread Baru",
          ),
        ],
      ),
      body: Column(
        children: [
          // Form Buat Thread Baru
          Container(
            margin: const EdgeInsets.all(16),
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
                  controller: _createTitleController,
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
                  controller: _createContentController,
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
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmittingThread ? null : () => _submitCreateThread(request),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: _darkBlue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: _isSubmittingThread
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
          // Filter Tags
          if (_tags.isNotEmpty)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _tags.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: FilterChip(
                        label: const Text("Semua"),
                        selected: _selectedTagId == null,
                        selectedColor: _gold.withOpacity(0.3),
                        checkmarkColor: _darkBlue,
                        labelStyle: TextStyle(
                          color: _selectedTagId == null ? _darkBlue : Colors.grey[700],
                          fontWeight: _selectedTagId == null ? FontWeight.w600 : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _selectedTagId = null;
                          });
                          _loadThreads(request);
                        },
                      ),
                    );
                  }
                  final tag = _tags[index - 1];
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: FilterChip(
                      label: Text(tag.name),
                      selected: _selectedTagId == tag.id,
                      selectedColor: _gold.withOpacity(0.3),
                      checkmarkColor: _darkBlue,
                      labelStyle: TextStyle(
                        color: _selectedTagId == tag.id ? _darkBlue : Colors.grey[700],
                        fontWeight: _selectedTagId == tag.id ? FontWeight.w600 : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedTagId = selected ? tag.id : null;
                        });
                        _loadThreads(request);
                      },
                    ),
                  );
                },
              ),
            ),
          // Threads List
          Expanded(
            child: FutureBuilder<List<Thread>>(
              future: _threadsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.forum, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text("Belum ada thread", style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        Text("Jadilah yang pertama membuat thread!",
                            textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  );
                }

                List<Thread> threads = snapshot.data!;
                if (_selectedTagId != null) {
                  threads = threads.where((thread) => thread.tags.any((tag) => tag.id == _selectedTagId)).toList();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    _loadThreads(request);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: threads.length,
                    itemBuilder: (context, index) {
                      final thread = threads[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: _cream,
                          borderRadius: BorderRadius.circular(16),
                          border: const Border(
                            left: BorderSide(color: Color(0xFFFFC107), width: 4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ThreadDetailPage(threadId: thread.id),
                              ),
                            );
                            if (result == true) {
                              _loadThreads(request);
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            thread.title,
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: _darkBlue,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          if (thread.tags.isNotEmpty)
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: thread.tags.map((tag) {
                                                return Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: _gold.withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    tag.name,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: _darkBlue,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Score Display (non-interactive)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: _gold.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.trending_up,
                                            color: _darkBlue,
                                            size: 20,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "${thread.score}",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: _darkBlue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  thread.content,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF2d2d2d),
                                    fontSize: 16,
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.only(top: 16),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                        color: _gold.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.account_circle, size: 16, color: _darkBlue),
                                      const SizedBox(width: 4),
                                      Text(
                                        thread.author.username,
                                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                      ),
                                      const SizedBox(width: 16),
                                      Icon(Icons.access_time, size: 16, color: _darkBlue),
                                      const SizedBox(width: 4),
                                      Text(
                                        thread.createdAt.split('T')[0],
                                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                      ),
                                      const Spacer(),
                                      Icon(Icons.comment, size: 16, color: _darkBlue),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${thread.replyCount} balasan",
                                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

