import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/text_styles.dart';
import '../../vendor/models/product_model.dart';
import '../../vendor/widgets/search_widget.dart';
import '../screens/admin_product_detail_screen.dart'; // Import the detail screen

class AdminProductTab extends StatefulWidget {
  const AdminProductTab({Key? key}) : super(key: key);

  @override
  State<AdminProductTab> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Product Management', style: AppTextStyles.heading1),
        ),
        automaticallyImplyLeading: false, // This removes the back arrow
        backgroundColor: AppColors.background,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending Requests'),
            Tab(text: 'All Products'),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          PendingProductsTab(),
          AllProductsTab(),
        ],
      ),
    );
  }
}

// Tab for pending product requests with approval/rejection functionality
class PendingProductsTab extends StatefulWidget {
  const PendingProductsTab({Key? key}) : super(key: key);

  @override
  State<PendingProductsTab> createState() => _PendingProductsTabState();
}

class _PendingProductsTabState extends State<PendingProductsTab> {
  String _searchQuery = '';
  List<Product> _pendingProducts = [];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Search widget
          ProductSearchWidget(
            products: _pendingProducts,
            onSearch: (query) {
              if (mounted) {
                setState(() {
                  _searchQuery = query;
                });
              }
            },
            onProductSelected: (product) {
              if (mounted) {
                setState(() {
                  _searchQuery = product.name;
                });
              }
            },
            initialSearchText: _searchQuery,
          ),

          const SizedBox(height: 16),

          // Products list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .where('verification', whereIn: ['Pending', ''])
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading products: ${snapshot.error}',
                      style: AppTextStyles.body,
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState('No pending products');
                }

                // Convert to list of products
                _pendingProducts = snapshot.data!.docs
                    .map((doc) => Product.fromFirestore(doc))
                    .toList();

                // Apply search filter
                List<Product> filteredProducts = _pendingProducts;
                if (_searchQuery.isNotEmpty) {
                  filteredProducts = _pendingProducts.where((product) =>
                  product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      product.description.toLowerCase().contains(_searchQuery.toLowerCase())
                  ).toList();
                }

                if (filteredProducts.isEmpty) {
                  return _buildEmptyState('No products matching "$_searchQuery"');
                }

                return _buildProductsList(filteredProducts);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pending_actions,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.subtitle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList(List<Product> products) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminProductDetailScreen(
                  product: product,
                  isPending: true,
                ),
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: product.imageUrls != null && product.imageUrls!.isNotEmpty
                        ? Image.network(
                      product.imageUrls![0],
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 80,
                        width: 80,
                        color: AppColors.border,
                        child: const Icon(Icons.image_not_supported, color: AppColors.textSecondary),
                      ),
                    )
                        : Container(
                      height: 80,
                      width: 80,
                      color: AppColors.border,
                      child: const Icon(Icons.image, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Product Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'By: ${product.email}',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${product.minPrice} - \$${product.maxPrice}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                      Icons.timer_outlined,
                      color: Colors.orange
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Tab for all products (approved and rejected)
class AllProductsTab extends StatefulWidget {
  const AllProductsTab({Key? key}) : super(key: key);

  @override
  State<AllProductsTab> createState() => _AllProductsTabState();
}

class _AllProductsTabState extends State<AllProductsTab> {
  String _searchQuery = '';
  String _selectedFilter = 'all'; // Default filter is 'all'
  List<Product> _allProducts = [];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Search widget
          ProductSearchWidget(
            products: _allProducts,
            onSearch: (query) {
              if (mounted) {
                setState(() {
                  _searchQuery = query;
                });
              }
            },
            onProductSelected: (product) {
              if (mounted) {
                setState(() {
                  _searchQuery = product.name;
                });
              }
            },
            initialSearchText: _searchQuery,
          ),

          const SizedBox(height: 16),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  selected: _selectedFilter == 'all',
                  label: const Text('All Products'),
                  onSelected: (selected) {
                    if (selected && mounted) {
                      setState(() {
                        _selectedFilter = 'all';
                      });
                    }
                  },
                  backgroundColor: Colors.white,
                  selectedColor: AppColors.primary.withOpacity(0.1),
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: _selectedFilter == 'all' ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  selected: _selectedFilter == 'approved',
                  label: const Text('Approved'),
                  onSelected: (selected) {
                    if (selected && mounted) {
                      setState(() {
                        _selectedFilter = 'approved';
                      });
                    }
                  },
                  backgroundColor: Colors.white,
                  selectedColor: AppColors.primary.withOpacity(0.1),
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: _selectedFilter == 'approved' ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  selected: _selectedFilter == 'rejected',
                  label: const Text('Rejected'),
                  onSelected: (selected) {
                    if (selected && mounted) {
                      setState(() {
                        _selectedFilter = 'rejected';
                      });
                    }
                  },
                  backgroundColor: Colors.white,
                  selectedColor: AppColors.primary.withOpacity(0.1),
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: _selectedFilter == 'rejected' ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Products list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getFilteredProductsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading products: ${snapshot.error}',
                      style: AppTextStyles.body,
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                // Convert to list of products
                _allProducts = snapshot.data!.docs
                    .map((doc) => Product.fromFirestore(doc))
                    .toList();

                // Apply search filter
                List<Product> filteredProducts = _allProducts;
                if (_searchQuery.isNotEmpty) {
                  filteredProducts = _allProducts.where((product) =>
                  product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      product.description.toLowerCase().contains(_searchQuery.toLowerCase())
                  ).toList();
                }

                if (filteredProducts.isEmpty) {
                  return _buildEmptyFilterState();
                }

                // Show product count
                return Column(
                  children: [
                    Text(
                      '${filteredProducts.length} products found',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _buildProductsList(filteredProducts),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getFilteredProductsStream() {
    // For the All Products tab, we don't want to show pending products
    if (_selectedFilter == 'approved') {
      return FirebaseFirestore.instance
          .collection('products')
          .where('verification', isEqualTo: 'Approved')
          .snapshots();
    } else if (_selectedFilter == 'rejected') {
      return FirebaseFirestore.instance
          .collection('products')
          .where('verification', isEqualTo: 'Rejected')
          .snapshots();
    } else {
      // All products (excluding pending)
      return FirebaseFirestore.instance
          .collection('products')
          .where('verification', whereIn: ['Approved', 'Rejected'])
          .snapshots();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No products available',
            style: AppTextStyles.subtitle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilterState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.filter_list,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No products matching "$_searchQuery"'
                : _getEmptyFilterMessage(),
            style: AppTextStyles.subtitle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getEmptyFilterMessage() {
    switch (_selectedFilter) {
      case 'approved':
        return 'No approved products';
      case 'rejected':
        return 'No rejected products';
      default:
        return 'No products found';
    }
  }

  Widget _buildProductsList(List<Product> products) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminProductDetailScreen(
                  product: product,
                  isPending: false,
                ),
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: product.imageUrls != null && product.imageUrls!.isNotEmpty
                        ? Image.network(
                      product.imageUrls![0],
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 80,
                        width: 80,
                        color: AppColors.border,
                        child: const Icon(Icons.image_not_supported, color: AppColors.textSecondary),
                      ),
                    )
                        : Container(
                      height: 80,
                      width: 80,
                      color: AppColors.border,
                      child: const Icon(Icons.image, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Product Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'By: ${product.email}',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${product.minPrice} - \$${product.maxPrice}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if(product.verification=="Approved")
                    Icon(
                      Icons.verified,
                      color: Colors.green,
                    ),
                  if(product.verification=="Rejected")
                    Icon(
                      Icons.error_outline,
                      color: Colors.red,
                    )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}