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
  final dbManager = DatabaseManager();
  List<TransactionModel> _transactions = [];
  Map<DateTime, List<TransactionModel>> grouped = {};
  DateTime? _selectedDate;
  bool _showFiltered = false;
  List<TransactionModel> _filteredTransactions = [];

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadTransactions();

    _glowController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _glowController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

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

  void _onBarTap(DateTime date, bool isIncome) {
    setState(() {
      if (_selectedDate == date && _showFiltered) {
        _showFiltered = false;
        _selectedDate = null;
        _filteredTransactions.clear();
        _glowController.stop();
        _fadeController.reverse();
      } else {
        _selectedDate = date;
        _filteredTransactions = _transactions
            .where((tx) =>
                tx.date.year == date.year &&
                tx.date.month == date.month &&
                tx.date.day == date.day &&
                ((isIncome && tx.amount > 0) || (!isIncome && tx.amount < 0)))
            .toList();
        _showFiltered = true;
        _glowController.repeat(reverse: true);
        _fadeController.forward(from: 0);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedDate = null;
      _showFiltered = false;
      _filteredTransactions.clear();
      _glowController.stop();
      _fadeController.reverse();
    });
  }

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
    final sortedDays = grouped.keys.toList()..sort();
    final maxTransaction = _transactions.isNotEmpty
        ? _transactions
            .map((t) => t.amount.abs())
            .reduce((a, b) => a > b ? a : b)
        : 100.0;
    final maxY = maxTransaction * 1.2;
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
                              return FlLine(
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
                                      : const [
                                          Color(0xFF005F38),
                                          Color(0xFF00FF94),
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
                                          Color(0xFF5F0000),
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
