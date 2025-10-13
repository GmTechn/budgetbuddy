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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:math';

class SignUpPage extends StatefulWidget {
  final String email;
  const SignUpPage({super.key, required this.email});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  //controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;

  //google and  sign in
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final DatabaseManager _dbManager = DatabaseManager();

  @override
  void initState() {
    super.initState();
    _dbManager.initialisation();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  //local sing in

  Future<void> registerUser() async {
    //local sign in with email and password
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

    // Save to local DB first
    await _dbManager.insertAppUser(newUser);
    await SessionManager.saveCurrentUser(newUser.email);

    // Check internet
    final connectivity = await Connectivity().checkConnectivity();
    final isOnline = connectivity != ConnectivityResult.none;

    if (isOnline) {
      //Cloud sign in
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
            .createUserWithEmailAndPassword(email: email, password: password);
        final firestore = FirebaseFirestore.instance;
        await firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': email,
          'fname': '',
          'lname': '',
          'phone': '',
          'photoPath': '',
        }, SetOptions(merge: true));
      } catch (e) {
        //pop the progressin
        Navigator.pop(context);
        debugPrint("Firebase signup failed: $e");
        showMessage(
            "Signed up locally, but Firebase registration failed. Try again later.");
      }
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ProfilePage(email: newUser.email)),
    );
  }

  Future<void> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return;

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

      try {
        final googleAuth = await account.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
        final firestore = FirebaseFirestore.instance;
        final docRef =
            firestore.collection('users').doc(userCredential.user!.uid);
        if (!(await docRef.get()).exists) {
          await docRef.set({
            'uid': userCredential.user!.uid,
            'email': userCredential.user!.email,
          }, SetOptions(merge: true));
        }
      } catch (e) {
        debugPrint("Firebase Google Sign-In failed: $e");
        showMessage(
            "Signed up locally with Google, but Firebase failed. Try again later.");
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ProfilePage(email: account.email)),
      );
    } catch (e) {
      showMessage('Google sign-in failed: $e');
    }
  }

  Future<void> _handleAppleSignIn() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName
      ]);
      if (credential.email == null) {
        showMessage("Apple Sign-In returned null email.");
        return;
      }

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

      try {
        final oauthCredential = OAuthProvider("apple.com").credential(
          idToken: credential.identityToken,
          accessToken: credential.authorizationCode,
        );
        final userCredential =
            await FirebaseAuth.instance.signInWithCredential(oauthCredential);
        final firestore = FirebaseFirestore.instance;
        final docRef =
            firestore.collection('users').doc(userCredential.user!.uid);
        if (!(await docRef.get()).exists) {
          await docRef.set({
            'uid': userCredential.user!.uid,
            'email': userCredential.user!.email,
            'username': credential.givenName ?? 'User${Random().nextInt(9999)}',
          }, SetOptions(merge: true));
        }
      } catch (e) {
        debugPrint("Firebase Apple Sign-In failed: $e");
        showMessage(
            "Signed up locally with Apple, but Firebase failed. Try again later.");
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => ProfilePage(email: credential.email!)),
      );
    } catch (e) {
      showMessage('Apple Sign-In failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    Color whiteColor = Colors.white;

    return Scaffold(
      backgroundColor: const Color(0xff181a1e),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
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
                  color: whiteColor,
                ),
              ),
              const SizedBox(height: 20),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Create an account here!',
                    style: TextStyle(color: Colors.white70),
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
                leadingIcon:
                    const Icon(CupertinoIcons.lock_fill, color: Colors.white24),
                trailingIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? CupertinoIcons.eye_fill
                        : CupertinoIcons.eye_slash_fill,
                    color: Colors.white24,
                  ),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
              ),
              const SizedBox(height: 20),
              MyTextFormField(
                controller: confirmPasswordController,
                hintText: 'Confirm Password',
                obscureText: !_isPasswordVisible,
                leadingIcon:
                    const Icon(CupertinoIcons.lock_fill, color: Colors.white24),
                trailingIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? CupertinoIcons.eye_fill
                        : CupertinoIcons.eye_slash_fill,
                    color: Colors.white24,
                  ),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
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
                      child: Divider(thickness: .5, color: whiteColor),
                    ),
                    const SizedBox(width: 10),
                    Text('Or continue with',
                        style: TextStyle(color: whiteColor)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Divider(thickness: .5, color: whiteColor),
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
                  Text(
                    "Already have an account? ",
                    style: TextStyle(color: whiteColor),
                  ),
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
    );
  }
}
