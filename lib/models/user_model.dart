class UserModel {
  int id;
  String name;
  String email;
  String role;

  UserModel({required this.id, required this.name, required this.email, required this.role});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
    );
  }
}