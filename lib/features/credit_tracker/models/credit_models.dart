import 'package:cloud_firestore/cloud_firestore.dart';

class CreditCardModel {
  final String id;
  final String name;
  final String bankName;
  final double creditLimit;
  final int billDate; // Day of month (1-31)
  final int dueDate; // Day of month (1-31)
  final double currentBalance; // Amount used
  final Timestamp createdAt;

  CreditCardModel({
    required this.id,
    required this.name,
    required this.bankName,
    required this.creditLimit,
    required this.billDate,
    required this.dueDate,
    this.currentBalance = 0.0,
    required this.createdAt,
  });

  factory CreditCardModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CreditCardModel(
      id: doc.id,
      name: data['name'] ?? '',
      bankName: data['bankName'] ?? '',
      creditLimit: (data['creditLimit'] ?? 0.0).toDouble(),
      billDate: data['billDate'] ?? 1,
      dueDate: data['dueDate'] ?? 1,
      currentBalance: (data['currentBalance'] ?? 0.0).toDouble(),
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'bankName': bankName,
      'creditLimit': creditLimit,
      'billDate': billDate,
      'dueDate': dueDate,
      'currentBalance': currentBalance,
      'createdAt': createdAt,
    };
  }
}

class CreditTransactionModel {
  final String id;
  final String cardId;
  final double amount;
  final Timestamp date;
  final String bucket; // From Settings (e.g., Lifestyle)
  final String type; // 'Income' (Payment) or 'Expense' (Spend)
  final String category;
  final String subCategory;
  final String notes;

  CreditTransactionModel({
    required this.id,
    required this.cardId,
    required this.amount,
    required this.date,
    required this.bucket,
    required this.type,
    required this.category,
    required this.subCategory,
    required this.notes,
  });

  factory CreditTransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CreditTransactionModel(
      id: doc.id,
      cardId: data['cardId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      date: data['date'] ?? Timestamp.now(),
      bucket: data['bucket'] ?? 'Unallocated',
      type: data['type'] ?? 'Expense',
      category: data['category'] ?? 'General',
      subCategory: data['subCategory'] ?? 'General',
      notes: data['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cardId': cardId,
      'amount': amount,
      'date': date,
      'bucket': bucket,
      'type': type,
      'category': category,
      'subCategory': subCategory,
      'notes': notes,
    };
  }
}
