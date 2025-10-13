import 'package:flutter/material.dart';

class MyCards extends StatelessWidget {
  const MyCards({
    super.key,
    required this.amount,
    required this.cardnumber,
    required this.expirydate,
    required this.username,
    required this.colorOne,
    required this.colorTwo,
  });

  final String amount;
  final String cardnumber;
  final String expirydate;
  final String username;
  final Color colorOne;
  final Color colorTwo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 237,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorOne,
                colorTwo,
              ])),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            amount,
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(
            height: 20,
          ),
          Text(
            cardnumber,
            style: const TextStyle(
              letterSpacing: 2,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              // color: Colors.white
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          const Text(
            'VALID TRHU',
            style: TextStyle(
              fontSize: 14,
              // fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            expirydate,
            style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            username,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          )
        ],
      ),
    );
  }
}
