class UserModel {
  final String uid;
  final String email;
  final String name;
  final String phoneNumber;
  final String userType;  // Added userType field
  final String? address;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.userType,  // Required parameter
    this.phoneNumber = '',
    this.address = ''
  });

  UserModel copyWith({
    String? name,
    String? email,
    String? phoneNumber,
    String? userType,
    String? address,
  }) {
    return UserModel(
      uid: this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      userType: userType ?? this.userType,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'userType': userType,
      'phoneNumber': phoneNumber,
      'address': address,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      userType: map['userType'] ?? 'buyer',  // Default to 'buyer' if not specified
      phoneNumber: map['phoneNumber'] ?? '',
      address: map['address'] ?? '',
    );
  }
}