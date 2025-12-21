// lib/forums/thread_detail_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:servetix/models/forum_models.dart';
import 'package:servetix/utils/toast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ThreadDetailPage extends StatefulWidget {
  final int threadId;

  const ThreadDetailPage({super.key, required this.threadId});

  @override
  State<ThreadDetailPage> createState() => _ThreadDetailPageState();
}

class _ThreadDetailPageState extends State<ThreadDetailPage> {
  Future<Thread>? _threadFuture;
  final TextEditingController _replyController = TextEditingController();
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
    _loadThread(request);
  }

  void _loadThread(CookieRequest request) {
    setState(() {
      _threadFuture = fetchThreadDetail(request, widget.threadId);
    });
  }

  Future<Thread> fetchThreadDetail(CookieRequest request, int threadId) async {
    final response = await request.get("http://127.0.0.1:8000/forums/api/threads/$threadId/");
    if (response['success'] == true) {
      return Thread.fromJson(response['thread']);
    } else {
      throw Exception('Gagal load thread');
    }
  }

  Future<void> _submitReply(CookieRequest request) async {
    if (_replyController.text.trim().isEmpty) {
      Toast.error("Reply tidak boleh kosong");
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await request.postJson(
        "http://127.0.0.1:8000/forums/api/threads/${widget.threadId}/reply/",
        jsonEncode({'content': _replyController.text.trim()}),
      );

      if (response['success'] == true) {
        _replyController.clear();
        _loadThread(request);
        if (mounted) {
          Toast.success("Reply berhasil ditambahkan");
        }
      } else {
        if (mounted) {
          Toast.error(response['errors']?.toString() ?? "Gagal menambahkan reply");
        }
      }
    } catch (e) {
      if (mounted) {
        Toast.error("Error: $e");
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _voteThread(CookieRequest request, String action) async {
    try {
      final response = await request.postJson(
        "http://127.0.0.1:8000/forums/api/threads/${widget.threadId}/vote/",
        jsonEncode({'action': action}),
      );

      if (response['success'] == true) {
        _loadThread(request);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _voteReply(CookieRequest request, int replyId, String action) async {
    try {
      final response = await request.postJson(
        "http://127.0.0.1:8000/forums/api/replies/$replyId/vote/",
        jsonEncode({'action': action}),
      );

      if (response['success'] == true) {
        _loadThread(request);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteThread(CookieRequest request) async {
    // Konfirmasi penghapusan
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Thread"),
        content: const Text("Apakah Anda yakin ingin menghapus thread ini? Tindakan ini tidak dapat dibatalkan."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Menggunakan endpoint delete yang menerima POST untuk kompatibilitas dengan CookieRequest
      final response = await request.postJson(
        "http://127.0.0.1:8000/forums/api/threads/${widget.threadId}/delete/",
        jsonEncode({}),
      );

      if (response['success'] == true || response['status'] == true) {
        if (mounted) {
          Toast.success("Thread berhasil dihapus");
          Navigator.pop(context, true); // Kembali ke halaman sebelumnya
        }
      } else {
        if (mounted) {
          Toast.error(response['message'] ?? response['error'] ?? "Gagal menghapus thread");
        }
      }
    } catch (e) {
      if (mounted) {
        Toast.error("Error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7D1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e2c4f),
        title: const Text("Thread Detail", style: TextStyle(color: Color(0xFFfdf4d9))),
        iconTheme: const IconThemeData(color: Color(0xFFfdf4d9)),
        actions: [
          // Tombol hapus hanya muncul jika user adalah author
          FutureBuilder<Thread>(
            future: _threadFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.isAuthor) {
                return IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _deleteThread(request),
                  tooltip: "Hapus Thread",
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: FutureBuilder<Thread>(
        future: _threadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text("Gagal memuat thread", style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _loadThread(request),
                    child: const Text("Coba Lagi"),
                  ),
                ],
              ),
            );
          }

          final thread = snapshot.data!;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thread Content
                      Container(
                        decoration: BoxDecoration(
                          color: _cream,
                          borderRadius: BorderRadius.circular(16),
                          border: const Border(
                            left: BorderSide(color: Color(0xFFFFC107), width: 4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(32),
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
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: _darkBlue,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        if (thread.tags.isNotEmpty)
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: thread.tags.map((tag) {
                                              return Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                                  const SizedBox(width: 24),
                                  // Vote Section
                                  Column(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.arrow_circle_up,
                                          color: thread.hasUpvoted ? Colors.green : const Color(0xFFC5B983),
                                          size: 28,
                                        ),
                                        onPressed: () => _voteThread(request, 'upvote'),
                                      ),
                                      Text(
                                        "${thread.score}",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: _darkBlue,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.arrow_circle_down,
                                          color: thread.hasDownvoted ? Colors.red : const Color(0xFFC5B983),
                                          size: 28,
                                        ),
                                        onPressed: () => _voteThread(request, 'downvote'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Text(
                                thread.content,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF2d2d2d),
                                  height: 1.7,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.only(top: 24),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: _gold.withOpacity(0.4),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.account_circle, size: 18, color: _darkBlue),
                                    const SizedBox(width: 8),
                                    Text(
                                      thread.author.username,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[700],
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(Icons.access_time, size: 18, color: _darkBlue),
                                    const SizedBox(width: 8),
                                    Text(
                                      thread.createdAt.split('T')[0],
                                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                    ),
                                    const Spacer(),
                                    Icon(Icons.comment, size: 18, color: _darkBlue),
                                    const SizedBox(width: 8),
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
                      const SizedBox(height: 32),
                      // Replies Section Divider
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    _gold.withOpacity(0.3),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              "Balasan (${thread.replyCount})",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _darkBlue,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _gold.withOpacity(0.3),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (thread.replies == null || thread.replies!.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                          margin: const EdgeInsets.symmetric(horizontal: 0),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.comment_outlined, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                "Belum ada balasan. Jadilah yang pertama membalas!",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else
                        ...thread.replies!.map((reply) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: const Border(
                                left: BorderSide(color: Color(0xFFFFC107), width: 4),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reply.content,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF333333),
                                      height: 1.7,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.only(top: 16),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(color: Colors.grey[200]!, width: 1),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.account_circle, size: 16, color: _darkBlue),
                                        const SizedBox(width: 6),
                                        Text(
                                          reply.author.username,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[700],
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(Icons.access_time, size: 16, color: _darkBlue),
                                        const SizedBox(width: 6),
                                        Text(
                                          reply.createdAt.split('T')[0],
                                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                        ),
                                        const Spacer(),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                Icons.arrow_circle_up,
                                                size: 20,
                                                color: reply.hasUpvoted ? Colors.green : const Color(0xFFC5B983),
                                              ),
                                              onPressed: () => _voteReply(request, reply.id, 'upvote'),
                                            ),
                                            Text(
                                              "${reply.score}",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: _darkBlue,
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.arrow_circle_down,
                                                size: 20,
                                                color: reply.hasDownvoted ? Colors.red : const Color(0xFFC5B983),
                                              ),
                                              onPressed: () => _voteReply(request, reply.id, 'downvote'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ),
              // Reply Input
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  border: Border.all(
                    color: _gold.withOpacity(0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.reply, color: _darkBlue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Tulis Balasan",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _darkBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _replyController,
                      decoration: InputDecoration(
                        hintText: "Tulis balasan kamu di sini...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: _gold, width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "Tekan Enter untuk mengirim",
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : () => _submitReply(request),
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
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }
}

