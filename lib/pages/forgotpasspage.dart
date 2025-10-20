import 'package:expenses_tracker/components/mybutton.dart';
import 'package:expenses_tracker/components/mytextfield.dart';
import 'package:expenses_tracker/management/databasemanager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    //controller
    final emailController = TextEditingController();

    //database instance
    final DatabaseManager dbManager = DatabaseManager();

    //reset link function
    Future<void> _sendResetLink() async {
      final email = emailController.text.trim();

      if (email.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your email!')),
        );
        return;
      }

      final user = await dbManager.getUserByEmail(email);
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No account found with this email!')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reset link sent to $email')),
      );
      // Note: since we're using local DB, you may later add actual email service.
    }

    return Scaffold(
      backgroundColor: const Color(0xff181a1e),
      appBar: AppBar(
        backgroundColor: const Color(0xff181a1e),
        title: const Text(
          'R E S E T',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.lock_fill,
              size: 60,
              color: Colors.white70,
            ),
            const SizedBox(height: 20),
            const Text(
              'Enter your email to reset password:',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 40),
            MyTextFormField(
              controller: emailController,
              hintText: 'Email',
              obscureText: false,
              leadingIcon: const Icon(
                CupertinoIcons.envelope_fill,
                color: Colors.white70,
              ),
              enabled: false,
            ),
            const SizedBox(height: 40),
            MyButton(
              textbutton: 'Send reset link',
              onTap: _sendResetLink,
              buttonHeight: 40,
              buttonWidth: 200,
            ),
          ],
        ),
      ),
    );
  }
}
