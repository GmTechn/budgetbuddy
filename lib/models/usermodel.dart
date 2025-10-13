class AppUser {
  final int? id;
  final String fname;
  final String lname;
  final String email;
  final String password;
  final String phone;
  final String photoPath;

  AppUser({
    this.id,
    this.fname = '',
    this.lname = '',
    required this.email,
    this.password = '',
    this.phone = '',
    this.photoPath = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id, // tu peux aussi choisir de ne pas inclure si null
      'fname': fname,
      'lname': lname,
      'email': email,
      'password': password,
      'phone': phone,
      'photoPath': photoPath,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'],
      fname: map['fname'] ?? '',
      lname: map['lname'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      phone: map['phone'] ?? '',
      photoPath: map['photoPath'] ?? '',
    );
  }
  AppUser copyWith({
    int? id,
    String? fname,
    String? lname,
    String? email,
    String? password,
    String? phone,
    String? photoPath,
  }) {
    return AppUser(
      id: id ?? this.id,
      fname: fname ?? this.fname,
      lname: lname ?? this.lname,
      email: email ?? this.email,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      photoPath: photoPath ?? this.photoPath,
    );
  }
}
