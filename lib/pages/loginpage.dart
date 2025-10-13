import 'package:expenses_tracker/components/mybutton.dart';
import 'package:expenses_tracker/components/mysquaretile.dart';
import 'package:expenses_tracker/components/mytextfield.dart';
import 'package:expenses_tracker/management/databasemanager.dart';
import 'package:expenses_tracker/models/usermodel.dart';
import 'package:expenses_tracker/pages/dashboardpage.dart';
import 'package:expenses_tracker/pages/forgotpasspage.dart';
import 'package:expenses_tracker/pages/signuppage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class LoginPage extends StatefulWidget {
  final String email;
  const LoginPage({super.key, required this.email});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Boolean for password visibility
  bool _isPasswordVisible = false;

  // Google sign-in instance
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Database instance
  final DatabaseManager _dbManager = DatabaseManager();

  // Instance of user
  AppUser? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  // Load user from DB
  Future<void> _loadUser() async {
    final user = await _dbManager.getUserByEmail(widget.email);
    if (mounted) {
      setState(() {
        _user = user;
      });
    }
  }

  // Google Sign-In
  Future<void> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => Dashboard(email: account.email)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: $e')),
      );
    }
  }

  // Apple Sign-In
  Future<void> _handleAppleSignIn() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName
        ],
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => Dashboard(email: credential.email ?? '')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Apple Sign-In failed: $e')),
      );
    }
  }

  // Error message
  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xff181a1e),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  // Local login
  Future<void> loginUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showErrorMessage("Please fill all fields.");
      return;
    }

    if (!RegExp(r"^[\w\.-]+@[\w\.-]+\.\w+$").hasMatch(email)) {
      showErrorMessage("Please enter a valid email address.");
      return;
    }

    try {
      final user = await _dbManager.getUserByEmail(email);

      if (user == null) {
        showErrorMessage("No account found with this email.");
        return;
      }

      if (user.password != password) {
        showErrorMessage("Incorrect password. Please try again.");
        return;
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Dashboard(email: email)),
      );
    } catch (e) {
      showErrorMessage("Login failed: $e");
    }
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
                              'Welcome back ',
                              style: TextStyle(color: Colors.white70),
                            ),
                            Text(
                              _user != null ? "${_user!.fname}!" : "Guest!",
                              style: const TextStyle(color: Colors.white70),
                            ),
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
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                              icon: Icon(
                                _isPasswordVisible
                                    ? CupertinoIcons.eye_fill
                                    : CupertinoIcons.eye_slash_fill,
                                color: whiteColor,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ForgotPasswordPage(),
                                  ),
                                );
                              },
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: whiteColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        MyButton(
                          textbutton: 'Login',
                          onTap: loginUser,
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
                            Text("Don't have an account? ",
                                style: TextStyle(color: whiteColor)),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignUpPage(
                                    email: '',
                                  ),
                                ),
                              ),
                              child: const Text(
                                'Sign Up',
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
