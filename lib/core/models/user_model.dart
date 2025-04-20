class UserModel {
  final String uid;
  final String email;
  final String name;
  final String phoneNumber;
  // final String? profileImageUrl;
  final String? address;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.phoneNumber = '',
    this.address = ''
    // this.profileImageUrl,
  });

  UserModel copyWith({
    String? name,
    String? email,
    String? phoneNumber,
    String? address,
    // String? profileImageUrl,
  }) {
    return UserModel(
      uid: this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      // profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'address': address,
      // 'profileImageUrl': profileImageUrl,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      address: map['address'] ?? '',
      // profileImageUrl: map['profileImageUrl'],
    );
  }
}