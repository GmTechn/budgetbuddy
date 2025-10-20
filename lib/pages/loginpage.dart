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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  final String email;
  const LoginPage({super.key, required this.email});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  //controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  //boolean for password visibility
  bool _isPasswordVisible = false;

  //database manager
  final DatabaseManager _dbManager = DatabaseManager();

  AppUser? _user;
  String? _cachedEmail;

  @override
  void initState() {
    super.initState();
    _loadCachedUser();
  }

  /// Load last logged-in user email and fetch data
  Future<void> _loadCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedEmail = prefs.getString('lastUserEmail') ?? widget.email;
    final cachedName = prefs.getString('lastUserFname') ?? '';

    if (_cachedEmail != null && _cachedEmail!.isNotEmpty) {
      final user = await _dbManager.getUserByEmail(_cachedEmail!);
      if (mounted) {
        setState(() {
          _user = user ?? AppUser(email: _cachedEmail!, fname: cachedName);
        });
      }
    }
  }

  /// Save logged user email
  Future<void> _saveUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastEmail', email);
  }

  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xff181a1e),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  /// Hybrid login: check connectivity → use Firebase if online else local DB
  Future<void> loginUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showErrorMessage("Please fill all fields.");
      return;
    }

    final connectivity = await Connectivity().checkConnectivity();
    final isOnline = connectivity != ConnectivityResult.none;

    if (isOnline) {
      // Firebase login

      //show circular progression
      showDialog(
        context: context,
        builder: (context) {
          return const Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.white, // Background color of the track
              valueColor: const AlwaysStoppedAnimation<Color>(
                  Colors.green), // Color of the progress arc
              strokeWidth: 5.0,
            ),
          );
        },
      );
      try {
        final userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);

        await _saveUserEmail(userCredential.user!.email ?? email);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  Dashboard(email: userCredential.user!.email ?? email)),
        );
      } on FirebaseAuthException catch (e) {
        //pop the progressin
        Navigator.pop(context);
        showErrorMessage("Firebase login failed: ${e.message}");
      }
    } else {
      // Local DB login
      final localUser = await _dbManager.getUserByEmail(email);
      if (localUser == null) {
        showErrorMessage("No account found in local DB for this email.");
        return;
      }
      if (localUser.password != password) {
        showErrorMessage("Incorrect password for local DB login.");
        return;
      }

      await _saveUserEmail(email);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Dashboard(email: email)),
      );
    }
  }

  /// Google login (Firebase only)
  Future<void> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      await _saveUserEmail(userCredential.user!.email ?? '');

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => Dashboard(email: userCredential.user!.email ?? '')),
      );
    } catch (e) {
      showErrorMessage('Google sign-in failed: $e');
    }
  }

  /// Apple login (Firebase only)
  Future<void> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      await _saveUserEmail(userCredential.user!.email ?? '');

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => Dashboard(email: userCredential.user!.email ?? '')),
      );
    } catch (e) {
      showErrorMessage('Apple Sign-In failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff181a1e),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
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
                const SizedBox(height: 20),
                Text(
                  'B U D G E T  B U D D Y',
                  style: GoogleFonts.abel(
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                    color: Colors.white,
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
                      _user != null && _user!.fname.isNotEmpty
                          ? "${_user!.fname}!"
                          : "Guest!",
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
                  enabled: false,
                ),
                const SizedBox(height: 20),
                MyTextFormField(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: !_isPasswordVisible,
                  leadingIcon: const Icon(CupertinoIcons.lock_fill,
                      color: Colors.white24),
                  enabled: false,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        color: Colors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ForgotPasswordPage()),
                        );
                      },
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
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
                    children: const [
                      Expanded(child: Divider(color: Colors.white24)),
                      SizedBox(width: 10),
                      Text('Or continue with',
                          style: TextStyle(color: Colors.white)),
                      SizedBox(width: 10),
                      Expanded(child: Divider(color: Colors.white24)),
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
                      onTap: signInWithApple,
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? ",
                        style: TextStyle(color: Colors.white)),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SignUpPage(email: '')),
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                            color: Colors.blue, fontWeight: FontWeight.bold),
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
  }
}
