class CardModel {
  final int? id;
  final String email;
  final double amount;
  final String cardnumber;
  final double threshold; // Low balance threshold
  final String expirydate;
  final String username;
  final int colorOne;
  final int colorTwo;
  final int isDefault;

  CardModel({
    this.id,
    required this.email,
    required this.amount,
    required this.cardnumber,
    this.threshold = 100.0,
    required this.expirydate,
    required this.username,
    required this.colorOne,
    required this.colorTwo,
    this.isDefault = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'amount': amount,
      'cardnumber': cardnumber,
      'expirydate': expirydate,
      'username': username,
      'colorOne': colorOne,
      'colorTwo': colorTwo,
      'isDefault': isDefault,
    };
  }

  factory CardModel.fromMap(Map<String, dynamic> map) {
    return CardModel(
      id: map['id'] as int?,
      email: map['email']?.toString() ?? '',
      amount: map['amount'] is double
          ? map['amount'] as double
          : map['amount'] is int
              ? (map['amount'] as int).toDouble()
              : double.tryParse(map['amount'].toString()) ?? 0.0,
      cardnumber: map['cardnumber']?.toString() ?? '',
      expirydate: map['expirydate']?.toString() ?? '',
      username: map['username']?.toString() ?? '',
      colorOne: map['colorOne'] as int? ?? 0,
      colorTwo: map['colorTwo'] as int? ?? 0,
      isDefault: map['isDefault'] as int? ?? 0,
    );
  }

//==== Empty card model when login for the first time =====
  static CardModel empty() {
    return CardModel(
      id: -1,
      email: '',
      amount: 0.0,
      cardnumber: '',
      expirydate: '',
      username: '',
      colorOne: 0,
      colorTwo: 0,
      isDefault: 0,
    );
  }

  // === copy with method ===
  CardModel copyWith({
    int? id,
    String? email,
    double? amount,
    String? cardnumber,
    String? expirydate,
    String? username,
    int? colorOne,
    int? colorTwo,
    int? isDefault,
    double? threshold,
  }) {
    return CardModel(
      id: id ?? this.id,
      email: email ?? this.email,
      amount: amount ?? this.amount,
      cardnumber: cardnumber ?? this.cardnumber,
      expirydate: expirydate ?? this.expirydate,
      username: username ?? this.username,
      colorOne: colorOne ?? this.colorOne,
      colorTwo: colorTwo ?? this.colorTwo,
      isDefault: isDefault ?? this.isDefault,
      threshold: threshold ?? this.threshold,
    );
  }
}
