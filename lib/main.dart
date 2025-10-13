import 'package:expenses_tracker/management/databasemanager.dart';
import 'package:expenses_tracker/management/usersmanager.dart';
import 'package:expenses_tracker/pages/dashboardpage.dart';
import 'package:expenses_tracker/pages/loginpage.dart';
import 'package:expenses_tracker/pages/profilepage.dart';
import 'package:expenses_tracker/pages/signuppage.dart';
import 'package:expenses_tracker/pages/transactionspage.dart';
import 'package:expenses_tracker/providers/balanceprovider.dart';
import 'package:expenses_tracker/providers/notificationprovider.dart';
import 'package:flutter/material.dart';

import 'pages/cardspage.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dbManager = DatabaseManager();

  //clearing db

  //await dbManager.clearDatabase();

  // ✅ Initialise toujours la DB avec version:1

  await dbManager.initialisation();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => BalanceProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String? initialEmail;

  const MyApp({super.key, this.initialEmail});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Budget Buddy',
      theme: ThemeData(primarySwatch: Colors.blue),

      /// ✅ Si user existe → Dashboard
      /// ✅ Sinon → Login (car DB est vide au lancement)
      home: initialEmail != null && initialEmail!.isNotEmpty
          ? Dashboard(email: initialEmail!)
          : const LoginPage(email: ''),

      onGenerateRoute: (settings) {
        final args = settings.arguments as Map<String, dynamic>?;

        switch (settings.name) {
          case '/signup':
            return MaterialPageRoute(
                builder: (_) => const SignUpPage(
                      email: '',
                    ));
          case '/dashboard':
            return MaterialPageRoute(
              builder: (_) => Dashboard(email: args?['email'] ?? ''),
            );
          case '/transactions':
            return MaterialPageRoute(
              builder: (_) => TransactionsPage(email: args?['email'] ?? ''),
            );
          case '/mycards':
            return MaterialPageRoute(
              builder: (_) => MyCardsPage(email: args?['email'] ?? ''),
            );
          case '/profile':
            return MaterialPageRoute(
              builder: (_) => ProfilePage(email: args?['email'] ?? ''),
            );
          case '/usersList':
            return MaterialPageRoute(builder: (_) => const ListOfUsers());
          default:
            return null;
        }
      },
    );
  }
}
