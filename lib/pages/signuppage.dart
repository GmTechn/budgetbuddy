import 'package:expenses_tracker/components/mybutton.dart';
import 'package:expenses_tracker/components/mysquaretile.dart';
import 'package:expenses_tracker/components/mytextfield.dart';
import 'package:expenses_tracker/management/databasemanager.dart';
import 'package:expenses_tracker/management/sessionmanager.dart';
import 'package:expenses_tracker/models/usermodel.dart';
import 'package:expenses_tracker/pages/profilepage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SignUpPage extends StatefulWidget {
  final String email;
  const SignUpPage({super.key, required this.email});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Boolean for password visibility
  bool _isPasswordVisible = false;

  // Google sign-in instance
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Database instance
  final DatabaseManager _dbManager = DatabaseManager();

  // Instance of user
  AppUser? _user;

//initializing database
  @override
  void initState() {
    super.initState();
    _dbManager.initialisation();
  }

//show scaffold error message

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

//signing up a user
  Future<void> registerUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      showMessage("Please fill in all required fields.");
      return;
    }

    if (password != confirmPassword) {
      showMessage("Passwords do not match.");
      return;
    }

    if (!RegExp(r"^[\w\.-]+@[\w\.-]+\.\w+$").hasMatch(email)) {
      showMessage("Please enter a valid email address.");
      return;
    }

    try {
      final existingUser = await _dbManager.getUserByEmail(email);
      if (existingUser != null) {
        showMessage("An account with this email already exists.");
        return;
      }

      final newUser = AppUser(
        fname: '',
        lname: '',
        email: email,
        password: password,
        phone: '',
        photoPath: '',
      );

      await _dbManager.insertAppUser(newUser);
      await SessionManager.saveCurrentUser(newUser.email);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProfilePage(email: newUser.email),
        ),
      );
    } catch (e) {
      showMessage("Registration failed: $e");
    }
  }

  // Google Sign-In
  Future<void> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        showMessage('Signed in with Google');
        final existingUser = await _dbManager.getUserByEmail(account.email);
        if (existingUser == null) {
          final newUser = AppUser(
            fname: '',
            lname: '',
            email: account.email,
            password: '',
            phone: '',
            photoPath: '',
          );
          await _dbManager.insertAppUser(newUser);
          await SessionManager.saveCurrentUser(newUser.email);
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ProfilePage(email: account.email)),
        );
      }
    } catch (e) {
      showMessage('Google sign-in failed: $e');
    }
  }

  // Apple Sign-In

  Future<void> _handleAppleSignIn() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName
      ]);
      showMessage("Signed in with Apple: ${credential.email}");
      if (credential.email != null) {
        final existingUser = await _dbManager.getUserByEmail(credential.email!);
        if (existingUser == null) {
          final newUser = AppUser(
            fname: '',
            lname: '',
            email: credential.email!,
            password: '',
            phone: '',
            photoPath: '',
          );
          await _dbManager.insertAppUser(newUser);
          await SessionManager.saveCurrentUser(newUser.email);
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => ProfilePage(email: credential.email!)),
        );
      }
    } catch (e) {
      showMessage('Apple Sign-In failed: $e');
    }
  }

  // Error message
  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff181a1e),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color whiteColor = Colors.white;

    return Scaffold(
      backgroundColor: const Color(0xff181a1e),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.chart_bar_circle_fill,
                          color: Color.fromRGBO(76, 175, 80, 1),
                          size: 60,
                        ),
                        const SizedBox(height: 40),
                        Text(
                          'B U D G E T  B U D D Y',
                          style: GoogleFonts.abel(
                            fontWeight: FontWeight.bold,
                            fontSize: 30,
                            color: whiteColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Create an account here!',
                              style: TextStyle(color: Colors.white70),
                            ),
                            if (_user != null) ...[
                              Text(
                                _user != null ? "${_user!.fname}!" : "Guest!",
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ]
                          ],
                        ),
                        const SizedBox(height: 40),
                        MyTextFormField(
                          controller: emailController,
                          hintText: 'Email',
                          obscureText: false,
                          leadingIcon: const Icon(CupertinoIcons.envelope_fill,
                              color: Colors.white24),
                        ),
                        const SizedBox(height: 20),
                        MyTextFormField(
                          controller: passwordController,
                          hintText: 'Password',
                          obscureText: !_isPasswordVisible,
                          leadingIcon: const Icon(
                            CupertinoIcons.lock_fill,
                            color: Colors.white24,
                          ),
                          trailingIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? CupertinoIcons.eye_fill
                                  : CupertinoIcons.eye_slash_fill,
                              color: Colors.white24,
                            ),
                            onPressed: () => setState(
                                () => _isPasswordVisible = !_isPasswordVisible),
                          ),
                        ),
                        const SizedBox(height: 20),
                        MyTextFormField(
                          controller: confirmPasswordController,
                          hintText: 'Confirm Password',
                          obscureText: !_isPasswordVisible,
                          leadingIcon: const Icon(
                            CupertinoIcons.lock_fill,
                            color: Colors.white24,
                          ),
                          trailingIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? CupertinoIcons.eye_fill
                                  : CupertinoIcons.eye_slash_fill,
                              color: Colors.white24,
                            ),
                            onPressed: () => setState(
                                () => _isPasswordVisible = !_isPasswordVisible),
                          ),
                        ),
                        const SizedBox(height: 40),
                        MyButton(
                          textbutton: 'Sign Up',
                          onTap: registerUser,
                          buttonHeight: 40,
                          buttonWidth: 200,
                        ),
                        const SizedBox(height: 40),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child:
                                    Divider(thickness: .5, color: whiteColor),
                              ),
                              const SizedBox(width: 10),
                              Text('Or continue with',
                                  style: TextStyle(color: whiteColor)),
                              const SizedBox(width: 10),
                              Expanded(
                                child:
                                    Divider(thickness: .5, color: whiteColor),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 50),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            MySquareTile(
                              imagePath: 'assets/images/google.png',
                              onTap: signInWithGoogle,
                            ),
                            MySquareTile(
                              imagePath: 'assets/images/apple.png',
                              onTap: _handleAppleSignIn,
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Already have an account? ",
                                style: TextStyle(color: whiteColor)),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
