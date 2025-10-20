import 'package:expenses_tracker/models/notificationmodel.dart';
import 'package:flutter/material.dart';

class NotificationProvider extends ChangeNotifier {
  // List of all notifications
  final List<AppNotification> _notifications = [];

  // Get all notifications sorted by date
  List<AppNotification> get allNotifications =>
      _notifications..sort((a, b) => b.date.compareTo(a.date));

  // Count of unread notifications
  int get unreadCount => _notifications.where((n) => !n.read).length;

  // Add a notification
  void addNotification(AppNotification notification) {
    _notifications.add(notification);
    notifyListeners();
  }

  // Mark a notification as read
  void markAsRead(String id) {
    final notif = _notifications.firstWhere((n) => n.id == id);
    notif.read = true;
    notifyListeners();
  }

  // Mark all notifications as read
  void markAllAsRead() {
    for (var n in _notifications) {
      n.read = true;
    }
    notifyListeners();
  }

  // Delete a notification
  void deleteNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  // ---- Transaction Notifications ----

  //adding income
  void addIncomeNotification(double amount) {
    addNotification(
      AppNotification.create(
        title: "Income",
        description:
            "Income added to your account - \$${amount.toStringAsFixed(2)}.",
        type: NotificationType.incomeAdded,
      ),
    );
  }

  //adding high income
  void addHighIncomeNotification(double amount) {
    addNotification(
      AppNotification.create(
        title: "⚠️High income alert!",
        description: "High income recorded - \$${amount.toStringAsFixed(2)}!",
        type: NotificationType.highExpense,
      ),
    );
  }

  //adding expense notification
  void addExpenseNotification(double amount, String place) {
    addNotification(
      AppNotification.create(
        title: "Expense",
        description:
            "Expense from $place added - \$${amount.toStringAsFixed(2)}.",
        type: NotificationType.transaction,
      ),
    );
  }

  //adding low balance notification
  void addLowBalanceNotification(double currentBalance, double threshold) {
    addNotification(
      AppNotification.create(
        title: "⚠️Low balance warning!",
        description:
            "Your balance is low: \$${currentBalance.toStringAsFixed(2)} (below threshold \$${threshold.toStringAsFixed(2)}).",
        type: NotificationType.lowBalance,
      ),
    );
  }

  // ---- Card Notifications ---- //
  //adding a new card
  void addNewCardNotification() {
    addNotification(
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'A new card was added!',
        description: 'Your new debit card is now active.',
        type: NotificationType.newCard,
        date: DateTime.now(),
      ),
    );
  }

  //removing card notification
  void addCardRemoveNotification(String last4) {
    addNotification(
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Card removed successfully',
        description: 'Your card ending in ****$last4 has been deleted.',
        type: NotificationType.cardRemoved,
        date: DateTime.now(),
      ),
    );
  }

  //updating card notification
  void addCardUpdatedNotification(String last4) {
    addNotification(
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Card updated successfully',
        description: 'Your card ending in ****$last4 has been updated.',
        type: NotificationType.cardUpdated, // new type
        date: DateTime.now(),
      ),
    );
  }
}
