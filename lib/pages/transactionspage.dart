import 'package:expenses_tracker/models/transactionmodel.dart';
import 'package:expenses_tracker/models/usermodel.dart';
import 'package:expenses_tracker/pages/overviewpage.dart';
import 'package:expenses_tracker/providers/balanceprovider.dart';
import 'package:expenses_tracker/providers/notificationprovider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:expenses_tracker/components/mynavbar.dart';
import 'package:expenses_tracker/components/mytextfield.dart';
import 'package:expenses_tracker/management/databasemanager.dart';
import 'package:provider/provider.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key, required this.email});
  final String email;

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  //database manager
  final dbManager = DatabaseManager();

  final List<TransactionModel> _transactions = [];
  final _formKey = GlobalKey<FormState>();
  final _placeController = TextEditingController();
  final _amountController = TextEditingController();
  String? _selectedBrand;

  final Map<String, String> brandLogos = {
    'Adobe':
        "https://tse2.mm.bing.net/th/id/OIP.mM9NRRVAHaDQL0nr_pALqwHaFj?cb=12&w=800&h=600&rs=1&pid=ImgDetMain&o=7&rm=3",
    'Amazon': 'https://wallpapercave.com/wp/wp7771222.png',
    'Apple':
        'https://w7.pngwing.com/pngs/589/546/png-transparent-apple-logo-new-york-city-brand-computer-apple-company-computer-logo.png',
    'Direct Deposit':
        'https://www.shutterstock.com/image-vector/building-vector-icon-column-bank-600nw-1930635143.jpg',
    'Disney Plus':
        "https://vectorseek.com/wp-content/uploads/2024/03/Disney-2024-Logo-Vector-3-1024x1024.png",
    'DoorDash':
        "https://www.shutterstock.com/image-vector/kerala-india-09082023-doordash-food-600nw-2344891519.jpg",
    'Facebook':
        'https://www.citypng.com/public/uploads/preview/round-blue-circle-contains-f-letter-facebook-logo-701751695134712lb9coc4kea.png',
    'Google':
        'https://4kwallpapers.com/images/wallpapers/google-logo-5k-8k-7680x4320-11298.png',
    'H&M':
        'https://e7.pngegg.com/pngimages/43/204/png-clipart-logo-h-m-brand-clothing-logo-hm.png',
    'Instagram':
        'https://img.freepik.com/free-vector/instagram-icon_1057-2227.jpg?semt=ais_hybrid&w=740&q=80',
    'Interact':
        'https://canadianhorsedefencecoalition.org/wp-content/uploads/2021/06/Interac_Brand_2021-1024x1024.png',
    'Loblaws':
        'https://cdn.freebiesupply.com/logos/large/2x/loblaws-logo-png-transparent.png',
    'Lyft':
        "https://play-lh.googleusercontent.com/DSChqzPVvt0F4mGutfwuZNtcpmBIJCYlr-erQ3g41rsNfJkeMYQExxTXB7Wi9MQCOFw",
    'Microsoft':
        'https://static.vecteezy.com/system/resources/previews/014/018/578/non_2x/microsoft-logo-on-transparent-background-free-vector.jpg',
    'Microsoft Excel':
        "https://th.bing.com/th/id/OIP.eAB8kM9ESZ8NvW4jN6maSwHaEo?w=289&h=180&c=7&r=0&o=7&cb=12&dpr=2&pid=1.7&rm=3",
    'Microsoft PowerPoint':
        "https://drawmill.com/wp-content/uploads/2024/06/powerpoint-circle.png",
    'Microsoft Word':
        "https://th.bing.com/th/id/OIP.6c8ogw6RkBNX_MgY7yuIAAHaEo?w=298&h=186&c=7&r=0&o=7&cb=12&dpr=2&pid=1.7&rm=3",
    'MoneyGram':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/5/50/MoneyGram_Logo.svg/2560px-MoneyGram_Logo.svg.png',
    'Netflix': 'https://images3.alphacoders.com/115/1152293.png',
    'Nike':
        'https://www.muraldecal.com/en/img/asfs364-jpg/folder/products-listado-merchanthover/stickers-nike-on-your-logo.jpg',
    'Paypal': 'https://static.cdnlogo.com/logos/p/9/paypal.png',
    'Samsung': 'https://www.pc-canada.com/dd2/img/item/B-500x500/-/Samsung.jpg',
    'Shein': 'https://1000logos.net/wp-content/uploads/2021/05/Shein-logo.png',
    'Spotify':
        'https://www.freepnglogos.com/uploads/spotify-logo-png/spotify-logo-spotify-symbol-3.png',
    'TikTok': 'https://purepng.com/public/uploads/large/tik-tok-logo-6fh.png',
    'Twitter':
        'https://upload.wikimedia.org/wikipedia/commons/7/71/Twitter_Logo_Blue_%282%29.png',
    'Uber': "https://images.icon-icons.com/2407/PNG/512/uber_icon_146079.png",
    'Uber Eats':
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRT7cTyrYHxcrxLMmPD76qfLDvG7HNMDEEbJQ&s",
    'Walmart':
        'https://www.per-accurate.com/wp-content/uploads/2023/08/walmart-logo-24.jpg',
    'Wise':
        'https://d21buns5ku92am.cloudfront.net/69645/images/470455-Frame%2039263-cdfad6-medium-1677657684.png',
    'Zara': 'https://logos-world.net/wp-content/uploads/2020/05/Zara-Logo.png',
  };

  //liste of brands
  List<String> get sortedBrands => brandLogos.keys.toList()..sort();

  //appuser instance
  AppUser? _currentUser;

  //state initialization

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadTransactions();
  }

  //loading users
  Future<void> _loadUsers() async {
    final _user = await dbManager.getUserByEmail(widget.email);
    if (mounted) {
      setState(() {
        _currentUser = _user;
      });
    }
  }

  //loading transactions
  Future<void> _loadTransactions() async {
    final data = await dbManager.getTransactions(widget.email);
    data.sort((a, b) => b.date.compareTo(a.date));
    setState(() {
      _transactions.clear();
      _transactions.addAll(data);
    });
  }

  double get totalTransactionsAmount {
    final provider = context.read<BalanceProvider>();
    final cardId = provider.defaultCardId;
    if (cardId == null) return 0.0;
    final transactions = provider.transactionsForCard(cardId);

    double total = 0.0;
    for (var t in transactions) {
      total += t.type.toLowerCase() == 'income' ? t.amount : -t.amount;
    }
    return total;
  }

  void _openTransactionDialog({TransactionModel? transaction}) {
    String? _selectedType = transaction != null
        ? (transaction.type.toLowerCase() == 'income' ? 'Income' : 'Expense')
        : null;

    if (transaction != null) {
      _placeController.text = transaction.place;
      _amountController.text = transaction.amount.toString();
      _selectedBrand = brandLogos.entries
          .firstWhere((entry) => entry.value == transaction.logoPath,
              orElse: () => const MapEntry('', ''))
          .key;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xff181a1e),
          title: Text(
            transaction == null ? 'Add Transaction' : 'Edit Transaction',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MyTextFormField(
                    leadingIcon: const Icon(CupertinoIcons.placemark),
                    controller: _placeController,
                    hintText: 'Merchant',
                    obscureText: false,
                    validator: (value) =>
                        value!.isEmpty ? "Enter a place" : null,
                    enabled: false,
                  ),
                  const SizedBox(height: 10),
                  MyTextFormField(
                    leadingIcon: const Icon(CupertinoIcons.money_dollar),
                    controller: _amountController,
                    hintText: 'Amount',
                    obscureText: false,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) =>
                        value!.isEmpty ? "Enter amount" : null,
                    enabled: false,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    hint: const Text(
                      'Select Brand',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                    value: _selectedBrand,
                    items: sortedBrands
                        .map((brand) => DropdownMenuItem(
                              value: brand,
                              child: Text(
                                brand,
                              ),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedBrand = value),
                    validator: (value) =>
                        value == null ? 'Select a brand' : null,
                    style: const TextStyle(color: Colors.white),
                    dropdownColor: const Color(0xff282b32),
                    decoration: InputDecoration(
                      fillColor: const Color.fromARGB(255, 40, 43, 50),
                      filled: true,
                      prefixIcon: const Icon(CupertinoIcons.tag),
                      prefixIconColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 40, 43, 50),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.red),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.red),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    hint: const Text(
                      'Select Type',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                    value: _selectedType,
                    items: const [
                      DropdownMenuItem(
                        value: 'Income',
                        child: Text('Income',
                            style: TextStyle(color: Colors.white)),
                      ),
                      DropdownMenuItem(
                        value: 'Expense',
                        child: Text('Expense',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                    onChanged: (value) => setState(() => _selectedType = value),
                    validator: (value) =>
                        value == null ? 'Select a type' : null,
                    style: const TextStyle(color: Colors.white),
                    dropdownColor: const Color(0xff282b32),
                    decoration: InputDecoration(
                      fillColor: const Color.fromARGB(255, 40, 43, 50),
                      filled: true,
                      prefixIcon: const Icon(CupertinoIcons.arrow_2_circlepath),
                      prefixIconColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                            color: Color.fromARGB(255, 40, 43, 50)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.red),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.red),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final place = _placeController.text;
                      final amountValue = double.parse(_amountController.text);
                      final isIncome = _selectedType == 'Income';
                      final amount = isIncome ? amountValue : -amountValue;
                      final logoPath = _selectedBrand != null
                          ? brandLogos[_selectedBrand!]
                          : null;

                      final balanceProvider = context.read<BalanceProvider>();
                      final notifProvider =
                          context.read<NotificationProvider>();
                      final defaultCardId = balanceProvider.defaultCardId;

                      if (defaultCardId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please set a default card first')),
                        );
                        return;
                      }

                      TransactionModel transactionModel;

                      if (transaction != null) {
                        transactionModel = transaction.copyWith(
                          place: place,
                          amount: amount,
                          logoPath: logoPath,
                          type: isIncome ? 'income' : 'expense',
                        );
                        balanceProvider.updateTransaction(
                            defaultCardId, transactionModel);
                        await dbManager.updateTransaction(transactionModel);
                      } else {
                        transactionModel = TransactionModel(
                          email: widget.email,
                          place: place,
                          amount: amount,
                          date: DateTime.now(),
                          logoPath: logoPath,
                          cardId: defaultCardId,
                          type: isIncome ? 'income' : 'expense',
                        );

                        // ✅ Use provider logic here
                        balanceProvider.addTransaction(
                            defaultCardId, transactionModel);
                        await dbManager.insertTransaction(transactionModel);

                        // 🧠 Notifications logic
                        if (isIncome) {
                          if (amountValue > 500) {
                            notifProvider
                                .addHighIncomeNotification(amountValue);
                          } else {
                            notifProvider.addIncomeNotification(amountValue);
                          }
                        } else {
                          final currentBalance =
                              balanceProvider.totalBalance(defaultCardId);

                          if (currentBalance <
                              (balanceProvider.cards
                                      .firstWhere((c) => c.id == defaultCardId)
                                      .threshold ??
                                  100.0)) {
                            notifProvider.addLowBalanceNotification(
                              currentBalance,
                              balanceProvider.cards
                                      .firstWhere((c) => c.id == defaultCardId)
                                      .threshold ??
                                  100.0,
                            );
                          } else {
                            notifProvider.addExpenseNotification(
                                amountValue, place);
                          }
                        }
                      }

                      if (mounted) Navigator.pop(context);
                      _placeController.clear();
                      _amountController.clear();
                      _selectedBrand = null;
                    }
                  },
                  child: const Text(
                    "Save",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BalanceProvider>();
    final _transactions = provider.defaultCardId != null
        ? provider.transactionsForCard(provider.defaultCardId!)
        : [];

    return Scaffold(
      backgroundColor: const Color(0xff181a1e),
      appBar: AppBar(
        title: const Text('T R A N S A C T I O N S',
            style: TextStyle(color: Colors.white)),
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xff181a1e),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChartsPage(
                      email: widget.email,
                    ),
                  ),
                );
              },
              icon: const Icon(
                CupertinoIcons.right_chevron,
                color: Colors.white70,
              ))
        ],
      ),
      body: Column(
        children: [
          Expanded(
              child: _transactions.isEmpty
                  ? const Center(
                      child: Text("No transactions yet",
                          style: TextStyle(color: Colors.white70)))
                  : ListView.builder(
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final t = _transactions[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Dismissible(
                            key: ValueKey(t.id),
                            background: Container(
                              color: Colors.redAccent.shade700,
                              alignment: Alignment.centerRight,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: const Icon(CupertinoIcons.trash_fill,
                                  color: Colors.white),
                            ),
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) async {
                              await dbManager.deleteTransaction(t.id!);
                              if (provider.defaultCardId != null) {
                                provider.removeTransaction(
                                    provider.defaultCardId!, t);
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Transaction deleted!')),
                              );
                            },
                            child: ListTile(
                              onTap: () =>
                                  _openTransactionDialog(transaction: t),
                              leading:
                                  t.logoPath != null && t.logoPath!.isNotEmpty
                                      ? CircleAvatar(
                                          radius: 28,
                                          backgroundColor: Colors.white,
                                          child: ClipOval(
                                              child: Image.network(t.logoPath!,
                                                  fit: BoxFit.fill)),
                                        )
                                      : const CircleAvatar(
                                          backgroundColor: Colors.white,
                                          child: Icon(CupertinoIcons.cart_fill,
                                              color: Color(0xff181a1e)),
                                        ),
                              title: Text(t.place,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                  "${t.date.day}/${t.date.month}/${t.date.year}",
                                  style:
                                      const TextStyle(color: Colors.white54)),
                              trailing: Text(
                                t.amount >= 0
                                    ? "+\$${t.amount.toStringAsFixed(2)}"
                                    : "-\$${t.amount.abs().toStringAsFixed(2)}",
                                style: TextStyle(
                                    color: t.amount >= 0
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        );
                      },
                    )),
          Container(
            decoration: const BoxDecoration(
                border:
                    Border(top: BorderSide(width: .5, color: Colors.white54))),
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white70)),
                Text('\$${totalTransactionsAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () => _openTransactionDialog(),
        child: const Icon(CupertinoIcons.add, color: Colors.white),
      ),
      bottomNavigationBar: MyNavBar(currentIndex: 2, email: widget.email),
    );
  }
}
