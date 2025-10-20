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
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local DB
  final dbManager = DatabaseManager();
  await dbManager.initialisation();

  //clearing local database
  //await dbManager.clearDatabase();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Migrate existing local users to Firebase
  await migrateLocalUsersToFirebase(dbManager);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BalanceProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

/// Migration function: pushes all users from local DB to Firebase
Future<void> migrateLocalUsersToFirebase(DatabaseManager dbManager) async {
  try {
    final users = await dbManager
        .getAllAppUsers(); // Make sure your DBManager has this method
    final firestore = FirebaseFirestore.instance;

    for (var user in users) {
      final docRef = firestore.collection('users').doc(user.email);
      final doc = await docRef.get();
      if (!doc.exists) {
        await docRef.set({
          'fname': user.fname,
          'lname': user.lname,
          'email': user.email,
          'password': user.password,
          'phone': user.phone,
          'photoPath': user.photoPath ?? '',
        });
      }
    }
    debugPrint('Migration to Firebase completed. Total users: ${users.length}');
  } catch (e) {
    debugPrint('Migration failed: $e');
  }
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
      home: initialEmail != null && initialEmail!.isNotEmpty
          ? Dashboard(email: initialEmail!)
          : const LoginPage(email: ''),
      onGenerateRoute: (settings) {
        final args = settings.arguments as Map<String, dynamic>?;

        switch (settings.name) {
          case '/signup':
            return MaterialPageRoute(
                builder: (_) => const SignUpPage(email: ''));
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
