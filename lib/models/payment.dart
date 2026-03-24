// lib/models/payment.dart
class Payment {
  final String id;
  final String tenantId;
  final String tenantName;
  final String buildingId;
  final String lotId;
  final String lotName;
  final double amount;
  final DateTime dueDate;
  final DateTime? paymentDate;
  final String status; // 'paid', 'pending', 'late'
  final String? receiptId;

  Payment({
    required this.id,
    required this.tenantId,
    required this.tenantName,
    required this.buildingId,
    required this.lotId,
    required this.lotName,
    required this.amount,
    required this.dueDate,
    this.paymentDate,
    required this.status,
    this.receiptId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenantId': tenantId,
    'tenantName': tenantName,
    'buildingId': buildingId,
    'lotId': lotId,
    'lotName': lotName,
    'amount': amount,
    'dueDate': dueDate.toIso8601String(),
    'paymentDate': paymentDate?.toIso8601String(),
    'status': status,
    'receiptId': receiptId,
  };

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
    id: json['id'],
    tenantId: json['tenantId'],
    tenantName: json['tenantName'],
    buildingId: json['buildingId'],
    lotId: json['lotId'],
    lotName: json['lotName'],
    amount: json['amount'],
    dueDate: DateTime.parse(json['dueDate']),
    paymentDate: json['paymentDate'] != null ? DateTime.parse(json['paymentDate']) : null,
    status: json['status'],
    receiptId: json['receiptId'],
  );

  bool get isPaid => status == 'paid';
  bool get isLate => !isPaid && dueDate.isBefore(DateTime.now());
  String get formattedAmount => '${amount.toStringAsFixed(2)} €';
  String get formattedDueDate => '${dueDate.day}/${dueDate.month}/${dueDate.year}';
}