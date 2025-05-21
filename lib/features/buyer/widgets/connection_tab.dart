import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../vendor/models/request_model.dart';

class BuyerConnectionsTab extends StatefulWidget {
  const BuyerConnectionsTab({Key? key}) : super(key: key);

  @override
  State<BuyerConnectionsTab> createState() => _BuyerConnectionsTabState();
}

class _BuyerConnectionsTabState extends State<BuyerConnectionsTab> {
  bool _isLoading = false;
  List<Request> _requests = [];
  final ScrollController _scrollController = ScrollController();
  String? _errorMessage;
  Map<String, String?> _productImages = {};

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
      debugPrint("Loading requests for buyer userId: $userId");

      if (userId == null) {
        setState(() {
          _errorMessage = "User not authenticated";
          _isLoading = false;
        });
        return;
      }

      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('requests')
            .where('buyerId', isEqualTo: userId)
            .orderBy('requestDate', descending: true)
            .get();

        debugPrint("Fetched ${snapshot.docs.length} buyer requests");

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

            // Fetch product images for each product
            _fetchProductImage(request.productId);
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

  Future<void> _fetchProductImage(String productId) async {
    try {
      debugPrint("Fetching image for product: $productId");
      final doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final List<dynamic>? imageUrls = data['imageUrls'];

        if (mounted) {
          setState(() {
            if (imageUrls != null && imageUrls.isNotEmpty) {
              _productImages[productId] = imageUrls.first.toString();
              debugPrint(
                  "Image found for $productId: ${_productImages[productId]}");
            } else {
              _productImages[productId] = null;
              debugPrint("No images found for product $productId");
            }
          });
        }
      } else {
        debugPrint("Product document not found for ID: $productId");
      }
    } catch (e) {
      debugPrint("Error fetching product image for $productId: $e");
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
              'My Requests',
              style: AppTextStyles.heading1,
            ),
            const SizedBox(height: 8),
            Text(
              'Track all your product requests here',
              style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary),
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
            Icons.shopping_cart_outlined,
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
            'Products you request will appear here',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Request request) {
    final daysRemaining = request.sellerDaysRemaining;
    final isExpired = daysRemaining <= 0;
    final isExpiringSoon = daysRemaining > 0 && daysRemaining <= 2;

    // Determine status color and create status chip
    Color statusColor;
    String statusText;

    if (request.status == 'Contacted') {
      statusColor = Colors.green.shade100;
      statusText = 'Contacted';
    } else if (isExpired) {
      statusColor = Colors.red.shade100;
      statusText = 'Expired';
    } else if (isExpiringSoon) {
      statusColor = Colors.orange.shade100;
      statusText = 'Expiring Soon';
    } else {
      statusColor = Colors.blue.shade100;
      statusText = 'Pending';
    }

    // Determine text color for status (darker shade of the background)
    Color statusTextColor = request.status == 'Contacted'
        ? Colors.green.shade700
        : isExpired
        ? Colors.red.shade700
        : isExpiringSoon
        ? Colors.orange.shade700
        : Colors.blue.shade700;

    return GestureDetector(
      onTap: () {
        // Add your onTap action here
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image in a square with proper aspect ratio
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: _productImages.containsKey(request.productId) &&
                  _productImages[request.productId] != null
                  ? ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: Image.network(
                  _productImages[request.productId]!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.grey.shade300,
                        size: 26,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }
                    return Center(
                      child: ShimmerLoading(
                        isLoading: true,
                        child: Container(
                          width: 90,
                          height: 90,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              )
                  : Center(
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: Colors.grey.shade300,
                  size: 26,
                ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Product name row with status chip
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product name
                        Expanded(
                          child: Text(
                            request.productName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Status pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusTextColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Quantity and date row - more spaced out
                    Row(
                      children: [
                        Text(
                          'Qty: ${request.quantity}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          height: 12,
                          width: 1,
                          color: Colors.grey.shade200,
                        ),
                        Text(
                          DateFormat('MMM dd, yyyy').format(
                              request.requestDate),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Expiry progress indicator with gradient
                    if (!isExpired && request.status != 'Contacted')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${daysRemaining} ${daysRemaining == 1
                                    ? 'day'
                                    : 'days'} remaining',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isExpiringSoon
                                      ? Colors.orange.shade700
                                      : Colors.grey.shade600,
                                  fontWeight: isExpiringSoon
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Gradient progress bar
                          Container(
                            height: 4,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: Colors.grey.shade100,
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: daysRemaining / 10,
                              // Assuming 10 days total
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  gradient: LinearGradient(
                                    colors: isExpiringSoon
                                        ? [
                                      Colors.orange.shade300,
                                      Colors.orange.shade600
                                    ]
                                        : [
                                      Colors.blue.shade300,
                                      Colors.blue.shade600
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                    // Show "Expired" message if request has expired
                    if (isExpired && request.status != 'Contacted')
                      Text(
                        'Expired on ${DateFormat('MMM dd').format(
                            request.expiryDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// Add this shimmer effect for loading images
  class ShimmerLoading extends StatefulWidget {
  final bool isLoading;
  final Widget child;

  const ShimmerLoading({
  Key? key,
  required this.isLoading,
  required this.child,
  }) : super(key: key);

  @override
  _ShimmerLoadingState createState() => _ShimmerLoadingState();
  }

  class _ShimmerLoadingState extends State<ShimmerLoading>
  with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
  super.initState();
  _controller = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 1500),
  )..repeat();
  _animation = Tween<double>(begin: -2, end: 2).animate(_controller);
  }

  @override
  void dispose() {
  _controller.dispose();
  super.dispose();
  }

  @override
  Widget build(BuildContext context) {
  if (!widget.isLoading) {
  return widget.child;
  }

  return AnimatedBuilder(
  animation: _animation,
  builder: (context, child) {
  return ShaderMask(
  blendMode: BlendMode.srcATop,
  shaderCallback: (bounds) {
  return LinearGradient(
  colors: [
  Colors.grey.shade200,
  Colors.grey.shade100,
  Colors.grey.shade200,
  ],
  stops: const [0.1, 0.5, 0.9],
  begin: Alignment(_animation.value, 0),
  end: Alignment(_animation.value + 1, 0),
  ).createShader(bounds);
  },
  child: Container(
  color: Colors.grey.shade100,
  child: widget.child,
  ),
  );
  },
  );
  }
  }