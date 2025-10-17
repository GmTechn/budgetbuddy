import 'package:expenses_tracker/management/databasemanager.dart';
import 'package:expenses_tracker/models/transactionmodel.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class ChartsPage extends StatefulWidget {
  final String email;
  const ChartsPage({super.key, required this.email});

  @override
  State<ChartsPage> createState() => _ChartsPageState();
}

class _ChartsPageState extends State<ChartsPage> with TickerProviderStateMixin {
  //instance of database
  final dbManager = DatabaseManager();

  //list of all the transactions
  List<TransactionModel> _transactions = [];

  //list of grouped transactions to display
  //transactions by date & type
  Map<DateTime, List<TransactionModel>> grouped = {};

  //date time instance
  DateTime? _selectedDate;

  //filtering transactions
  bool _showFiltered = false;

  //list of listed transactions
  List<TransactionModel> _filteredTransactions = [];

  //animations and glows

  //glow controller
  late AnimationController _glowController;

  //glow animation
  late Animation<double> _glowAnimation;

  //fade controller
  late AnimationController _fadeController;

  //fade animation
  late Animation<double> _fadeAnimation;

  //offset animation
  late Animation<Offset> _slideAnimation;

  //initializing state
  @override
  void initState() {
    super.initState();
    _loadTransactions();

    //controlling the glow
    _glowController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    //controlling the fade

    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
  }

  //disposing of the contollers contents

  @override
  void dispose() {
    _glowController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  //loading transactions from database

  Future<void> _loadTransactions() async {
    final data = await dbManager.getTransactions(widget.email);
    data.sort((a, b) => a.date.compareTo(b.date));
    setState(() {
      _transactions = data;
      grouped.clear();
      for (var tx in data) {
        final day = DateTime(tx.date.year, tx.date.month, tx.date.day);
        grouped.putIfAbsent(day, () => []).add(tx);
      }
    });
  }

  ///on Bar tap function that displays daily transactions
  ///based on the datetime variable

  void _onBarTap(DateTime dateoftransaction, bool isIncome) {
    setState(() {
      if (_selectedDate == dateoftransaction && _showFiltered) {
        ///
        _showFiltered = false;
        _selectedDate = null;
        _filteredTransactions.clear();
        _glowController.stop();
        _fadeController.reverse();
      } else {
        ///display the filtered transaction
        ///by setting the date, the filters
        ///with year,month and day as filters
        _selectedDate = dateoftransaction;
        _filteredTransactions = _transactions
            .where((tx) =>
                tx.date.year == dateoftransaction.year &&
                tx.date.month == dateoftransaction.month &&
                tx.date.day == dateoftransaction.day &&
                ((isIncome && tx.amount > 0) || (!isIncome && tx.amount < 0)))
            .toList();
        _showFiltered = true;
        _glowController.repeat(reverse: true);
        _fadeController.forward(from: 0);
      }
    });
  }

  ///clear the filters or the selection
  void _clearSelection() {
    setState(() {
      _selectedDate = null;
      _showFiltered = false;
      _filteredTransactions.clear();
      _glowController.stop();
      _fadeController.reverse();
    });
  }

  ///this generates ticks that depend on the max value of y
  ///by dividing the max by 5 so the chartsbar won't
  ///go beyond the screen display

  List<double> _generateTicks(double maxY) {
    if (maxY <= 10) return [0, 2, 4, 6, 8, 10];
    if (maxY <= 50) return [0, 10, 20, 30, 40, 50];
    if (maxY <= 100) return [0, 20, 40, 60, 80, 100];
    if (maxY <= 500) return [0, 100, 200, 300, 400, 500];
    if (maxY <= 1000) return [0, 200, 400, 600, 800, 1000];
    double step = (maxY / 5).roundToDouble();
    return List.generate(6, (i) => i * step);
  }

  @override
  Widget build(BuildContext context) {
    ///sorting the transactions and grouping them
    final sortedDays = grouped.keys.toList()..sort();

    ///
    final maxTransaction = _transactions.isNotEmpty
        ? _transactions
            .map((t) => t.amount.abs())
            .reduce((a, b) => a > b ? a : b)
        : 100.0;

    ///
    final maxY = maxTransaction * 2;
    final ticks = _generateTicks(maxTransaction);

    return Scaffold(
      backgroundColor: const Color(0xff181a1e),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white70),
        backgroundColor: const Color(0xff181a1e),
        title: const Text(
          'O V E R V I E W',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: _clearSelection,
        behavior: HitTestBehavior.translucent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Flexible(
                flex: 2,
                child: AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, _) {
                    return BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxY,
                        minY: 0,
                        gridData: FlGridData(
                            show: true,
                            drawHorizontalLine: true,
                            getDrawingHorizontalLine: (value) {
                              return const FlLine(
                                  color: Colors.white10, strokeWidth: 1);
                            }),
                        borderData: FlBorderData(show: false),
                        barTouchData: BarTouchData(
                          touchCallback: (event, response) {
                            if (!event.isInterestedForInteractions ||
                                response == null ||
                                response.spot == null) return;

                            final idx = response.spot!.touchedBarGroupIndex;
                            final rodIdx = response.spot!.touchedRodDataIndex;
                            final day = sortedDays[idx];
                            final isIncome =
                                rodIdx == 0; // ✅ 0 = income, 1 = expense
                            _onBarTap(day, isIncome);
                          },
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (val, _) {
                                if (ticks.contains(val)) {
                                  return Text(
                                    val.toInt().toString(),
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 10),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, _) {
                                final idx = val.toInt();
                                if (idx >= 0 && idx < sortedDays.length) {
                                  final day = sortedDays[idx];
                                  return Text(
                                    '${day.day}/${day.month}',
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 10),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                        barGroups: List.generate(sortedDays.length, (index) {
                          final day = sortedDays[index];
                          final transactions = grouped[day]!;
                          final incomeTotal = transactions
                              .where((tx) => tx.amount > 0)
                              .fold(0.0, (a, b) => a + b.amount);
                          final expenseTotal = transactions
                              .where((tx) => tx.amount < 0)
                              .fold(0.0, (a, b) => a + b.amount.abs());

                          final isSelected = _selectedDate == day;

                          return BarChartGroupData(
                            x: index,
                            barsSpace: 18,
                            barRods: [
                              BarChartRodData(
                                toY: incomeTotal,
                                width: 20,
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  colors: isSelected
                                      ? [
                                          const Color(0xFF00FF94).withOpacity(
                                              _glowAnimation.value),
                                          const Color(0xFF00FFA2),
                                        ]
                                      : [
                                          Color(0xFF00FF94),
                                          Colors.blue,
                                        ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                              BarChartRodData(
                                toY: expenseTotal,
                                width: 20,
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  colors: isSelected
                                      ? [
                                          const Color(0xFFFF4D4D).withOpacity(
                                              _glowAnimation.value),
                                          const Color(0xFFFF1E1E),
                                        ]
                                      : const [
                                          Colors.orange,
                                          Color(0xFFFF4D4D),
                                        ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              if (_showFiltered)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141923),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredTransactions.length,
                        itemBuilder: (context, index) {
                          final tx = _filteredTransactions[index];
                          final isIncome = tx.amount > 0;
                          return ListTile(
                            leading: Icon(
                              isIncome
                                  ? Icons.arrow_downward_rounded
                                  : Icons.arrow_upward_rounded,
                              color: isIncome
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                            ),
                            title: Text(
                              tx.place,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            trailing: Text(
                              '${tx.amount > 0 ? '+' : ''}${tx.amount.toStringAsFixed(2)} \$',
                              style: TextStyle(
                                color: isIncome
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
