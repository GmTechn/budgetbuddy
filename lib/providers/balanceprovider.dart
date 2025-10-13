import 'package:expenses_tracker/models/cardmodel.dart';
import 'package:expenses_tracker/models/transactionmodel.dart';
import 'package:expenses_tracker/providers/notificationprovider.dart';
import 'package:flutter/material.dart';

class BalanceProvider extends ChangeNotifier {
  //card id to differencier les cartes par leurs ids
  int? _defaultCardId;

  //generating a list of cards
  List<CardModel> _cards = [];

  //Mapping a list of transaction models
  Map<int, List<TransactionModel>> _cardTransactions = {};

  // --- Getters ---
  //getting a card by it's id, when it's been
  //set as a defaultcard
  int? get defaultCardId => _defaultCardId;

  //getting a list of cards to using a
  //card model
  List<CardModel> get cards => _cards;

  double get currentBalance {
    //setting a default card amount to 0
    //when it's none has been set to default
    if (_defaultCardId == null) return 0.0;

    ///giving to a card set by def, its specific
    ///set of transactions
    final transactions = _cardTransactions[_defaultCardId!] ?? [];
    //summing up all it's transactions
    return transactions.fold(0.0, (sum, t) => sum + t.amount);
  }

  //--- setters /actions ----

//getting the int for default card setting
//when a card has id 0, its deflaut
  void setDefaultCard(int cardId) {
    _defaultCardId = cardId;
    notifyListeners();
  }

//and other cards have 1 as int id, which
//automatically makes them "!default"
  void setCards(List<CardModel> cards) {
    _cards = cards;
    notifyListeners();
  }

//giving a specific card , it's specific transactions

  void setTransactionsForCard(int cardId, List<TransactionModel> transactions) {
    _cardTransactions[cardId] = transactions;
    notifyListeners();
  }

//adding a transaction to a card

  void addTransaction(int cardId, TransactionModel transaction) {
    _cardTransactions[cardId] ??= [];
    //putting transaction in stack, from last entered to
    //top of the list
    _cardTransactions[cardId]!.insert(0, transaction);
    notifyListeners();
  }

  //updating a transaction

  void updateTransaction(int cardId, TransactionModel transaction) {
    //get transaction for a specific card
    final transactions = _cardTransactions[cardId];

//if it doesn't have any, don't do anything
    if (transactions == null) return;

//now update a transaction using it's specific id
//cause each transaction is individual

    final index = transactions.indexWhere((t) => t.id == transaction.id);

    if (index != -1) {
      transactions[index] = transaction;
      notifyListeners();
    }
  }

  //removing a transaction

  void removeTransaction(int cardId, TransactionModel transaction) {
    //put the transaction into cardIdtrans
    final transactions = _cardTransactions[cardId];

//if it's null do nothing
    if (transactions == null) return;

//else remove the transaction by its id
    transactions.removeWhere((t) => t.id == transaction.id);
//and notify the listeners
    notifyListeners();
  }

//Set a list of the transactions for a specific card
//so each card is tied to their own transactions

  List<TransactionModel> transactionsForCard(int cardId) {
    return _cardTransactions[cardId] ?? [];
  }

//get the total balance of the card by Id

  double totalBalance(int cardId) {
    //if there are transactions, get the total
    //by calculating or summing the transactions
    final card = _cards.firstWhere(
      (c) => c.id == cardId,

      //if it's empty, return an empty card model
      orElse: () => CardModel.empty(),
    );

//baseAmount or amount to start from, is the amount set on the card
//during its initialization
    final baseAmount = card.amount;

    //get specific transactions for a card
    final transactions = _cardTransactions[cardId] ?? [];

    //then calculate the sum, which is for each card
    final transactionsSum = transactions.fold(0.0, (sum, t) => sum + t.amount);
//and give back the calculated amount
    return baseAmount + transactionsSum;
  }
  // ---- LOW BALANCE CHECK ----

  void _checkLowBalance(int cardId, NotificationProvider notifProvider) {
    final card = _cards.firstWhere(
      (c) => c.id == cardId,
      orElse: () => CardModel.empty(),
    );

    final balance = totalBalance(cardId);
    const double threshold = 50.0; // Customize this per user/card

    if (balance < threshold) {
      notifProvider.addLowBalanceNotification(balance, threshold);
    }
  }

  // ---- GET ALL TRANSACTIONS ----
  List<TransactionModel> get allTransactions {
    return _cardTransactions.values.expand((list) => list).toList();
  }
}
