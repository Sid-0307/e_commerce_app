class UserModel {
  final String uid;
  final String email;
  final String name;
  final String phoneNumber;
  final String countryCode;  // Added separate country code field
  final String countryISOCode;
  final String userType;
  final String? address;
  final String? aboutUs;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.userType,
    this.phoneNumber = '',
    this.countryCode = '+91',  // Default to India country code
    this.countryISOCode = 'IN',
    this.address = '',
    this.aboutUs = '',
  });

  UserModel copyWith({
    String? name,
    String? email,
    String? phoneNumber,
    String? countryCode,  // Added to copyWith
    String? countryISOCode,
    String? userType,
    String? address,
    String? aboutUs,
  }) {
    return UserModel(
      uid: this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      userType: userType ?? this.userType,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      countryCode: countryCode ?? this.countryCode,  // Added to constructor
      countryISOCode: countryISOCode ?? this.countryISOCode,
      address: address ?? this.address,
      aboutUs: aboutUs ?? this.aboutUs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'userType': userType,
      'phoneNumber': phoneNumber,
      'countryCode': countryCode,  // Added to map
      'countryISOCode':countryISOCode,
      'address': address,
      'aboutUs': aboutUs,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      userType: map['userType'] ?? 'Buyer',  // Default to 'Buyer' to match dropdown
      phoneNumber: map['phoneNumber'] ?? '',
      countryCode: map['countryCode'] ?? '+91',  // Added with default
      countryISOCode:map['countryISOCode'] ?? 'IN',
      address: map['address'] ?? '',
      aboutUs: map['aboutUs'] ?? '',
    );
  }

  // Helper method to get complete phone number with country code
  String get completePhoneNumber => '$countryCode$phoneNumber';
}