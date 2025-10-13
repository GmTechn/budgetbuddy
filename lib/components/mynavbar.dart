import 'package:expenses_tracker/components/mycards.dart';
import 'package:expenses_tracker/pages/cardspage.dart';
import 'package:expenses_tracker/pages/dashboardpage.dart';
import 'package:expenses_tracker/pages/profilepage.dart';
import 'package:expenses_tracker/pages/transactionspage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MyNavBar extends StatelessWidget {
  const MyNavBar({super.key, required this.currentIndex, required this.email});

  final int currentIndex;
  final String email;
  final primaryColor = const Color(0xff4338CA);
  final secondaryColor = const Color(0xff6D28D9);
  final accentColor = const Color(0xffffffff);
  final backgroundColor = const Color(0xffffffff);
  final errorColor = const Color(0xffEF4444);

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: const Color(0xff181a1e),
      child: SizedBox(
        height: 56,
        width: MediaQuery.of(context).size.width,
        child: Padding(
          padding: const EdgeInsets.only(left: 25.0, right: 25.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              //dashboard page icon
              IconBottomBar(
                text: "Home",
                icon: CupertinoIcons.house_fill,
                selected: currentIndex == 0,
                onPressed: () {
                  if (currentIndex != 0) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Dashboard(
                          email: email,
                        ),
                      ),
                    );
                  }
                },
              ),

              //cards page icon
              IconBottomBar(
                text: "Cards",
                icon: CupertinoIcons.creditcard_fill,
                selected: currentIndex == 1,
                onPressed: () {
                  if (currentIndex != 1) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyCardsPage(
                          email: email,
                        ),
                      ),
                    );
                  }
                },
              ),

              //transactions page icon
              IconBottomBar(
                text: "Transactions",
                icon: CupertinoIcons.money_dollar_circle_fill,
                selected: currentIndex == 2,
                onPressed: () {
                  if (currentIndex != 2) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TransactionsPage(
                          email: email,
                        ),
                      ),
                    );
                  }
                },
              ),

              //Profile page icon
              IconBottomBar(
                text: "Profile",
                icon: CupertinoIcons.person_fill,
                selected: currentIndex == 3,
                onPressed: () {
                  if (currentIndex != 3) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(email: email),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IconBottomBar extends StatelessWidget {
  const IconBottomBar({
    super.key,
    required this.text,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String text;
  final IconData icon;
  final bool selected;
  final Function() onPressed;

  final primaryColor = Colors.green;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(
            icon,
            size: selected ? 30 : 25,
            color: selected ? primaryColor : Colors.white24,
          ),
        ),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            height: .1,
            color: selected ? primaryColor : Colors.white24,
          ),
        ),
      ],
    );
  }
}
