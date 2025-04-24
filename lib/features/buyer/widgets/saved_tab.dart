// // lib/features/buyer/tabs/saved_tab.dart
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:provider/provider.dart';
// import '../../../core/constants/colors.dart';
// import '../../../core/constants/text_styles.dart';
// import '../../../core/providers/user_provider.dart';
// import '../../vendor/models/product_model.dart';
// import '../screens/product_detail_screen.dart';
//
// class SavedProductsTab extends StatelessWidget {
//   const SavedProductsTab({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final userProvider = Provider.of<UserProvider>(context);
//     final user = userProvider.currentUser;
//
//     return Padding(
//         padding: const EdgeInsets.all(16.0),
//     child: Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//     Text(
//     'Saved Products',
//     style: AppTextStyles.heading1,
//     ),
//     const SizedBox(height: 16),
//     Expanded(
//     child: StreamBuilder<QuerySnapshot>(
//     stream: FirebaseFirestore.instance
//     .collection('users')
//         .doc(user?.uid)
//         .collection('savedProducts')
//         .snapshots(),
//     builder: (context, snapshot) {
//     // Show loading indicator while waiting
//       // lib/features/buyer/tabs/saved_tab.dart (continued)
//       if (snapshot.connectionState == ConnectionState.waiting) {
//         return const Center(child: CircularProgressIndicator());
//       }
//
//       // Handle errors
//       if (snapshot.hasError) {
//         return Center(
//           child: Text(
//             'Error loading saved products: ${snapshot.error}',
//             style: AppTextStyles.body,
//             textAlign: TextAlign.center,
//           ),
//         );
//       }
//
//       // No saved products
//       if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//         return _buildEmptyState();
//       }
//
//       // Get product IDs from saved collection
//       List<String> savedProductIds = snapshot.data!.docs
//           .map((doc) => doc.id)
//           .toList();
//
//       // Fetch the actual products
//       return StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('products')
//             .where(FieldPath.documentId, whereIn: savedProductIds)
//             .snapshots(),
//         builder: (context, productSnapshot) {
//           if (productSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           if (productSnapshot.hasError) {
//             return Center(
//               child: Text(
//                 'Error loading product details: ${productSnapshot.error}',
//                 style: AppTextStyles.body,
//                 textAlign: TextAlign.center,
//               ),
//             );
//           }
//
//           if (!productSnapshot.hasData || productSnapshot.data!.docs.isEmpty) {
//             return _buildEmptyState();
//           }
//
//           // Convert to product objects
//           List<Product> products = productSnapshot.data!.docs
//               .map((doc) => Product.fromFirestore(doc))
//               .toList();
//
//           // Display products
//           return ListView.builder(
//             itemCount: products.length,
//             itemBuilder: (context, index) {
//               final product = products[index];
//               return _buildSavedProductCard(context, product, user?.uid ?? '');
//             },
//           );
//         },
//       );
//     },
//     ),
//     ),
//     ],
//     ),
//     );
//   }
//
//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.bookmark_outline,
//             size: 80,
//             color: AppColors.textSecondary.withOpacity(0.5),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'No saved products yet',
//             style: AppTextStyles.subtitle,
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Products you save will appear here',
//             style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSavedProductCard(BuildContext context, Product product, String userId) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => ProductDetailScreen(product: product),
//           ),
//         );
//       },
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 5,
//               spreadRadius: 1,
//             ),
//           ],
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(12.0),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Product Image
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(8),
//                 child: product.imageUrls != null && product.imageUrls!.isNotEmpty
//                     ? Image.network(
//                   product.imageUrls![0],
//                   width: 115,
//                   height: 115,
//                   fit: BoxFit.cover,
//                   errorBuilder: (context, error, stackTrace) => Container(
//                     width: 115,
//                     height: 115,
//                     color: AppColors.border,
//                     child: const Icon(Icons.image_not_supported, color: AppColors.textSecondary),
//                   ),
//                 )
//                     : Container(
//                   width: 115,
//                   height: 115,
//                   color: AppColors.border,
//                   child: const Icon(Icons.image, color: AppColors.textSecondary),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               // Product details
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       product.name,
//                       style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       product.description,
//                       style: AppTextStyles.body,
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                           decoration: BoxDecoration(
//                             color: AppColors.primary.withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(4),
//                           ),
//                           child: Text(
//                             '\$${product.minPrice} - \$${product.maxPrice} ${product.priceUnit}',
//                             style: AppTextStyles.caption.copyWith(
//                               color: AppColors.primary,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       '• ${product.shippingTerm} • ${product.countryOfOrigin}',
//                       style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ],
//                 ),
//               ),
//               // Remove from saved icon
//               GestureDetector(
//                 onTap: () async {
//                   try {
//                     await FirebaseFirestore.instance
//                         .collection('users')
//                         .doc(userId)
//                         .collection('savedProducts')
//                         .doc(product.id)
//                         .delete();
//
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text('Product removed from saved')),
//                     );
//                   } catch (e) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text('Error removing product: $e')),
//                     );
//                   }
//                 },
//                 child: Container(
//                   height: 30,
//                   width: 30,
//                   decoration: BoxDecoration(
//                     color: Colors.red.shade50,
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(
//                     Icons.bookmark,
//                     size: 16,
//                     color: Colors.red,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// // lib/features/buyer/tabs/messages_tab.dart
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:provider/provider.dart';
// import '../../../core/constants/colors.dart';
// import '../../../core/constants/text_styles.dart';
// import '../../../core/providers/user_provider.dart';
// import '../screens/chat_screen.dart';
//
// class BuyerMessagesTab extends StatelessWidget {
//   const BuyerMessagesTab({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final userProvider = Provider.of<UserProvider>(context);
//     final currentUser = userProvider.currentUser;
//
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Messages',
//             style: AppTextStyles.heading1,
//           ),
//           const SizedBox(height: 16),
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection('chats')
//                   .where('participants', arrayContains: currentUser?.email)
//                   .orderBy('lastMessageTime', descending: true)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//
//                 if (snapshot.hasError) {
//                   return Center(
//                     child: Text(
//                       'Error loading messages: ${snapshot.error}',
//                       style: AppTextStyles.body,
//                       textAlign: TextAlign.center,
//                     ),
//                   );
//                 }
//
//                 if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                   return _buildEmptyState();
//                 }
//
//                 return ListView.builder(
//                   itemCount: snapshot.data!.docs.length,
//                   itemBuilder: (context, index) {
//                     final chatDoc = snapshot.data!.docs[index];
//                     final chatData = chatDoc.data() as Map<String, dynamic>;
//
//                     final List<dynamic> participants = chatData['participants'] ?? [];
//                     final String otherUserEmail = participants.firstWhere(
//                             (email) => email != currentUser?.email,
//                         orElse: () => 'Unknown'
//                     );
//
//                     return _buildChatItem(
//                       context,
//                       chatDoc.id,
//                       otherUserEmail,
//                       chatData['lastMessage'] ?? '',
//                       chatData['lastMessageTime'] != null
//                           ? (chatData['lastMessageTime'] as Timestamp).toDate()
//                           : DateTime.now(),
//                       chatData['unreadCount'] ?? 0,
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.message_outlined,
//             size: 80,
//             color: AppColors.textSecondary.withOpacity(0.5),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'No messages yet',
//             style: AppTextStyles.subtitle,
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Messages from vendors will appear here',
//             style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildChatItem(
//       BuildContext context,
//       String chatId,
//       String otherUserEmail,
//       String lastMessage,
//       DateTime timestamp,
//       int unreadCount
//       ) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => ChatScreen(
//               chatId: chatId,
//               recipientEmail: otherUserEmail,
//             ),
//           ),
//         );
//       },
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 8),
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         decoration: BoxDecoration(
//           color: unreadCount > 0 ? AppColors.primary.withOpacity(0.05) : Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 5,
//               spreadRadius: 1,
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             CircleAvatar(
//               radius: 24,
//               backgroundColor: AppColors.secondary.withOpacity(0.2),
//               child: Text(
//                 otherUserEmail.substring(0, 1).toUpperCase(),
//                 style: AppTextStyles.subtitle.copyWith(
//                   color: AppColors.secondary,
//                 ),
//               ),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         otherUserEmail,
//                         style: AppTextStyles.bodyLarge.copyWith(
//                           fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       Text(
//                         _formatTimestamp(timestamp),
//                         style: AppTextStyles.caption.copyWith(
//                           color: AppColors.textSecondary,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 4),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: Text(
//                           lastMessage,
//                           style: AppTextStyles.body.copyWith(
//                             color: unreadCount > 0
//                                 ? AppColors.textPrimary
//                                 : AppColors.textSecondary,
//                             fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                       if (unreadCount > 0)
//                         Container(
//                           padding: const EdgeInsets.all(6),
//                           decoration: BoxDecoration(
//                             color: AppColors.primary,
//                             shape: BoxShape.circle,
//                           ),
//                           child: Text(
//                             unreadCount.toString(),
//                             style: AppTextStyles.caption.copyWith(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   String _formatTimestamp(DateTime timestamp) {
//     final now = DateTime.now();
//     final difference = now.difference(timestamp);
//
//     if (difference.inDays > 7) {
//       // Format as MM/DD/YY
//       return '${timestamp.month}/${timestamp.day}/${timestamp.year.toString().substring(2)}';
//     } else if (difference.inDays > 0) {
//       // Show day of week
//       List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
//       return days[timestamp.weekday - 1];
//     } else {
//       // Show time
//       String hour = timestamp.hour > 12
//           ? (timestamp.hour - 12).toString()
//           : timestamp.hour == 0 ? '12' : timestamp.hour.toString();
//       String minute = timestamp.minute.toString().padLeft(2, '0');
//       String period = timestamp.hour >= 12 ? 'PM' : 'AM';
//
//       return '$hour:$minute $period';
//     }
//   }
// }