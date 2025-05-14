class UserModel {
  final String? id;
  String? firebase_id;
  String? rePassword;
  final String name;
  final String email;
  final String password;

  UserModel({
    this.id,
    this.firebase_id,
    this.rePassword,
    required this.name,
    required this.email,
    required this.password,
  });

  toJson() {
    return {
      "name": name,
      "email": email,
      "firebase_id": firebase_id,
      "password": password,
    };
  }
}
