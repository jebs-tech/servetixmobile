class TicketHolder {
  final String nama;
  final String jenisKelamin;

  TicketHolder({
    required this.nama,
    required this.jenisKelamin,
  });

  Map<String, dynamic> toJson() {
    return {
      'nama': nama,
      'jenis_kelamin': jenisKelamin,
    };
  }
}

