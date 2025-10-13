class TransactionModel {
  final int? id;
  final String email;
  final String place;
  final double amount;
  final DateTime date;
  final String? logoPath;
  final int cardId;
  final String type; // 'income' ou 'expense'

  TransactionModel({
    this.id,
    required this.email,
    required this.place,
    required this.amount,
    required this.date,
    this.logoPath,
    required this.cardId,
    this.type = 'expense',
  });

  TransactionModel copyWith({
    int? id,
    String? email,
    String? place,
    double? amount,
    DateTime? date,
    String? logoPath,
    int? cardId,
    String? type,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      email: email ?? this.email,
      place: place ?? this.place,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      logoPath: logoPath ?? this.logoPath,
      cardId: cardId ?? this.cardId,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'place': place,
      'amount': amount,
      'date': date.toIso8601String(),
      'logoPath': logoPath,
      'cardId': cardId,
      'type': type, // ✅ ajouter ici
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      email: map['email'],
      place: map['place'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      logoPath: map['logoPath'],
      cardId: map['cardId'],
      type: map['type'] ?? 'expense', // default si null
    );
  }
}
