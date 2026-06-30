class UserModel {
  final int? id;
  final String name;
  final String emailOrPhone;
  final String passwordHash;

  UserModel({
    this.id,
    required this.name,
    required this.emailOrPhone,
    required this.passwordHash,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'emailOrPhone': emailOrPhone,
      'passwordHash': passwordHash,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      emailOrPhone: map['emailOrPhone'] as String,
      passwordHash: map['passwordHash'] as String,
    );
  }
}
