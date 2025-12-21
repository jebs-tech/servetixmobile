import 'package:flutter/material.dart';
import 'package:servetixmobile/models/match_entry.dart';

class MatchFormPage extends StatefulWidget {
  final MatchEntry? matchToEdit;

  const MatchFormPage({super.key, this.matchToEdit});

  @override
  State<MatchFormPage> createState() => _MatchFormPageState();
}

class _MatchFormPageState extends State<MatchFormPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Form fields
  late String _title;
  late String _teamAName;
  late String _teamBName;
  late String _venueName;
  late String _venueAddress;
  late DateTime _startTime;
  late String _description;
  late int _priceFrom;

  // Sample data untuk dropdown
  final List<String> _teams = [
    "Jakarta Pertamina",
    "Bandung BJB Tandamata",
    "Surabaya Bhayangkara",
    "Gresik Petrokimia",
    "Palembang Bank Sumsel",
    "Jakarta Elektrik",
    "Bogor LavAni",
    "Solo Bayangkara",
  ];

  final Map<String, String> _venues = {
    "Istora Senayan": "Gelora Bung Karno, Jakarta",
    "GOR Among Rogo": "Yogyakarta",
    "GOR PSCC": "Surabaya",
    "Gor C-Tra Arena": "Bandung",
    "Manahan Stadium": "Solo",
    "GOR Pajjaiang": "Makassar",
  };

  @override
  void initState() {
    super.initState();
    
    if (widget.matchToEdit != null) {
      // Edit mode
      _title = widget.matchToEdit!.title;
      _teamAName = widget.matchToEdit!.teamA.name;
      _teamBName = widget.matchToEdit!.teamB.name;
      _venueName = widget.matchToEdit!.venue.name;
      _venueAddress = widget.matchToEdit!.venue.address;
      _startTime = widget.matchToEdit!.startTime;
      _description = widget.matchToEdit!.description;
      _priceFrom = widget.matchToEdit!.priceFrom;
    } else {
      // Create mode
      _title = "";
      _teamAName = _teams[0];
      _teamBName = _teams[1];
      _venueName = _venues.keys.first;
      _venueAddress = _venues.values.first;
      _startTime = DateTime.now().add(const Duration(days: 1));
      _description = "";
      _priceFrom = 75000;
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));
      
      Navigator.pop(context);
      
      // Create Match
      final matchEntry = MatchEntry(
        id: widget.matchToEdit?.id ?? 0,
        title: _title,
        teamA: Team(name: _teamAName, logo: null),
        teamB: Team(name: _teamBName, logo: null),
        venue: Venue(name: _venueName, address: _venueAddress),
        startTime: _startTime,
        description: _description,
        priceFrom: _priceFrom,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.matchToEdit != null 
              ? "Pertandingan berhasil diperbarui!" 
              : "Pertandingan berhasil dibuat!",
          ),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context, matchEntry);
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_startTime),
      );
      
      if (time != null) {
        setState(() {
          _startTime = DateTime(
            date.year, date.month, date.day,
            time.hour, time.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.matchToEdit != null ? "Edit Pertandingan" : "Tambah Pertandingan",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF3B528D),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _submitForm,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                initialValue: _title,
                decoration: const InputDecoration(
                  labelText: "Judul Pertandingan",
                  border: OutlineInputBorder(),
                  hintText: "Contoh: Jakarta vs Bandung",
                ),
                onSaved: (value) => _title = value ?? "",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Judul tidak boleh kosong";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _teamAName,
                    isExpanded: true, // TAMBAH INI!
                    decoration: const InputDecoration(
                      labelText: "Tim A",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    items: _teams.map((team) {
                      return DropdownMenuItem(
                        value: team,
                        child: Text(
                          team,
                          overflow: TextOverflow.ellipsis, // TAMBAH INI!
                          maxLines: 1,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _teamAName = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16), // GANTI width MENJADI height
                  DropdownButtonFormField<String>(
                    value: _teamBName,
                    isExpanded: true, // TAMBAH INI!
                    decoration: const InputDecoration(
                      labelText: "Tim B",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    items: _teams.map((team) {
                      return DropdownMenuItem(
                        value: team,
                        child: Text(
                          team,
                          overflow: TextOverflow.ellipsis, // TAMBAH INI!
                          maxLines: 1,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _teamBName = value!;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _venueName,
                decoration: const InputDecoration(
                  labelText: "Venue",
                  border: OutlineInputBorder(),
                ),
                items: _venues.keys.map((venue) {
                  return DropdownMenuItem(
                    value: venue,
                    child: Text(venue),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _venueName = value!;
                    _venueAddress = _venues[value]!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Venue harus dipilih";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: _pickDateTime,
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: TextEditingController(
                      text: "${_startTime.day}/${_startTime.month}/${_startTime.year} ${_startTime.hour}:${_startTime.minute.toString().padLeft(2, '0')}",
                    ),
                    decoration: const InputDecoration(
                      labelText: "Waktu Pertandingan",
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                      hintText: "Klik untuk memilih tanggal & waktu",
                    ),
                    validator: (value) {
                      if (_startTime.isBefore(DateTime.now())) {
                        return "Waktu harus di masa depan";
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Klik icon kalender di ujung kanan",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              TextFormField(
                initialValue: _priceFrom.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Harga Tiket Mulai Dari",
                  border: OutlineInputBorder(),
                  prefixText: "Rp ",
                ),
                onSaved: (value) => _priceFrom = int.tryParse(value ?? "") ?? 75000,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Harga tidak boleh kosong";
                  }
                  final price = int.tryParse(value);
                  if (price == null || price < 0) {
                    return "Harga harus angka positif";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                initialValue: _description,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Deskripsi",
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                onSaved: (value) => _description = value ?? "",
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF6CA50),
                        foregroundColor: const Color(0xFF1e2c4f),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        widget.matchToEdit != null ? "Simpan Perubahan" : "Simpan",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      child: const Text("Batal"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}