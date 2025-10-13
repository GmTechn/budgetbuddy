import 'package:flutter/material.dart';

class MySquareTile extends StatelessWidget {
  const MySquareTile({
    super.key,
    this.onTap,
    required this.imagePath,
  });

  final Function()? onTap;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            color: Colors.white24,
            border: Border.all(color: const Color(0xff050c20)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Image.asset(imagePath)),
    );
  }
}
