// lib/features/buyer/screens/product_detail_screen.dart
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/models/user_model.dart';
import '../../../core/widgets/custom_button.dart';
import '../../vendor/models/product_model.dart';
import '../services/notification_service.dart';
import '../widgets/pdf_viewer_tab.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final TextEditingController _quantityController = TextEditingController();
  bool _isLoading = false;
  UserModel? _currentUser;
  final _uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _ensureNotificationPermissions();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  // Ensure notification permissions are requested
  Future<void> _ensureNotificationPermissions() async {
    try {
      await NotificationService.initialize();
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  Future<void> _loadCurrentUser() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          _currentUser = UserModel.fromMap(
              userDoc.data() as Map<String, dynamic>, userId);
        });
      }
    }
  }

  Future<void> _openUrl(String? url) async {
    if (url != null && url.isNotEmpty) {
      final Uri uri = Uri.parse(url);
      try {
        // For PDF files, ensure they open in external application
        if (url.toLowerCase().endsWith('.pdf')) {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
        } else {
          // For other URLs, allow options for in-app or external viewing
          await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
          );
        }
      } catch (e) {
        // Show error dialog or snackbar for better user feedback
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open: $url\nError: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _openPdfPreview(BuildContext context, String url) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Download the PDF file
      final http.Response response = await http.get(Uri.parse(url));

      // Get temporary directory to store the PDF file
      final dir = await getTemporaryDirectory();
      final filename = url.split('/').last;
      final filePath = '${dir.path}/$filename';

      // Write PDF bytes to file
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      // Navigate to PDF viewer page
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PDFViewerPage(
              pdfPath: filePath,
              pdfUrl: url,
              pdfTitle: 'Product Test Report',
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (context.mounted) Navigator.pop(context);

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> checkHealth() async {
    User? user = FirebaseAuth.instance.currentUser;
    print("User irukanda ${user?.email}");

    if (user == null) {
      UserCredential userCredential = await FirebaseAuth.instance.signInAnonymously();
      user = userCredential.user;
      await user?.getIdToken(true);
    }else{
      await user.getIdToken(true);
    }

    // Now call the function after the user is definitely signed in
    final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('checkHealth');
    final result = await callable.call();
    print("checkHealth? ${result.data}");
  }

  // Send request to seller
  Future<void> _sendRequestToSeller(String quantity) async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to be logged in to send a request'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if user already has an active request for this product
      final existingRequests = await FirebaseFirestore.instance
          .collection('requests')
          .where('productId', isEqualTo: widget.product.id)
          .where('buyerId', isEqualTo: _currentUser!.uid)
          .where('isActive', isEqualTo: true)
          .get();

      if (existingRequests.docs.isNotEmpty) {
        // Find if any request is still valid (not expired)
        final now = DateTime.now();
        bool hasActiveRequest = false;

        for (final doc in existingRequests.docs) {
          final expiryTimestamp = doc.data()['expiryDate'] as Timestamp;
          final expiryDate = expiryTimestamp.toDate();

          if (expiryDate.isAfter(now)) {
            hasActiveRequest = true;
            break;
          }
        }

        if (hasActiveRequest) {
          // Show SweetAlert-like dialog for duplicate request
          if (context.mounted) {
            await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  title: Column(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 60,
                      ),
                      SizedBox(height: 10),
                      Text('Request Already Exists'),
                    ],
                  ),
                  content: Text(
                    'You already have an active request for this product. Please wait until it expires before sending a new request.',
                    textAlign: TextAlign.center,
                  ),
                  actionsAlignment: MainAxisAlignment.center,
                  actions: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('OK', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                );
              },
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // Get seller data
      final sellerDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: widget.product.email)
          .get();

      String? sellerId;
      String sellerName = "Seller"; // Default name

      if (sellerDoc.docs.isNotEmpty) {
        sellerId = sellerDoc.docs.first.id;
        sellerName = sellerDoc.docs.first.data()['name'] ?? "Seller";
        debugPrint("Seller found: ID=$sellerId, Name=$sellerName");
      } else {
        debugPrint("Seller not found with email: ${widget.product.email}");
      }

      // Create a unique request ID
      final requestId = _uuid.v4();

      // Create request data
      final timestamp = Timestamp.now();
      final expiryDate = Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 10))
      );

      final requestData = {
        "requestId": requestId,
        'productId': widget.product.id,
        'productName': widget.product.name,
        'buyerId': _currentUser!.uid,
        'buyerName': _currentUser!.name,
        'buyerPhone': _currentUser!.completePhoneNumber,
        'sellerId': sellerId,
        'sellerEmail': widget.product.email,
        'quantity': quantity,
        'requestDate': timestamp,
        'expiryDate': expiryDate,
        'status': 'Awaiting Seller Contact',
        'isActive': true,
      };

      debugPrint("Creating request with data: $requestData");

      // Add to Firestore - both in requests collection and in user-specific subcollections
      final requestRef = await FirebaseFirestore.instance
          .collection('requests')
          .add(requestData);

      // Add reference to buyer's requests
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('buyerRequests')
          .doc(requestRef.id)
          .set({
        ...requestData,
        'requestId': requestRef.id,
      });

      // Add reference to seller's requests if seller exists
      if (sellerId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(sellerId)
            .collection('sellerRequests')
            .doc(requestRef.id)
            .set({
          ...requestData,
          'requestId': requestRef.id,
          'sellerExpiryDate': Timestamp.fromDate(
              DateTime.now().add(const Duration(days: 3))
          ),
        });
        debugPrint("Added request to seller's collection");
      }

      // Show SweetAlert-like dialog for successful request
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              titlePadding: EdgeInsets.fromLTRB(24, 24, 24, 0),
              contentPadding: EdgeInsets.fromLTRB(24, 10, 24, 0),
              actionsPadding: EdgeInsets.only(bottom: 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 60,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Request Sent Successfully!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              content: Text(
                'The seller will contact you soon',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Great!',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      }
      _quantityController.clear();
    } catch (e) {
      debugPrint("Error in _sendRequestToSeller: $e");

      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  SizedBox(height: 10),
                  Text('Request Failed'),
                ],
              ),
              content: Text(
                'Failed to send request: ${e.toString()}',
                textAlign: TextAlign.center,
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product Details'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Images
            _buildImageGallery(),

            // Product Information
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  Text(
                    widget.product.name,
                    style: AppTextStyles.heading1,
                  ),
                  const SizedBox(height: 8),

                  // Price
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '\$${widget.product.minPrice} - \$${widget.product.maxPrice} ${widget.product.priceUnit ?? ''}',
                          style: AppTextStyles.subtitle.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'Description',
                    style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description,
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: 24),

                  // Specifications
                  Text(
                    'Specifications',
                    style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildSpecificationItem('Country of Origin', widget.product.countryOfOrigin),
                  _buildSpecificationItem('Shipping Terms', widget.product.shippingTerm),
                  _buildSpecificationItem('Payment Terms', widget.product.paymentTerms),
                  _buildSpecificationItem('Dispatch Port', widget.product.dispatchPort),
                  _buildSpecificationItem('Transit Time', widget.product.transitTime),
                  _buildSpecificationItem('Buyer Inspection', widget.product.buyerInspection != null && widget.product.buyerInspection! ? 'Available' : 'Not Available'),
                  const SizedBox(height: 16),

                  // Test Report
                  if (widget.product.testReportUrl != null && widget.product.testReportUrl!.isNotEmpty)
                    InkWell(
                      onTap: () => _openPdfPreview(context, widget.product.testReportUrl!),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.picture_as_pdf,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Product Test Report',
                                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    'Tap to preview document',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.visibility,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Video
                  if (widget.product.videoUrl != null && widget.product.videoUrl!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Product Video',
                          style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _openUrl(widget.product.videoUrl),
                          child: Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.play_circle_filled,
                                color: Colors.white,
                                size: 64,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),

                  // Contact Supplier Button
                  CustomButton(
                    text: _isLoading ? 'Sending...' : 'Contact Supplier',
                    onPressed: _isLoading
                        ? (){}
                        : () {
                      // Show quantity input dialog
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Contact Supplier'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Interested in "${widget.product.name}"?'),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _quantityController,
                                decoration: const InputDecoration(
                                  labelText: 'Quantity Required',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                final quantity = _quantityController.text.trim();
                                if (quantity.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter a quantity'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                Navigator.pop(context);
                                _sendRequestToSeller(quantity);
                                // checkHealth();
                              },
                              child: const Text('Send Request'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery() {
    if (widget.product.imageUrls == null || widget.product.imageUrls!.isEmpty) {
      return Container(
        height: 250,
        color: AppColors.border,
        child: Center(
          child: Icon(
            Icons.image,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: PageView.builder(
        itemCount: widget.product.imageUrls!.length,
        itemBuilder: (context, index) {
          return Image.network(
            widget.product.imageUrls![index],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: AppColors.border,
              child: Center(
                child: Icon(
                  Icons.image_not_supported,
                  size: 64,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpecificationItem(String title, String? value) {
    if (value == null || value.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              title,
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }
}