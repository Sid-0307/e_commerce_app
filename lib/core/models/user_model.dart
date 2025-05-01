class UserModel {
  final String uid;
  final String email;
  final String name;
  final String phoneNumber;
  final String countryCode;
  final String countryISOCode;
  final String userType;
  final String? address;
  final String? aboutUs;
  final List<String> hsCodePreferences;  // List of HS code preferences

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.userType,
    this.phoneNumber = '',
    this.countryCode = '+91',
    this.countryISOCode = 'IN',
    this.address = '',
    this.aboutUs = '',
    this.hsCodePreferences = const [],  // Default empty list
  });

  UserModel copyWith({
    String? name,
    String? email,
    String? phoneNumber,
    String? countryCode,
    String? countryISOCode,
    String? userType,
    String? address,
    String? aboutUs,
    List<String>? hsCodePreferences,
  }) {
    return UserModel(
      uid: this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      userType: userType ?? this.userType,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      countryCode: countryCode ?? this.countryCode,
      countryISOCode: countryISOCode ?? this.countryISOCode,
      address: address ?? this.address,
      aboutUs: aboutUs ?? this.aboutUs,
      hsCodePreferences: hsCodePreferences ?? this.hsCodePreferences,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'userType': userType,
      'phoneNumber': phoneNumber,
      'countryCode': countryCode,
      'countryISOCode': countryISOCode,
      'address': address,
      'aboutUs': aboutUs,
      'hsCodePreferences': hsCodePreferences,  // List is directly serializable
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      userType: map['userType'] ?? 'Buyer',
      phoneNumber: map['phoneNumber'] ?? '',
      countryCode: map['countryCode'] ?? '+91',
      countryISOCode: map['countryISOCode'] ?? 'IN',
      address: map['address'] ?? '',
      aboutUs: map['aboutUs'] ?? '',
      hsCodePreferences: map['hsCodePreferences'] != null
          ? List<String>.from(map['hsCodePreferences'])
          : [],  // Convert to List<String> or provide empty list
    );
  }

  // Helper method to get complete phone number with country code
  String get completePhoneNumber => '$countryCode$phoneNumber';
}