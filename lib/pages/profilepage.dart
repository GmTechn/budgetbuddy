import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- added Firestore import
import 'package:expenses_tracker/components/mybutton.dart';
import 'package:expenses_tracker/components/mynavbar.dart';
import 'package:expenses_tracker/components/mytextfield.dart';
import 'package:expenses_tracker/management/databasemanager.dart';
import 'package:expenses_tracker/management/sessionmanager.dart';
import 'package:expenses_tracker/models/usermodel.dart';
import 'package:expenses_tracker/pages/loginpage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  final String email;
  const ProfilePage({super.key, required this.email});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _fnameController = TextEditingController();
  final _lnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  File? _imageFile;
  String? _photoPath;
  AppUser? _user;

  final _picker = ImagePicker();
  final DatabaseManager _databaseManager = DatabaseManager();
  bool _isLoading = false;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // <-- Firestore instance

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fnameController.dispose();
    _lnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    await _databaseManager.initialisation();
    AppUser? user = await _databaseManager.getUserByEmail(widget.email);

    if (!mounted) return;

    if (user != null) {
      _user = user;
      _fnameController.text = user.fname ?? '';
      _lnameController.text = user.lname ?? '';
      _emailController.text = user.email ?? widget.email;
      _phoneController.text = user.phone ?? '';
      if (user.photoPath != null && user.photoPath!.isNotEmpty) {
        final f = File(user.photoPath!);
        if (f.existsSync()) {
          _imageFile = f;
          _photoPath = user.photoPath;
        }
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 70);
      if (picked != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = path.basename(picked.path);
        final savedImage =
            await File(picked.path).copy('${appDir.path}/$fileName');

        setState(() {
          _imageFile = savedImage;
          _photoPath = savedImage.path;
        });

        if (_user != null) {
          final updated = _user!.copyWith(photoPath: _photoPath);
          await _databaseManager.upsertAppUser(updated);

          // <-- Update Firestore immediately when picking profile photo
          await _firestore.collection('users').doc(_user!.id.toString()).set({
            'photoPath': _photoPath,
          }, SetOptions(merge: true)); // merge pour créer si non existant

          _user = updated;
        }
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image')),
        );
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(CupertinoIcons.photo_camera_solid),
              title: const Text('Camera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.photo),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFullImage() {
    if (_imageFile == null) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: Image.file(_imageFile!),
        ),
      ),
    );
  }

  /// <-- UPDATED: Now saves to BOTH local DB and Firestore
  Future<void> _updateProfile() async {
    if (_user == null) return;

    setState(() => _isLoading = true); // show spinner

    final updated = AppUser(
      id: _user!.id,
      fname: _fnameController.text.trim(),
      lname: _lnameController.text.trim(),
      email: _emailController.text.trim(),
      password: _user!.password,
      phone: _phoneController.text.trim(),
      photoPath: _photoPath ?? '',
    );

    try {
      // 1️⃣ Update local database
      await _databaseManager.upsertAppUser(updated);

      // 2️⃣ Update Firestore (convert id to String)
      // 2️⃣ Update Firestore (create if not exists)
      await _firestore.collection('users').doc(_user!.id.toString()).set(
          {
            'fname': updated.fname,
            'lname': updated.lname,
            'email': updated.email,
            'phone': updated.phone,
            'photoPath': updated.photoPath ?? '',
          },
          SetOptions(
              merge: true)); // merge true pour ne pas écraser les autres champs

      _user = updated;
      await _loadProfile(); // reload the updated data

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xff181a1e),
            title: const Text(
              'Success',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'Your changes have been saved.',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Update failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false); // hide spinner
    }
  }

  Future<void> _confirmCancel() async {
    final doCancel = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Color(0xff181a1e),
        title: const Text(
          'Discard changes?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to discard your edits?',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'No',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Yes',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (doCancel == true) await _loadProfile();
  }

  Future<void> _logout() async {
    try {
      if (_user != null && _user!.fname != null && _user!.fname!.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('lastUserFname', _user!.fname!);
        await prefs.setString('lastUserEmail', _user!.email);
      }

      await SessionManager.clearCurrentUser();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint("Logout error: $e");
    }

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final lastEmail = prefs.getString('lastUserEmail') ?? '';

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginPage(email: lastEmail)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff181a1e),
      appBar: AppBar(
        backgroundColor: const Color(0xff181a1e),
        automaticallyImplyLeading: false,
        title: const Text(
          'P R O F I L E',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.power, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xff181a1e)))
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: IntrinsicHeight(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Stack(
                                  children: [
                                    GestureDetector(
                                      onTap: _showFullImage,
                                      child: CircleAvatar(
                                        radius: 60,
                                        backgroundColor: Colors.grey.shade300,
                                        backgroundImage: _imageFile != null
                                            ? FileImage(_imageFile!)
                                            : null,
                                        child: _imageFile == null
                                            ? const Icon(
                                                CupertinoIcons
                                                    .person_crop_circle_fill,
                                                size: 80,
                                                color: Colors.white)
                                            : null,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: _showImagePickerOptions,
                                        child: const CircleAvatar(
                                          radius: 20,
                                          backgroundColor: Colors.white,
                                          child: Icon(
                                              CupertinoIcons.camera_fill,
                                              color: Color(0xff181a1e)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 80),
                                MyTextFormField(
                                  controller: _fnameController,
                                  hintText: 'First Name',
                                  obscureText: false,
                                  leadingIcon:
                                      const Icon(CupertinoIcons.person_fill),
                                ),
                                const SizedBox(height: 20),
                                MyTextFormField(
                                  controller: _lnameController,
                                  hintText: 'Last Name',
                                  obscureText: false,
                                  leadingIcon:
                                      const Icon(CupertinoIcons.person_fill),
                                ),
                                const SizedBox(height: 20),
                                MyTextFormField(
                                  controller: _emailController,
                                  hintText: 'Email',
                                  obscureText: false,
                                  leadingIcon:
                                      const Icon(CupertinoIcons.mail_solid),
                                ),
                                const SizedBox(height: 20),
                                MyTextFormField(
                                  controller: _phoneController,
                                  hintText: 'Phone Number',
                                  obscureText: false,
                                  leadingIcon:
                                      const Icon(CupertinoIcons.phone_fill),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                ),
                                const SizedBox(height: 40),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    MyButton(
                                      textbutton: 'Update',
                                      onTap: _updateProfile,
                                      buttonHeight: 40,
                                      buttonWidth: 100,
                                    ),
                                    const SizedBox(width: 40),
                                    MyButton(
                                      textbutton: 'Cancel',
                                      onTap: _confirmCancel,
                                      buttonHeight: 40,
                                      buttonWidth: 100,
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
            ),
      bottomNavigationBar: MyNavBar(currentIndex: 3, email: widget.email),
    );
  }
}
