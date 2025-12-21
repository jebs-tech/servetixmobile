import 'package:flutter/material.dart';
import 'package:servetixmobile/widgets/left_drawer.dart';
import 'package:servetixmobile/widgets/match_card.dart';
import 'package:servetixmobile/models/match_entry.dart';
import 'package:servetixmobile/screens/match_form.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

class MatchListPage extends StatefulWidget {
  const MatchListPage({super.key});

  @override
  State<MatchListPage> createState() => _MatchListPageState();
}

class _MatchListPageState extends State<MatchListPage> {
  String _filter = 'all';
  int? _selectedMonth;
  bool _isAdmin = false;
  bool _isLoading = true;
  String? _error;
  List<MatchEntry> _matches = [];

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final request = context.read<CookieRequest>();
      String baseUrl = 'http://localhost:8000/api';
      String endpoint = '/matches/';
      
      final params = <String, String>{};
      if (_selectedMonth != null) {
        params['month'] = _selectedMonth.toString();
      }
      
      String url = '$baseUrl$endpoint';
      if (params.isNotEmpty) {
        url += '?${Uri(queryParameters: params).query}';
      }

      print('🌐 Fetching from: $url');
      
      final response = await request.get(url);
      print('📥 Raw response: $response');

      if (response is List) {
        final matches = <MatchEntry>[];
        for (var item in response) {
          try {
            matches.add(MatchEntry(
              id: item['id'] ?? 0,
              title: item['title'] ?? 'No Title',
              teamA: Team(
                name: item['team_a'] is Map 
                  ? item['team_a']['name'] ?? 'Team A'
                  : item['team_a'] ?? 'Team A',
                logo: item['team_a'] is Map ? item['team_a']['logo'] : null,
              ),
              teamB: Team(
                name: item['team_b'] is Map 
                  ? item['team_b']['name'] ?? 'Team B'
                  : item['team_b'] ?? 'Team B',
                logo: item['team_b'] is Map ? item['team_b']['logo'] : null,
              ),
              venue: Venue(
                name: item['venue'] is Map
                  ? item['venue']['name'] ?? 'Unknown Venue'
                  : item['venue'] ?? 'Unknown Venue',
                address: item['venue'] is Map
                  ? item['venue']['address'] ?? ''
                  : '',
              ),
              startTime: DateTime.parse(item['start_time'] ?? DateTime.now().toString()),
              description: item['description'] ?? '',
              priceFrom: item['price_from'] ?? 75000,
            ));
          } catch (e) {
            print('❌ Error creating match: $e, item: $item');
          }
        }
        
        if (mounted) {
          setState(() {
            _matches = matches;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Invalid response format. Expected List, got ${response.runtimeType}');
      }
    } catch (e) {
      print('❌ Error fetching matches: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load matches. Please check Django server.\nError: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteMatch(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Pertandingan"),
        content: const Text("Apakah Anda yakin ingin menghapus pertandingan ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Ya, Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final request = context.read<CookieRequest>();
      final baseUrl = 'http://localhost:8000';
      
      await request.post('$baseUrl/matches/$id/delete/', {});
      
      await _loadMatches();
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Pertandingan berhasil dihapus"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Error deleting match: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal menghapus: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<MatchEntry> _getFilteredMatches() {
    List<MatchEntry> filtered = _matches;
    
    // kita buat berdasarkan waktu
    final now = DateTime.now();
    filtered = filtered.where((match) {
      if (_filter == 'upcoming') return match.startTime.isAfter(now);
      if (_filter == 'ongoing') {
        // startTime < now < startTime + 3 jam
        return match.startTime.isBefore(now) && 
               match.startTime.add(const Duration(hours: 3)).isAfter(now);
      }
      if (_filter == 'finished') return match.startTime.add(const Duration(hours: 3)).isBefore(now);
      return true; // all
    }).toList();
    
    filtered.sort((a, b) => a.startTime.compareTo(b.startTime));
    
    return filtered;
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1: return 'Januari';
      case 2: return 'Februari';
      case 3: return 'Maret';
      case 4: return 'April';
      case 5: return 'Mei';
      case 6: return 'Juni';
      case 7: return 'Juli';
      case 8: return 'Agustus';
      case 9: return 'September';
      case 10: return 'Oktober';
      case 11: return 'November';
      case 12: return 'Desember';
      default: return '';
    }
  }

  Widget _buildStatusChip(String label, String value) {
    final isSelected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filter = value;
        });
      },
      selectedColor: const Color(0xFF3B528D),
      backgroundColor: Colors.grey[200],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF1e2c4f),
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredMatches = _getFilteredMatches();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pertandingan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: const Color(0xFF3B528D),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadMatches,
          ),
        ],
      ),
      drawer: const LeftDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadMatches,
                          child: const Text('Coba Lagi'),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Pastikan Django server sedang berjalan\npada http://localhost:8000',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Filter Section
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B528D),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12),
                                    child: Icon(Icons.filter_list, color: Color(0xFF3B528D)),
                                  ),
                                  Expanded(
                                    child: DropdownButton<int>(
                                      value: _selectedMonth,
                                      isExpanded: true,
                                      underline: const SizedBox(),
                                      hint: const Text('Semua Bulan'),
                                      items: [
                                        const DropdownMenuItem<int>(
                                          value: null,
                                          child: Text('Semua Bulan'),
                                        ),
                                        for (int i = 1; i <= 12; i++)
                                          DropdownMenuItem<int>(
                                            value: i,
                                            child: Text(_getMonthName(i)),
                                          ),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedMonth = value;
                                          _loadMatches();
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildStatusChip('Semua', 'all'),
                                const SizedBox(width: 8),
                                _buildStatusChip('Upcoming', 'upcoming'),
                                const SizedBox(width: 8),
                                _buildStatusChip('Ongoing', 'ongoing'),
                                const SizedBox(width: 8),
                                _buildStatusChip('Selesai', 'finished'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Match Count
                    if (filteredMatches.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        color: Colors.grey[50],
                        child: Row(
                          children: [
                            Text(
                              '${filteredMatches.length} pertandingan ditemukan',
                              style: const TextStyle(
                                color: Color(0xFF1e2c4f),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            if (_selectedMonth != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF6CA50),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _getMonthName(_selectedMonth!),
                                  style: const TextStyle(
                                    color: Color(0xFF1e2c4f),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                    // Matches List
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadMatches,
                        child: filteredMatches.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.sports_volleyball,
                                      size: 80,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Tidak ada pertandingan',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    if (_selectedMonth != null)
                                      const SizedBox(height: 8),
                                    if (_selectedMonth != null)
                                      const Text(
                                        'Coba pilih bulan lain',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 16),
                                itemCount: filteredMatches.length,
                                itemBuilder: (context, index) {
                                  final match = filteredMatches[index];
                                  return MatchCard(
                                    match: match,
                                    isAdmin: _isAdmin,
                                    onTap: () {
                                      _showMatchDetail(match);
                                    },
                                    onEdit: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MatchFormPage(matchToEdit: match),
                                        ),
                                      );
                                    },
                                    onDelete: () => _deleteMatch(match.id),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MatchFormPage(),
                  ),
                );
              },
              backgroundColor: const Color(0xFFF6CA50),
              child: const Icon(Icons.add, color: Color(0xFF1e2c4f)),
            )
          : null,
    );
  }

  void _showMatchDetail(MatchEntry match) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  match.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1e2c4f),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(_formatDateTime(match.startTime)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(match.venue.name),
                const SizedBox(width: 8),
                const Icon(Icons.info_outline, size: 14, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Deskripsi:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(match.description),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Harga mulai dari:'),
                    Text(
                      'Rp ${match.priceFrom}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1e2c4f),
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Navigate to booking
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF6CA50),
                    foregroundColor: const Color(0xFF1e2c4f),
                  ),
                  child: const Text('BELI TIKET'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    final months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 
                    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}