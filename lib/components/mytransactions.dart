import 'package:flutter/material.dart';

class Mytransaction extends StatelessWidget {
  const Mytransaction({
    super.key,
    required this.logo,
    required this.title,
    required this.date,
    required this.amount,
  });

  final String logo;
  final String title;
  final String date;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 35, 37, 46),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo image of transaction
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: ClipOval(
              child: Image.network(
                logo,
                fit: BoxFit.fill,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Title + Transaction Date + Amount
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),

          // Amount (always well signed)
          Text(
            amount >= 0
                ? "+\$${amount.toStringAsFixed(2)}"
                : "-\$${amount.abs().toStringAsFixed(2)}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: amount >= 0 ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
