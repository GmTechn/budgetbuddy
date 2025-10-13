import 'package:flutter/material.dart';

PreferredSizeWidget myAppBar(BuildContext context, String title,
    {List<Widget>? actions}) {
  return AppBar(
    backgroundColor: const Color(0xff181a1e),
    title: Text(
      title,
      style: const TextStyle(
        color: Colors.white,
      ),
    ),
    actions: actions,
  );
}
