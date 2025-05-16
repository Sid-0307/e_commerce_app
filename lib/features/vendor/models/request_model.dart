import 'package:cloud_firestore/cloud_firestore.dart';

class Request {
  final String id;
  final String productId;
  final String productName;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final String quantity;
  final DateTime requestDate;
  final DateTime expiryDate;
  final String sellerId;
  final String sellerEmail;
  final bool isActive;
  final String status;
  final int sellerDaysRemaining;

  Request({
    required this.id,
    required this.productId,
    required this.productName,
    required this.buyerId,
    required this.buyerName,
    required this.buyerPhone,
    required this.quantity,
    required this.requestDate,
    required this.expiryDate,
    required this.sellerId,
    required this.sellerEmail,
    required this.isActive,
    required this.status,
    required this.sellerDaysRemaining,
  });

  factory Request.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Handle Timestamp conversions
    final Timestamp requestTimestamp = data['requestDate'] as Timestamp;
    final Timestamp expiryTimestamp = data['expiryDate'] as Timestamp;

    final requestDate = requestTimestamp.toDate();
    final expiryDate = expiryTimestamp.toDate();

    // Calculate days remaining
    final difference = expiryDate.difference(DateTime.now()).inDays;
    final daysRemaining = difference < 0 ? 0 : difference;

    return Request(
      id: doc.id,
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      buyerId: data['buyerId'] ?? '',
      buyerName: data['buyerName'] ?? '',
      buyerPhone: data['buyerPhone'] ?? '',
      quantity: data['quantity'] ?? '',
      requestDate: requestDate,
      expiryDate: expiryDate,
      sellerId: data['sellerId'] ?? '',
      sellerEmail: data['sellerEmail'] ?? '',
      isActive: data['isActive'] ?? false,
      status: data['status'] ?? 'Pending',
      sellerDaysRemaining: daysRemaining,
    );
  }
}