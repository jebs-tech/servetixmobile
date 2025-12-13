class Voucher {
  final int id;
  final String code;
  final String description;
  final double discount;
  final int maxUses;
  final int usedCount;
  final String validUntil;
  final bool isActive;

  Voucher({
    required this.id,
    required this.code,
    required this.description,
    required this.discount,
    required this.maxUses,
    required this.usedCount,
    required this.validUntil,
    required this.isActive,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      id: json["id"],
      code: json["code"],
      description: json["description"],
      discount: (json["discount"] as num).toDouble(),
      maxUses: json["max_uses"],
      usedCount: json["used_count"],
      validUntil: json["valid_until"],
      isActive: json["is_active"],
    );
  }
}
