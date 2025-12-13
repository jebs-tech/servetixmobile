class Voucher {
  final int id;
  final String code;
  final String discountType; // 'PERCENT' or 'FIXED'
  final double value;
  final double minPurchaseAmount;
  final int maxUseCount;
  final DateTime validFrom;
  final DateTime validUntil;

  Voucher({
    required this.id,
    required this.code,
    required this.discountType,
    required this.value,
    required this.minPurchaseAmount,
    required this.maxUseCount,
    required this.validFrom,
    required this.validUntil,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      id: json['id'] as int,
      code: json['code'] as String,
      discountType: json['discount_type'] as String,
      value: (json['value'] as num).toDouble(),
      minPurchaseAmount: (json['min_purchase_amount'] as num).toDouble(),
      maxUseCount: json['max_use_count'] as int,
      validFrom: DateTime.parse(json['valid_from'] as String),
      validUntil: DateTime.parse(json['valid_until'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'discount_type': discountType,
      'value': value,
      'min_purchase_amount': minPurchaseAmount,
      'max_use_count': maxUseCount,
      'valid_from': validFrom.toIso8601String(),
      'valid_until': validUntil.toIso8601String(),
    };
  }

  String get discountDisplay {
    if (discountType == 'PERCENT') {
      return '${value.toStringAsFixed(0)}%';
    } else {
      return 'Rp ${value.toStringAsFixed(0)}';
    }
  }

  String get minPurchaseDisplay {
    if (minPurchaseAmount == 0) {
      return 'Tidak ada minimum';
    }
    return 'Min. pembelian: Rp ${minPurchaseAmount.toStringAsFixed(0)}';
  }

  bool get isExpired {
    return DateTime.now().isAfter(validUntil);
  }

  bool get isValid {
    final now = DateTime.now();
    return !isExpired && now.isAfter(validFrom);
  }
}

