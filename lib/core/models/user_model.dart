import 'package:cloud_firestore/cloud_firestore.dart';

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
  final bool isPremium;
  final String? premiumTransactionId;
  final Timestamp? premiumPurchaseDate;

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
    this.isPremium = false,
    this.premiumTransactionId='',
    this.premiumPurchaseDate,
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
    bool? isPremium,
    String? premiumTransactionId,
    Timestamp? premiumPurchaseDate,
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
      isPremium: isPremium ?? this.isPremium,
      premiumTransactionId: premiumTransactionId ?? this.premiumTransactionId,
      premiumPurchaseDate: premiumPurchaseDate ?? this.premiumPurchaseDate,
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
      'isPremium':isPremium,
      "premiumTransactionId":premiumTransactionId,
      "premiumPurchaseDate":premiumPurchaseDate,
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
      isPremium:map['isPremium']??false,
      premiumTransactionId:map["premiumTransactionId"]??'',
      premiumPurchaseDate:map["premiumPurchaseDate"]??null,
    );
  }

  // Helper method to get complete phone number with country code
  String get completePhoneNumber => '$countryCode$phoneNumber';
}