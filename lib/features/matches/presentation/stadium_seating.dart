import 'package:flutter/material.dart';
import 'dart:math' as math;

// =============================================================================
// KONFIGURASI WARNA KATEGORI UNTUK DENAH
// =============================================================================
const Color cBlueCategory = Color(0xFFA8C5F5);
const Color cGreenCategory = Color(0xFFC6E6C3);
const Color cYellowCategory = Color(0xFFFFF5C0);
const Color brandOrange = Color(0xFFFFA043); // Warna untuk kursi yang dipilih user

class StadiumSeatingChart extends StatelessWidget {
  final List<String> bookedSeatLabels; // Daftar label kursi yang sudah dipesan (Hitam)
  final String? selectedSeatLabel;     // Kursi yang sedang dipilih user (Orange)
  final Function(String)? onSeatTap;   // Callback saat kursi diklik

  const StadiumSeatingChart({
    super.key,
    this.bookedSeatLabels = const [],
    this.selectedSeatLabel,
    this.onSeatTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE0E0E5), // Latar belakang canvas denah
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onTapUp: (details) {
                  // Logika pendeteksian klik bisa dikembangkan di sini jika diperlukan koordinat presisi.
                  // Untuk saat ini, fungsi ini disiapkan untuk integrasi pemilihan kursi.
                },
                child: CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: SeatingPainter(
                    bookedSeats: bookedSeatLabels,
                    selectedSeat: selectedSeatLabel,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class SeatingPainter extends CustomPainter {
  final List<String> bookedSeats;
  final String? selectedSeat;
  late final List<SeatPos> _seats;

  SeatingPainter({required this.bookedSeats, this.selectedSeat}) {
    _seats = _getStadiumLayout();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Skala Global
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(0.92, 0.92);
    canvas.translate(-size.width / 2, -size.height / 2);

    final double baseW = size.width * 0.068;
    final double baseH = size.height * 0.048;

    for (final seat in _seats) {
      final bool isBooked = bookedSeats.contains(seat.label); //
      final bool isSelected = seat.label == selectedSeat;

      // --- LOGIKA WARNA ---
      if (isBooked) {
        paint.color = Colors.black;
      } else if (isSelected) {
        paint.color = brandOrange;
      } else {
        paint.color = seat.color;
      }

      final Color tColor = (isBooked || isSelected) ? Colors.white : Colors.black;

      // Ukuran berdasarkan kategori
      double sizeMultiplier = 1.0;
      if (seat.color == cBlueCategory) sizeMultiplier = 1.05;
      else if (seat.color == cGreenCategory) sizeMultiplier = 0.95;
      else sizeMultiplier = 0.85;

      final double sW = baseW * sizeMultiplier;
      final double sH = baseH * sizeMultiplier;

      final dx = seat.rx * size.width;
      final dy = seat.ry * size.height;

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(seat.rot);

      // Menggambar bentuk kursi
      Path p = Path();
      double w = sW / 2;
      double h = sH / 2;
      p.moveTo(-w, -h);
      p.quadraticBezierTo(0, -h + (h * 0.3), w, -h);
      p.lineTo(w * 0.85, h);
      p.lineTo(-w * 0.85, h);
      p.close();

      canvas.drawPath(p, paint);
      
      final borderPaint = Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7;
      if (!isBooked && !isSelected) canvas.drawPath(p, borderPaint);

      _drawLabel(canvas, seat.label, tColor, sW);
      canvas.restore();
    }

    canvas.restore();
  }

  void _drawLabel(Canvas canvas, String txt, Color col, double mW) {
    final tp = TextPainter(
      text: TextSpan(
        text: txt, 
        style: TextStyle(color: col, fontSize: mW * 0.42, fontWeight: FontWeight.w700)
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: mW);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
  }

  @override
  bool shouldRepaint(SeatingPainter old) => 
      old.selectedSeat != selectedSeat || old.bookedSeats != bookedSeats;
}

class SeatPos {
  final String label;
  final Color color;
  final double rx, ry, rot;
  SeatPos(this.label, this.color, this.rx, this.ry, [this.rot = 0.0]);
}

List<SeatPos> _getStadiumLayout() {
  double rad(double deg) => deg * (math.pi / 180.0);
  return [
    // Sayap Kiri (Nilai RY diperpendek jaraknya menjadi 0.07 per baris)
    SeatPos('B4', cBlueCategory, 0.12, 0.15), SeatPos('B3', cGreenCategory, 0.20, 0.15), SeatPos('B2', cYellowCategory, 0.28, 0.15),
    SeatPos('C4', cBlueCategory, 0.12, 0.22), SeatPos('C3', cGreenCategory, 0.20, 0.22), SeatPos('C2', cYellowCategory, 0.28, 0.22),
    SeatPos('D4', cBlueCategory, 0.12, 0.29), SeatPos('D3', cGreenCategory, 0.20, 0.29), SeatPos('D2', cYellowCategory, 0.28, 0.29),
    SeatPos('E4', cBlueCategory, 0.12, 0.36), SeatPos('E3', cGreenCategory, 0.20, 0.36), SeatPos('E2', cYellowCategory, 0.28, 0.36),

    // Lengkungan Kiri (RY disesuaikan agar tetap mengikuti alur sayap yang naik)
    SeatPos('F4', cBlueCategory, 0.13, 0.45, rad(-15)), SeatPos('F3', cGreenCategory, 0.22, 0.44, rad(-15)), SeatPos('F2', cYellowCategory, 0.31, 0.43, rad(-15)),
    SeatPos('G5', cBlueCategory, 0.16, 0.56, rad(-35)), SeatPos('G3', cGreenCategory, 0.26, 0.53, rad(-35)), SeatPos('G2', cYellowCategory, 0.35, 0.51, rad(-35)),
    
    // Area Bawah (RY dikompres agar tidak terlalu jauh ke bawah)
    SeatPos('H5', cBlueCategory, 0.20, 0.68, rad(-60)), SeatPos('H3', cGreenCategory, 0.30, 0.64, rad(-60)), SeatPos('H2', cYellowCategory, 0.39, 0.60, rad(-60)),
    SeatPos('I5', cBlueCategory, 0.34, 0.81, rad(-20)), SeatPos('I3', cGreenCategory, 0.39, 0.73, rad(-20)), SeatPos('I2', cYellowCategory, 0.44, 0.65, rad(-20)),
    SeatPos('J5', cBlueCategory, 0.66, 0.81, rad(20)),  SeatPos('J3', cGreenCategory, 0.61, 0.73, rad(20)),  SeatPos('J2', cYellowCategory, 0.56, 0.65, rad(20)),
    SeatPos('K5', cBlueCategory, 0.80, 0.68, rad(60)),  SeatPos('K3', cGreenCategory, 0.70, 0.64, rad(60)),  SeatPos('K2', cYellowCategory, 0.61, 0.60, rad(60)),

    // Lengkungan Kanan
    SeatPos('L5', cBlueCategory, 0.84, 0.56, rad(35)), SeatPos('L3', cGreenCategory, 0.74, 0.53, rad(35)), SeatPos('L2', cYellowCategory, 0.65, 0.51, rad(35)),
    SeatPos('M4', cBlueCategory, 0.87, 0.45, rad(15)), SeatPos('M3', cGreenCategory, 0.78, 0.44, rad(15)), SeatPos('M2', cYellowCategory, 0.69, 0.43, rad(15)),

    // Sayap Kanan (Nilai RY diperpendek jaraknya agar rapat seperti sayap kiri)
    SeatPos('N4', cBlueCategory, 0.88, 0.36), SeatPos('N3', cGreenCategory, 0.80, 0.36), SeatPos('N2', cYellowCategory, 0.72, 0.36),
    SeatPos('O4', cBlueCategory, 0.88, 0.29), SeatPos('O3', cGreenCategory, 0.80, 0.29), SeatPos('O2', cYellowCategory, 0.72, 0.29),
    SeatPos('P4', cBlueCategory, 0.88, 0.22), SeatPos('P3', cGreenCategory, 0.80, 0.22), SeatPos('P2', cYellowCategory, 0.72, 0.22),
    SeatPos('Q4', cBlueCategory, 0.88, 0.15), SeatPos('Q3', cGreenCategory, 0.80, 0.15), SeatPos('Q2', cYellowCategory, 0.72, 0.15),
  ];
}