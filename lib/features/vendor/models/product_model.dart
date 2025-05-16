import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app/core/providers/user_provider.dart';

class Product {
  final String id;
  final String email;
  final String name;
  final String description;
  final String hsCode;
  final String hsProduct; // Added new field for HS product name
  final double minPrice;
  final double maxPrice;
  final String? priceUnit;
  final String? shippingTerm;
  final String? countryOfOrigin;
  final String? paymentTerms;
  final String? dispatchPort;
  final String? transitTime;
  final String? videoUrl;
  final List<String>? imageUrls;
  final String? testReportUrl;
  final bool? buyerInspection;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final String verification;

  Product({
    required this.id,
    required this.email,
    required this.name,
    required this.description,
    required this.hsCode,
    required this.hsProduct, // Added to constructor
    required this.minPrice,
    required this.maxPrice,
    this.priceUnit,
    this.shippingTerm,
    this.countryOfOrigin,
    this.paymentTerms,
    this.dispatchPort,
    this.transitTime,
    this.videoUrl,
    this.imageUrls,
    this.testReportUrl,
    this.buyerInspection,
    required this.createdAt,
    required this.updatedAt,
    required this.verification,
  });

  // Helper method to format HS code and product together
  String getHsCodeWithProduct() {
    return '$hsCode-$hsProduct';
  }

  // Create Product from Firestore document
  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Product(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      hsCode: data['hsCode'] ?? '',
      hsProduct: data['hsProduct'] ?? '', // Added to fetch from Firestore
      minPrice: (data['minPrice'] ?? 0).toDouble(),
      maxPrice: (data['maxPrice'] ?? 0).toDouble(),
      priceUnit: data['priceUnit'],
      shippingTerm: data['shippingTerm'],
      countryOfOrigin: data['countryOfOrigin'],
      paymentTerms: data['paymentTerms'],
      dispatchPort: data['dispatchPort'],
      transitTime: data['transitTime'],
      videoUrl: data['videoUrl'],
      imageUrls: data['imageUrls'] != null ? List<String>.from(data['imageUrls']) : null,
      testReportUrl: data['testReportUrl'],
      buyerInspection: data['buyerInspection'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
      verification: data['verification'],
    );
  }

  // Convert Product to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'description': description,
      'hsCode': hsCode,
      'hsProduct': hsProduct, // Added to save to Firestore
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'priceUnit': priceUnit,
      'shippingTerm': shippingTerm,
      'countryOfOrigin': countryOfOrigin,
      'paymentTerms': paymentTerms,
      'dispatchPort': dispatchPort,
      'transitTime': transitTime,
      'videoUrl': videoUrl,
      'imageUrls': imageUrls,
      'testReportUrl': testReportUrl,
      'buyerInspection': buyerInspection,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'verification': verification,
    };
  }

  // Create a copy of the Product with updated fields
  Product copyWith({
    String? id,
    String? email,
    String? name,
    String? description,
    String? hsCode,
    String? hsProduct, // Added to copyWith
    double? minPrice,
    double? maxPrice,
    String? priceUnit,
    String? shippingTerm,
    String? countryOfOrigin,
    String? paymentTerms,
    String? dispatchPort,
    String? transitTime,
    String? videoUrl,
    List<String>? imageUrls,
    String? testReportUrl,
    bool? buyerInspection,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    String? verification,
  }) {
    return Product(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      description: description ?? this.description,
      hsCode: hsCode ?? this.hsCode,
      hsProduct: hsProduct ?? this.hsProduct, // Added to copyWith return
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      priceUnit: priceUnit ?? this.priceUnit,
      shippingTerm: shippingTerm ?? this.shippingTerm,
      countryOfOrigin: countryOfOrigin ?? this.countryOfOrigin,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      dispatchPort: dispatchPort ?? this.dispatchPort,
      transitTime: transitTime ?? this.transitTime,
      videoUrl: videoUrl ?? this.videoUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      testReportUrl: testReportUrl ?? this.testReportUrl,
      buyerInspection: buyerInspection ?? this.buyerInspection,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      verification: verification ?? this.verification,
    );
  }
}