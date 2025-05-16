import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../models/request_model.dart';

class RequestsTab extends StatefulWidget {
  const RequestsTab({Key? key}) : super(key: key);

  @override
  State<RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<RequestsTab> {
  bool _isLoading = false;
  List<Request> _requests = [];
  final ScrollController _scrollController = ScrollController();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      print("Loading requests for seller userId: $userId");

      if (userId == null) {
        setState(() {
          _errorMessage = "User not authenticated";
          _isLoading = false;
        });
        return;
      }

      // Use a try-catch block specifically for the Firestore query
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('requests')  // Use the main 'requests' collection
            .where('sellerId', isEqualTo: userId)  // Filter by current user as seller
            .orderBy('requestDate', descending: true)
            .get();

        print("Fetched ${snapshot.docs.length} requests");

        if (snapshot.docs.isEmpty) {
          setState(() {
            _requests = [];
            _isLoading = false;
          });
          return;
        }

        final List<Request> loadedRequests = [];

        for (var doc in snapshot.docs) {
          try {
            final request = Request.fromFirestore(doc);
            loadedRequests.add(request);
          } catch (e) {
            debugPrint("Error parsing request document ${doc.id}: $e");
            // Continue with other documents
          }
        }

        setState(() {
          _requests = loadedRequests;
        });
      } catch (firestoreError) {
        debugPrint("Firestore query error: $firestoreError");
        setState(() {
          _errorMessage = "Database error: $firestoreError";
        });
      }
    } catch (e) {
      debugPrint("General error in _loadRequests: $e");
      setState(() {
        _errorMessage = "Failed to load requests: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Make a phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(phoneUri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch phone dialer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Open WhatsApp
  Future<void> _openWhatsApp(String phoneNumber) async {
    // Remove any non-numeric characters
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    final Uri whatsappUri = Uri.parse('https://wa.me/$cleanNumber');
    try {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open WhatsApp: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Mark request as contacted
  Future<void> _markAsContacted(String requestId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final batch = FirebaseFirestore.instance.batch();

      // Update seller's copy
      final sellerRequestRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('sellerRequests')
          .doc(requestId);

      batch.update(sellerRequestRef, {'status': 'Contacted'});

      // Update the main requests collection
      final mainRequestRef = FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId);

      batch.update(mainRequestRef, {'status': 'Contacted'});

      try {
        // Get buyer ID from the main request document
        final requestDoc = await mainRequestRef.get();

        if (requestDoc.exists) {
          final data = requestDoc.data();
          final buyerId = data?['buyerId'];

          if (buyerId != null) {
            // Update buyer's copy
            final buyerRequestRef = FirebaseFirestore.instance
                .collection('users')
                .doc(buyerId)
                .collection('buyerRequests')
                .doc(requestId);

            batch.update(buyerRequestRef, {'status': 'Contacted'});
          }
        }
      } catch (e) {
        debugPrint("Error updating buyer's copy: $e");
        // Continue with the batch commit anyway
      }

      // Commit all updates
      await batch.commit();

      // Refresh the list
      await _loadRequests();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request marked as contacted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Requests',
              style: AppTextStyles.heading1,
            ),
            const SizedBox(height: 8),
            Text(
              'Requests from buyers interested in your products',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            // Display error message if any
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: AppTextStyles.body.copyWith(color: Colors.red),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.red),
                      onPressed: _loadRequests,
                      tooltip: 'Try again',
                    ),
                  ],
                ),
              ),

            // Pull to refresh
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadRequests,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _requests.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                  controller: _scrollController,
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final request = _requests[index];
                    return _buildRequestCard(request);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No requests yet',
            style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'When buyers request your products, they will appear here',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Request request) {
    final isExpiringSoon = request.sellerDaysRemaining <= 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with product name and expiry
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isExpiringSoon ? Colors.red.shade50 : AppColors.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    request.productName,
                    style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isExpiringSoon ? Colors.red.withOpacity(0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isExpiringSoon ? Colors.red : AppColors.primary,
                    ),
                  ),
                  child: Text(
                    isExpiringSoon
                        ? 'Expires soon: ${request.sellerDaysRemaining} ${request.sellerDaysRemaining == 1 ? 'day' : 'days'}'
                        : '${request.sellerDaysRemaining} ${request.sellerDaysRemaining == 1 ? 'day' : 'days'} left',
                    style: AppTextStyles.caption.copyWith(
                      color: isExpiringSoon ? Colors.red : AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Request details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Buyer Name
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      request.buyerName,
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Quantity
                Row(
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'Quantity: ${request.quantity}',
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Request Date
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'Requested on: ${DateFormat('MMM dd, yyyy').format(request.requestDate)}',
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Contact Buttons
                Row(
                  children: [
                    // Call Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _makePhoneCall(request.buyerPhone);
                          _markAsContacted(request.id);
                        },
                        icon: const Icon(Icons.call, color: Colors.white),
                        label: const Text('Call'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // WhatsApp Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _openWhatsApp(request.buyerPhone);
                          _markAsContacted(request.id);
                        },
                        icon: const Icon(FontAwesomeIcons.whatsapp, color: Colors.white),
                        label: const Text('WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366), // WhatsApp green
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),

                // Status indicator
                if (request.status == 'Contacted')
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Contacted',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}