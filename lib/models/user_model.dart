class UserModel {
  final int? id;
  final String name;
  final String emailOrPhone;
  final String passwordHash;
  final String? photo;
  final String? asal;
  UserModel({
    this.id,
    required this.name,
    required this.emailOrPhone,
    required this.passwordHash,
    this.photo,
    this.asal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'emailOrPhone': emailOrPhone,
      'passwordHash': passwordHash,
      'photo': photo,
      'asal': asal,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      emailOrPhone: map['emailOrPhone'] as String,
      passwordHash: map['passwordHash'] as String,
      photo: map['photo'] as String?,
      asal: map['asal'] as String?,
    );
  }
}
