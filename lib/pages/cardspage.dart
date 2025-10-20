import 'package:expenses_tracker/components/myappbar.dart';
import 'package:expenses_tracker/components/mybutton.dart';
import 'package:expenses_tracker/components/mycards.dart';
import 'package:expenses_tracker/components/mynavbar.dart';
import 'package:expenses_tracker/components/mytextfield.dart';
import 'package:expenses_tracker/management/databasemanager.dart';
import 'package:expenses_tracker/models/cardmodel.dart';
import 'package:expenses_tracker/models/transactionmodel.dart';
import 'package:expenses_tracker/providers/balanceprovider.dart';
import 'package:expenses_tracker/providers/notificationprovider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class MyCardsPage extends StatefulWidget {
  const MyCardsPage({super.key, required this.email});
  final String email;

  @override
  State<MyCardsPage> createState() => _MyCardsPageState();
}

class _MyCardsPageState extends State<MyCardsPage> {
  final DatabaseManager _databaseManager = DatabaseManager();
  List<CardModel> _userCards = [];

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final cards = await _databaseManager.getCards(widget.email);
    setState(() => _userCards = cards);

    final provider = context.read<BalanceProvider>();

    provider.setCards(cards);

    if (cards.isNotEmpty) {
      final defaultCard =
          cards.firstWhere((c) => c.isDefault == 1, orElse: () => cards[0]);
      provider.setDefaultCard(defaultCard.id!);

      for (var card in cards) {
        final transactions = await _databaseManager.getTransactionsByCard(
            widget.email, card.id!);
        provider.setTransactionsForCard(card.id!, transactions);
      }
    }
  }

  Future<void> _setDefaultCard(CardModel card) async {
    await _databaseManager.setDefaultCard(widget.email, card.id!);
    await _loadCards();
  }

  Future<void> _deleteCardAndTransactions(CardModel card) async {
    final provider = context.read<BalanceProvider>();
    final notifProvider = context.read<NotificationProvider>();

    final transactions =
        await _databaseManager.getTransactionsByCard(widget.email, card.id!);
    for (TransactionModel t in transactions) {
      await _databaseManager.deleteTransaction(t.id!);
    }

    await _databaseManager.deleteCard(card.id!);
    provider.removeCard(card.id!);
    notifProvider.addCardRemoveNotification(
        card.cardnumber.substring(card.cardnumber.length - 4));

    await _loadCards();
  }

  //card add : edit dialog
  void _cardAddEditDialog({CardModel? card}) {
    final provider = context.read<BalanceProvider>();

    // ✅ Check if this card already has transactions
    final bool hasTransactions =
        card != null && provider.transactionsForCard(card.id!).isNotEmpty;

    // ✅ If editing, use current computed balance (not static stored amount)
    final TextEditingController amountController = TextEditingController(
      text: card != null
          ? provider.totalBalance(card.id!).toStringAsFixed(2)
          : '',
    );

    final TextEditingController cardNumberController =
        TextEditingController(text: card?.cardnumber ?? '');

    final TextEditingController expiryController =
        TextEditingController(text: card?.expirydate ?? '');

    final TextEditingController usernameController =
        TextEditingController(text: card?.username ?? '');

    Color color1 = card != null ? Color(card.colorOne) : Colors.blue;
    Color color2 = card != null ? Color(card.colorTwo) : Colors.orangeAccent;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setStateDialog) {
          return AlertDialog(
            backgroundColor: const Color(0xff181a1e),
            title: Text(
              card == null ? 'Add New Card' : 'Edit Card',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  // ✅ Amount field (disabled if transactions exist)
                  MyTextFormField(
                    controller: amountController,
                    hintText: 'Amount',
                    obscureText: false,
                    leadingIcon: const Icon(CupertinoIcons.money_dollar_circle),
                    enabled:
                        !hasTransactions, // 🔒 disable if transactions exist
                  ),

                  if (hasTransactions)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        "⚠️ Amount cannot be changed once transactions exist.",
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),

                  const SizedBox(height: 10),
                  MyTextFormField(
                    controller: cardNumberController,
                    hintText: 'Card Number',
                    obscureText: false,
                    leadingIcon: const Icon(CupertinoIcons.creditcard),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(16),
                    ],
                    enabled: false,
                  ),
                  const SizedBox(height: 10),

                  GestureDetector(
                    onTap: () async {
                      final theme = Theme.of(context);
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                        builder: (BuildContext context, Widget? child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Colors.green,
                                surface: Color(0xff181a1e),
                                onSurface: Colors.white,
                              ),
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              dialogBackgroundColor: const Color(0xff181a1e),
                            ),
                            child: child!,
                          );
                        },
                      );

                      if (pickedDate != null) {
                        setState(() {
                          expiryController.text =
                              "${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year.toString().substring(2)}";
                        });
                      }
                    },
                    child: AbsorbPointer(
                      child: MyTextFormField(
                        controller: expiryController,
                        hintText: 'Expiry Date (MM/YY)',
                        obscureText: false,
                        leadingIcon: const Icon(CupertinoIcons.calendar_today),
                        enabled: false,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  MyTextFormField(
                    controller: usernameController,
                    hintText: 'Username',
                    obscureText: false,
                    leadingIcon: const Icon(CupertinoIcons.person),
                    enabled: false,
                  ),

                  const SizedBox(height: 20),
                  const Text('Pick Card Colors:',
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: const Color(0xff181a1e),
                              title: const Text(
                                'Pick First Color',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              content: BlockPicker(
                                  pickerColor: color1,
                                  onColorChanged: (c) =>
                                      setStateDialog(() => color1 = c)),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text(
                                      'Ok',
                                      style: TextStyle(color: Colors.white),
                                    )),
                              ],
                            ),
                          );
                        },
                        child:
                            CircleAvatar(backgroundColor: color1, radius: 20),
                      ),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: const Color(0xff181a1e),
                              title: const Text(
                                'Pick Second Color',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              content: BlockPicker(
                                  pickerColor: color2,
                                  onColorChanged: (c) =>
                                      setStateDialog(() => color2 = c)),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text(
                                      'Ok',
                                      style: TextStyle(color: Colors.white),
                                    )),
                              ],
                            ),
                          );
                        },
                        child:
                            CircleAvatar(backgroundColor: color2, radius: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text("Cancel",
                        style: TextStyle(color: Colors.white)),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (cardNumberController.text.isNotEmpty &&
                          expiryController.text.isNotEmpty &&
                          usernameController.text.isNotEmpty &&
                          (!hasTransactions ||
                              amountController.text.isNotEmpty)) {
                        final balanceProvider = context.read<BalanceProvider>();
                        final newCard = CardModel(
                          id: card?.id,
                          email: widget.email,
                          amount: card != null
                              ? (hasTransactions
                                  ? card.amount // don’t change if locked
                                  : double.tryParse(amountController.text) ??
                                      0.0)
                              : double.tryParse(amountController.text) ?? 0.0,
                          cardnumber: cardNumberController.text,
                          expirydate: expiryController.text,
                          username: usernameController.text,
                          colorOne: color1.value,
                          colorTwo: color2.value,
                          isDefault: card?.isDefault ?? 0,
                        );

                        final notifProvider =
                            context.read<NotificationProvider>();

                        if (card == null) {
                          await _databaseManager.insertCard(newCard);
                          notifProvider.addNewCardNotification();
                        } else {
                          await _databaseManager.updateCard(newCard);
                          final cardNum = card.cardnumber;
                          final last4 = cardNum.length > 4
                              ? cardNum.substring(cardNum.length - 4)
                              : cardNum;
                          notifProvider.addCardUpdatedNotification(last4);
                        }

                        if (mounted) Navigator.of(ctx).pop();
                        await _loadCards();
                      }
                    },
                    child: Text(card == null ? "Add" : "Save",
                        style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BalanceProvider>();

    return Scaffold(
      backgroundColor: const Color(0xff181a1e),
      appBar: myAppBar(context, 'M Y  C A R D S'),
      body: _userCards.isEmpty
          ? const Center(
              child: Text("No cards yet. Add one!",
                  style: TextStyle(color: Colors.white70)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _userCards.length,
              itemBuilder: (ctx, i) {
                final card = _userCards[i];
                final isDefault = card.isDefault == 1;

                return Dismissible(
                  key: ValueKey(card.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: Colors.redAccent.shade700,
                    child: const Icon(CupertinoIcons.trash_fill,
                        color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    if (isDefault) {
                      await showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: const Color(0xff181a1e),
                          title: Text(
                            '⚠️ Default Card Warning',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.redAccent.shade700,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          content: const Text(
                            'You cannot delete your default card.\nPlease set another card as default first.',
                            style: TextStyle(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                          actions: [
                            Center(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      );
                      return false;
                    }

                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: const Color(0xff181a1e),
                        title: const Text('Confirm',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        content: const Text(
                          'Do you want to delete this card and all its transactions?',
                          style: TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                        actions: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel',
                                    style: TextStyle(color: Colors.white)),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Delete',
                                    style: TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );

                    return confirm ?? false;
                  },
                  onDismissed: (_) => _deleteCardAndTransactions(card),
                  child: GestureDetector(
                    onTap: () => _cardAddEditDialog(card: card),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        MyCards(
                          amount:
                              "\$${provider.totalBalance(card.id!).toStringAsFixed(2)}",
                          cardnumber: card.cardnumber,
                          expirydate: card.expirydate,
                          username: card.username,
                          colorOne: Color(card.colorOne),
                          colorTwo: Color(card.colorTwo),
                        ),
                        const SizedBox(height: 8),
                        isDefault
                            ? const Icon(
                                CupertinoIcons.check_mark_circled_solid,
                                color: Colors.green,
                                size: 28)
                            : MyButton(
                                textbutton: 'Set as Default',
                                onTap: () => _setDefaultCard(card),
                                buttonHeight: 50,
                                buttonWidth: 180,
                              ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 16),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () => _cardAddEditDialog(),
        child: const Icon(CupertinoIcons.add, color: Colors.white),
      ),
      bottomNavigationBar: MyNavBar(currentIndex: 1, email: widget.email),
    );
  }
}
