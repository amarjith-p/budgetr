// lib/features/scan_and_pay/models/upi_payment_models.dart

class UpiQrData {
  final String pa; // Payee VPA / UPI ID (e.g. merchant@paytm)
  final String pn; // Payee Name (e.g. Sharma Stores)
  final double? am; // Preset amount (if dynamic QR)
  final String? mc; // Merchant Category Code (e.g. 5411)
  final String? tr; // Transaction Reference ID
  final String? tn; // Transaction note
  final String cu; // Currency (INR)
  final String rawUri;

  const UpiQrData({
    required this.pa,
    required this.pn,
    this.am,
    this.mc,
    this.tr,
    this.tn,
    this.cu = 'INR',
    required this.rawUri,
  });

  /// Factory for manually entered UPI IDs (e.g. from the manual entry sheet)
  factory UpiQrData.fromManual({
    required String pa,
    String? pn,
    double? am,
    String? tn,
    String? mc,
  }) {
    final cleanPa = pa.trim();
    final cleanPn = (pn != null && pn.trim().isNotEmpty) ? pn.trim() : cleanPa;
    final buffer = StringBuffer('upi://pay?pa=$cleanPa&pn=${Uri.encodeComponent(cleanPn)}&cu=INR');
    if (am != null && am > 0) {
      buffer.write('&am=${am.toStringAsFixed(2)}');
    }
    if (tn != null && tn.trim().isNotEmpty) {
      buffer.write('&tn=${Uri.encodeComponent(tn.trim())}');
    }
    if (mc != null && mc.trim().isNotEmpty) {
      buffer.write('&mc=${mc.trim()}');
    }
    return UpiQrData(
      pa: cleanPa,
      pn: cleanPn,
      am: am,
      tn: tn,
      mc: mc,
      cu: 'INR',
      rawUri: buffer.toString(),
    );
  }

  /// Parses a raw QR string into [UpiQrData].
  /// Returns null if the QR is not a valid UPI payment string.
  static UpiQrData? tryParse(String raw) {
    final trimmed = raw.trim();
    if (!trimmed.toLowerCase().startsWith('upi://pay') &&
        !trimmed.contains('pa=')) {
      return null;
    }

    try {
      final uri = Uri.tryParse(trimmed);
      if (uri == null) return null;

      final params = uri.queryParameters;
      final pa = params['pa']?.trim() ?? '';
      if (pa.isEmpty || !pa.contains('@')) {
        return null; // A valid UPI ID must contain '@'
      }

      final pnRaw = params['pn']?.trim() ?? '';
      final pn = pnRaw.isNotEmpty ? Uri.decodeComponent(pnRaw) : pa;

      double? am;
      final amStr = params['am']?.trim();
      if (amStr != null && amStr.isNotEmpty) {
        am = double.tryParse(amStr);
      }

      final mc = params['mc']?.trim();
      final tr = params['tr']?.trim();
      final tnRaw = params['tn']?.trim();
      final tn = tnRaw != null ? Uri.decodeComponent(tnRaw) : null;
      final cu = params['cu']?.trim().toUpperCase() ?? 'INR';

      return UpiQrData(
        pa: pa,
        pn: pn,
        am: am,
        mc: mc,
        tr: tr,
        tn: tn,
        cu: cu,
        rawUri: trimmed,
      );
    } catch (_) {
      return null;
    }
  }

  /// Suggests a probable Budgetr expense category name based on the Merchant Category Code (MCC).
  String? guessCategoryName() {
    if (mc == null || mc!.isEmpty) return null;
    final code = mc!;

    if (const {'5411', '5422', '5441', '5451', '5462', '5499'}.contains(code)) {
      return 'Groceries';
    }
    if (const {'5812', '5813', '5814', '5811'}.contains(code)) {
      return 'Food & Dining';
    }
    if (const {'5541', '5542', '5983'}.contains(code)) {
      return 'Fuel';
    }
    if (const {'4121', '4111', '4131', '4011', '4789'}.contains(code)) {
      return 'Transportation';
    }
    if (const {'5311', '5999', '5651', '5611', '5621', '5691', '5732'}
        .contains(code)) {
      return 'Shopping';
    }
    if (const {'4814', '4900', '4899', '4812'}.contains(code)) {
      return 'Bills & Utilities';
    }
    if (const {'8062', '8011', '5912', '8021', '8049'}.contains(code)) {
      return 'Medical & Healthcare';
    }
    if (const {'7832', '7997', '7999', '7922'}.contains(code)) {
      return 'Entertainment';
    }
    return null;
  }
}

class PendingUpiPayment {
  final String id;
  final String payeeName;
  final String payeeVpa;
  final double amount;
  final String accountId;
  final String accountName;
  final String? categoryId;
  final String? categoryName;
  final int? categoryIcon;
  final String? subCategory;
  final int? bucketId;
  final String? bucketName;
  final String? note;
  final String? tags;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final String rawUpiUri;

  const PendingUpiPayment({
    required this.id,
    required this.payeeName,
    required this.payeeVpa,
    required this.amount,
    required this.accountId,
    required this.accountName,
    this.categoryId,
    this.categoryName,
    this.categoryIcon,
    this.subCategory,
    this.bucketId,
    this.bucketName,
    this.note,
    this.tags,
    this.locationName,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.rawUpiUri,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'payeeName': payeeName,
        'payeeVpa': payeeVpa,
        'amount': amount,
        'accountId': accountId,
        'accountName': accountName,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'categoryIcon': categoryIcon,
        'subCategory': subCategory,
        'bucketId': bucketId,
        'bucketName': bucketName,
        'note': note,
        'tags': tags,
        'locationName': locationName,
        'latitude': latitude,
        'longitude': longitude,
        'createdAt': createdAt.toIso8601String(),
        'rawUpiUri': rawUpiUri,
      };

  factory PendingUpiPayment.fromJson(Map<String, dynamic> json) {
    return PendingUpiPayment(
      id: json['id'] as String,
      payeeName: json['payeeName'] as String? ?? 'UPI Payee',
      payeeVpa: json['payeeVpa'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      accountId: json['accountId'] as String? ?? '',
      accountName: json['accountName'] as String? ?? 'Account',
      categoryId: json['categoryId'] as String?,
      categoryName: json['categoryName'] as String?,
      categoryIcon: json['categoryIcon'] as int?,
      subCategory: json['subCategory'] as String?,
      bucketId: json['bucketId'] as int?,
      bucketName: json['bucketName'] as String?,
      note: json['note'] as String?,
      tags: json['tags'] as String?,
      locationName: json['locationName'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      rawUpiUri: json['rawUpiUri'] as String? ?? '',
    );
  }
}
