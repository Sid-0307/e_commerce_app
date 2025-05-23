import 'package:e_commerce_app/core/widgets/auth_wrapper.dart';
import 'package:e_commerce_app/features/vendor/widgets/search_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/widgets/custom_button.dart';
import '../models/product_model.dart';
import '../screens/add_edit_product_screen.dart';

class ProductsTab extends StatefulWidget {
  const ProductsTab({Key? key}) : super(key: key);

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Product> _allProducts = [];
  Product? _selectedProduct;
  List<Product> _filteredProducts = [];
  bool _showingSelectedProduct = false;
  late AnimationController _deleteAnimationController;
  String? _deletingProductId;

  @override
  void initState() {
    super.initState();
    _deleteAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _deleteAnimationController.dispose();
    super.dispose();
  }

  void _filterProducts(String query) {
    if (_allProducts.isEmpty) return;
    setState(() {
      _searchQuery = query;
      _showingSelectedProduct = false;

      if (query.isEmpty) {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts = _allProducts
            .where((product) => product.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _selectProduct(Product product) {
    setState(() {
      _selectedProduct = product;
      _showingSelectedProduct = true;
      _filteredProducts = [product];
      _searchQuery = product.name;
    });
  }

  String _getCountryFlag(String? countryName) {
    final Map<String, String> countryFlags = {
      'united states': '🇺🇸',
      'usa': '🇺🇸',
      'china': '🇨🇳',
      'japan': '🇯🇵',
      'germany': '🇩🇪',
      'united kingdom': '🇬🇧',
      'uk': '🇬🇧',
      'france': '🇫🇷',
      'italy': '🇮🇹',
      'canada': '🇨🇦',
      'australia': '🇦🇺',
      'india': '🇮🇳',
      'brazil': '🇧🇷',
      'south korea': '🇰🇷',
      'mexico': '🇲🇽',
      'spain': '🇪🇸',
      'netherlands': '🇳🇱',
      'switzerland': '🇨🇭',
      'sweden': '🇸🇪',
      'singapore': '🇸🇬',
    };

    return countryFlags[countryName?.toLowerCase()] ?? '🌍';
  }

  Widget _buildBlob1() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withOpacity(0.7),
            AppColors.secondary,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(500),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: AppColors.primary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No products added yet',
            style: AppTextStyles.subtitle.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Start building your product catalog',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: 'Add Your First Product',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEditProductScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductsContent(AsyncSnapshot<QuerySnapshot> snapshot) {
    _allProducts = snapshot.data!.docs.map((doc) {
      return Product.fromFirestore(doc);
    }).toList();

    // Always update filtered products when data changes
    if (_searchQuery.isEmpty && !_showingSelectedProduct) {
      // No search query and not showing selected product - show all
      _filteredProducts = _allProducts;
    } else if (_showingSelectedProduct && _selectedProduct != null) {
      // Showing selected product - check if it still exists
      final selectedProductExists = _allProducts.any((p) => p.id == _selectedProduct!.id);
      if (selectedProductExists) {
        _filteredProducts = [_selectedProduct!];
      } else {
        // Selected product was deleted, reset to show all
        _selectedProduct = null;
        _showingSelectedProduct = false;
        _searchQuery = '';
        _searchController.clear();
        _filteredProducts = _allProducts;
      }
    } else if (_searchQuery.isNotEmpty) {
      // Apply search filter to current products
      _filteredProducts = _allProducts
          .where((product) => product.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          ProductSearchWidget(
            products: _allProducts,
            onSearch: _filterProducts,
            onProductSelected: _selectProduct,
            initialSearchText: _searchQuery,
          ),

          // Enhanced Results Count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '${_filteredProducts.length} products found',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w300,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: _buildProductsList(context, _filteredProducts),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('email', isEqualTo: user!.email)
          .snapshots(),
      builder: (context, snapshot) {
        // Determine if we should show the blob
        final hasProducts = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

        return Stack(
          children: [
            // Only show blob when there are products
            if (hasProducts)
              Positioned(
                left: -100,
                top: -50,
                right: -100,
                child: _buildBlob1(),
              ),

            // Main content
            if (snapshot.connectionState == ConnectionState.waiting)
              _buildShimmerLoading()
            else if (snapshot.hasError)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading products',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: AppTextStyles.caption,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else if (!hasProducts)
                _buildEmptyState(context) // No blob background here
              else
                _buildProductsContent(snapshot), // Blob background included

            // Floating Action Button
            if(hasProducts)
              Positioned(
              bottom: 25,
              right: 20,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddEditProductScreen(),
                    ),
                  );
                },
                backgroundColor: const Color(0xFF021024),
                foregroundColor: Colors.white,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.add_rounded, size: 24),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Search bar shimmer
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),
          // Results count shimmer
          Container(
            height: 32,
            width: 150,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 16),
          // Product list shimmer
          Expanded(
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 20,
                            width: double.infinity,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 16,
                            width: 200,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 16,
                            width: 120,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProductFiles(Product product) async {
    final storage = FirebaseStorage.instance;

    if (product.imageUrls != null && product.imageUrls!.isNotEmpty) {
      for (final imageUrl in product.imageUrls!) {
        try {
          final ref = storage.refFromURL(imageUrl);
          await ref.delete();
        } catch (e) {
          print('Error deleting image: $e');
        }
      }
    }

    if (product.testReportUrl != null && product.testReportUrl!.isNotEmpty) {
      try {
        final ref = storage.refFromURL(product.testReportUrl!);
        await ref.delete();
      } catch (e) {
        print('Error deleting report: $e');
      }
    }
  }

  Widget _buildProductsList(BuildContext context, List<Product> products) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 48,
                color: AppColors.lightTertiary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No products matching "${_searchQuery}"',
              style: AppTextStyles.subtitle.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final isDeleting = _deletingProductId == product.id;

        return AnimatedBuilder(
          animation: _deleteAnimationController,
          builder: (context, child) {
            return Transform.scale(
              scale: isDeleting ? 1.0 - _deleteAnimationController.value : 1.0,
              child: Opacity(
                opacity: isDeleting ? 1.0 - _deleteAnimationController.value : 1.0,
                child: _buildProductCard(product),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddEditProductScreen(product: product),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditProductScreen(product: product),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enhanced Product Image with Caching
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Hero(
                          tag: 'product_image_${product.id}',
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: product.imageUrls != null && product.imageUrls!.isNotEmpty
                                  ? _buildCachedImage(product.imageUrls![0])
                                  : _buildImagePlaceholder(),
                            ),
                          ),
                        ),
                        // Verification badge positioned at top right corner
                        Positioned(
                          top: -10,
                          right: -10,
                          child: _buildVerificationBadge(product.verification),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Enhanced Product Details
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Name
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  product.name,
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: const Color(0xFF021024),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Enhanced Price Container
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withOpacity(0.1),
                                  AppColors.primary.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '\$${product.minPrice} - \$${product.maxPrice} ${product.priceUnit}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Enhanced Shipping and Country Badges
                          Row(
                            children: [
                              _buildInfoBadge(
                                '${_getCountryFlag(product.countryOfOrigin)} ${product.countryOfOrigin}',
                                AppColors.lightTertiary,
                                AppColors.tertiary,
                              ),
                              const SizedBox(width: 8),
                              _buildInfoBadge(
                                product.shippingTerm,
                                AppColors.lightTertiary,
                                AppColors.tertiary,
                                icon: Icons.local_shipping,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Enhanced Delete Button
                  GestureDetector(
                    onTap: () => _showDeleteConfirmation(product),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.red.shade100,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Enhanced Cached Image Widget
  Widget _buildCachedImage(String imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: 100,
      height: 100,
      fit: BoxFit.cover,
      placeholder: (context, url) => _buildImageLoadingPlaceholder(),
      errorWidget: (context, url, error) => _buildImagePlaceholder(),
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
      // Memory cache configuration
      maxHeightDiskCache: 400,
      maxWidthDiskCache: 400,
      memCacheWidth: 400,
      memCacheHeight: 400,
      // Cache manager can be customized if needed
      // cachemanager: null, // Uses default cache manager
    );
  }

  // Loading placeholder for cached images
  Widget _buildImageLoadingPlaceholder() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shimmer effect
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade200,
                  Colors.grey.shade100,
                  Colors.grey.shade200,
                ],
                stops: const [0.0, 0.5, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Loading indicator
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primary.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 24,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 4),
          Text(
            'No Image',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBadge(String? verification) {
    IconData icon;
    Color color;

    switch (verification) {
      case "Approved":
        icon = Icons.verified_rounded;
        color = Colors.green;
        break;
      case "Pending":
        icon = Icons.timer_outlined;
        color = Colors.amber;
        break;
      case "Rejected":
        icon = Icons.error;
        color = Colors.red;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 24,
        color: color,
      ),
    );
  }

  Widget _buildInfoBadge(
      String? text,
      Color backgroundColor,
      Color textColor, {
        IconData? icon,
      }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: textColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            text!,
            style: TextStyle(
              fontSize: 11,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 30,
            ),
            const SizedBox(width: 12),
            const Text(
              'Delete Product',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${product.name}"?',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteProduct(product);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(Product product) async {
    setState(() {
      _deletingProductId = product.id;
    });

    await _deleteAnimationController.forward();

    try {
      await _deleteProductFiles(product);
      await FirebaseFirestore.instance
          .collection('products')
          .doc(product.id)
          .delete();

      // Reset search state if the deleted product was selected
      if (_showingSelectedProduct && _selectedProduct?.id == product.id) {
        setState(() {
          _selectedProduct = null;
          _showingSelectedProduct = false;
          _searchQuery = '';
          _searchController.clear();
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text('Product deleted successfully'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text('Error deleting product: $e'),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }

    setState(() {
      _deletingProductId = null;
    });
    _deleteAnimationController.reset();
  }
}