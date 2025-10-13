enum NotificationType {
  transaction, // Default for normal transactions
  system, // General system updates
  alert, // Warnings or errors
  newCard, // When a new card is added
  highExpense, // When spending is high
  incomeAdded, // When income is recorded
  balanceUpdated, // When balance changes significantly
  cardRemoved, // When a card is deleted
  lowBalance, // calculating low balance for treshold
}

class AppNotification {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final NotificationType type;
  bool read;
  final String? cardLast4;

  AppNotification({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.type,
    this.read = false,
    this.cardLast4,
  });

  factory AppNotification.create({
    required String title,
    required String description,
    required NotificationType type,
    String? cardLast4,
  }) {
    return AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      date: DateTime.now(),
      type: type,
      read: false,
      cardLast4: cardLast4,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
        'read': read ? 1 : 0,
        'cardLast4': cardLast4,
        'type': type.name,
      };

  factory AppNotification.fromMap(Map<String, dynamic> map) => AppNotification(
        id: map['id'],
        title: map['title'],
        description: map['description'],
        date: DateTime.parse(map['date']),
        type: NotificationType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => NotificationType.transaction,
        ),
        read: map['read'] == 1,
        cardLast4: map['cardLast4'],
      );
}
