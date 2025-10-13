import 'package:expenses_tracker/components/myappbar.dart';
import 'package:expenses_tracker/components/mybutton.dart';
import 'package:expenses_tracker/components/mytextfield.dart';
import 'package:expenses_tracker/management/databasemanager.dart';
import 'package:expenses_tracker/models/usermodel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ListOfUsers extends StatefulWidget {
  const ListOfUsers({super.key});

  @override
  State<ListOfUsers> createState() => _ListOfUsersState();
}

class _ListOfUsersState extends State<ListOfUsers> {
  final TextEditingController searchController = TextEditingController();

  // Users list
  List<AppUser> _users = [];

  //list of user to use for search bar
  List<AppUser> _filteredUsers = [];

  //calling the database

  final DatabaseManager _databaseManager = DatabaseManager();

//initialising the database
  @override
  void initState() {
    super.initState();
    _initDb();
  }

//loading users

  Future<void> _initDb() async {
    await _databaseManager.initialisation();
    _loadUsers();
  }

  ///gettinhg a user by the function get all users
  ///to filter for the seach function

  Future<void> _loadUsers() async {
    final users = await _databaseManager.getAllAppUsers();
    setState(() {
      _users = users.cast<AppUser>();
      _filteredUsers = users.cast<AppUser>();
    });
  }

  ///Search function that goes through the db
  ///by setting all chars to lower case
  ///so if you look for a person with the first letter of their
  ///name or email, you can get it

  void _searchUsers(String query) {
    final results = _users.where((user) {
      final fullName = '${user.fname} ${user.lname}'.toLowerCase();
      final email = (user.email ?? '').toLowerCase();
      return fullName.contains(query.toLowerCase()) ||
          email.contains(query.toLowerCase());
    }).toList();

    setState(() {
      _filteredUsers = results;
    });
  }

  ///Delete user from the database calling on the
  ///function "delete user" from the db

  Future<void> _deleteUser(AppUser user) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xff181a1e),
        title: const Text(
          "Delete this user?",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Are you sure you want to delete ${user.fname}?",
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirm == true && user.id != null) {
      await _databaseManager.deleteAppUser(user.id!);
      _loadUsers();
    }
  }

  /// Edit user by making use of the function
  /// Edit user from the database
  Future<void> _editUser(AppUser user) async {
    final newFname = TextEditingController(text: user.fname);
    final newLname = TextEditingController(text: user.lname);
    final newEmail = TextEditingController(text: user.email);
    final newPassword = TextEditingController(text: user.password);
    final newPhone = TextEditingController(text: user.phone);

    await showDialog(
      context: context,
      builder: (context) {
        bool isPasswordVisible = false;

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            backgroundColor: Color(0xff181a1e),
            title: const Text(
              textAlign: TextAlign.center,
              'Edit user info',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MyTextFormField(
                    controller: newFname,
                    hintText: 'First Name',
                    obscureText: false,
                    leadingIcon: const Icon(
                      CupertinoIcons.person_fill,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 10),
                  MyTextFormField(
                    controller: newLname,
                    hintText: 'Last Name',
                    obscureText: false,
                    leadingIcon: const Icon(
                      CupertinoIcons.person_fill,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 10),
                  MyTextFormField(
                    controller: newEmail,
                    hintText: 'Email',
                    obscureText: false,
                    leadingIcon: const Icon(
                      CupertinoIcons.mail_solid,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 10),
                  MyTextFormField(
                    controller: newPassword,
                    hintText: 'Password',
                    obscureText: !isPasswordVisible,
                    leadingIcon: const Icon(
                      CupertinoIcons.lock_fill,
                      color: Colors.white70,
                    ),
                    trailingIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible
                            ? CupertinoIcons.eye_fill
                            : CupertinoIcons.eye_slash_fill,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  MyTextFormField(
                    controller: newPhone,
                    hintText: 'Phone Number',
                    obscureText: false,
                    leadingIcon: const Icon(
                      CupertinoIcons.phone_fill,
                      color: Colors.white70,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final updatedUser = AppUser(
                        id: user.id,
                        fname: newFname.text,
                        lname: newLname.text,
                        email: newEmail.text,
                        password: newPassword.text,
                        phone: newPhone.text,
                        photoPath: user.photoPath,
                      );

                      await _databaseManager
                          .upsertAppUser(updatedUser as AppUser);

                      Navigator.pop(context);
                      _loadUsers();
                    },
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff181a1e),
      appBar: AppBar(
        backgroundColor: const Color(0xff181a1e),
        title: const Text(
          'Users',
          style: TextStyle(color: Colors.white),
        ),
        // Ici on peut juste changer la couleur du leading par défaut
        iconTheme: const IconThemeData(
          color: Colors.white, // ← couleur de l'icône "back"
        ),
        // Si tu veux explicitement un bouton retour personnalisé, tu peux le faire comme ça
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              style: TextStyle(color: Colors.white),
              cursorColor: Colors.white70,
              controller: searchController,
              onChanged: _searchUsers,
              decoration: InputDecoration(
                focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey, width: 1.5)),
                prefixIcon:
                    const Icon(CupertinoIcons.search, color: Colors.white),
                hintText: "Search users...",
                hintStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xff050c20))),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    elevation: 5,
                    color: Color(0xff181a1e),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white70, width: .5)),
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    child: ListTile(
                      title: Text(
                        '${user.fname} ${user.lname}',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        user.email ?? '',
                        style: TextStyle(color: Colors.white70),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                              onPressed: () => _deleteUser(user),
                              icon: const Icon(
                                CupertinoIcons.delete_solid,
                                color: Colors.white70,
                              )),
                          IconButton(
                              onPressed: () => _editUser(user),
                              icon: const Icon(
                                CupertinoIcons.pencil,
                                color: Colors.white70,
                              )),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            height: 50,
          ),
        ],
      ),
    );
  }
}
