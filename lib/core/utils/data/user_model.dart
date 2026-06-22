class UserModel {
  final String username;
  final String email;
  final String sn;
  final String idSite;
  final String position;
  final int age;
  final String createdAt;
  final String image;

  UserModel({
    required this.username,
    required this.email,
    required this.sn,
    required this.idSite,
    required this.position,
    required this.age,
    required this.createdAt,
    required this.image,
  });

  @override
  String toString() {
    return '''
UserModel(
  username: $username,
  email: $email,
  sn: $sn,
  idSite: $idSite,
  position: $position,
  age: $age,
  createdAt: $createdAt,
  image: $image
)''';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      sn: json['sn'] ?? '',
      idSite: json['id_site'] ?? '',
      position: json['position'] ?? '',
      age: json['age'] ?? 0,
      createdAt: json['created_at'] ?? '',
      image: json['image'] ?? '',
    );
  }
}
