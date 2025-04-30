  import 'package:e_commerce_app/features/vendor/widgets/search_widget.dart';
import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:firebase_storage/firebase_storage.dart';
  import 'package:dropdown_search/dropdown_search.dart';
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

  class _ProductsTabState extends State<ProductsTab> {
    final TextEditingController _searchController = TextEditingController();
    String _searchQuery = '';
    List<Product> _allProducts = [];
    Product? _selectedProduct;
    List<Product> _filteredProducts = [];
    bool _showingSelectedProduct = false;

    @override
    void dispose() {
      _searchController.dispose();
      super.dispose();
    }

    void _navigateToProduct(Product? product) {
      if (product != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddEditProductScreen(product: product),
          ),
        );

        // Reset selection after navigation
        Future.delayed(Duration.zero, () {
          setState(() {
            _selectedProduct = null;
          });
        });
      }
    }

    void _filterProducts(String query) {
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

    // Select a specific product
    void _selectProduct(Product product) {
      setState(() {
        _selectedProduct = product;
        _showingSelectedProduct = true;
        _filteredProducts = [product]; // Show only the selected product
        _searchQuery = product.name; // Keep the search query updated
      });
    }

    @override
    Widget build(BuildContext context) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.currentUser;

      return Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Products',
                    style: AppTextStyles.heading1,
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddEditProductScreen(),
                        ),
                      );
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('products').where('email', isEqualTo: user!.email).snapshots(),
                  builder: (context, snapshot) {
                    // Show loading indicator while waiting for data
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Handle errors
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading products: ${snapshot.error}',
                          style: AppTextStyles.body,
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    // No data available
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptyState(context);
                    }

                    // Convert to list of products
                    _allProducts = snapshot.data!.docs.map((doc) {
                      return Product.fromFirestore(doc);
                    }).toList();

                    if (_searchQuery.isEmpty && !_showingSelectedProduct) {
                      _filteredProducts = _allProducts;
                    }

                    // Apply search filter for the list view
                    // List<Product> filteredProducts = _allProducts;
                    // if (_searchQuery.isNotEmpty) {
                    //   filteredProducts = _allProducts.where((product) =>
                    //       product.name.toLowerCase().contains(_searchQuery.toLowerCase())
                    //   ).toList();
                    // }

                    // Display products with search
                    return Column(
                      children: [
                        // Dropdown search with professional design
                        ProductSearchWidget(
                          products: _allProducts,
                          onSearch: _filterProducts,
                          onProductSelected: _selectProduct,
                          initialSearchText: _searchQuery,
                        ),
                        const SizedBox(height: 16),

                        // Results count
                        Text(
                          '${_filteredProducts.length} products found',
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(height: 8),

                        // Product list
                        Expanded(
                          child: _buildProductsList(context, _filteredProducts),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget _buildEmptyState(BuildContext context) {
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
              'No products added yet',
              style: AppTextStyles.subtitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
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

    Future<void> _deleteProductFiles(Product product) async {
      final storage = FirebaseStorage.instance;

      // Delete image files
      if (product.imageUrls != null && product.imageUrls!.isNotEmpty) {
        for (final imageUrl in product.imageUrls!) {
          try {
            // Extract the file path from the URL
            final ref = storage.refFromURL(imageUrl);
            await ref.delete();
          } catch (e) {
            print('Error deleting image: $e');
          }
        }
      }

      // Delete PDF report if exists
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
        // Show "No products found" message when search returns no results
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No products matching "${_searchQuery}"',
                style: AppTextStyles.subtitle,
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
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditProductScreen(product: product),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: product.imageUrls != null && product.imageUrls!.isNotEmpty
                          ? Image.network(
                        product.imageUrls![0],
                        width: 115,
                        height: 115,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 115,
                          height: 115,
                          color: AppColors.border,
                          child: const Icon(Icons.image_not_supported, color: AppColors.textSecondary),
                        ),
                      )
                          : Container(
                        width: 115,
                        height: 115,
                        color: AppColors.border,
                        child: const Icon(Icons.image, color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Product details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                            Text(
                                product.name,
                                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (product.verified == true)
                              Padding(
                                padding: const EdgeInsets.only(left: 4.0),
                                child: Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: Colors.green,
                                ),
                              ),
                          ],
                        ),
                          const SizedBox(height: 4),
                          Text(
                            product.description,
                            style: AppTextStyles.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '\$${product.minPrice} - \$${product.maxPrice} ${product.priceUnit}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '• ${product.shippingTerm} • ${product.countryOfOrigin}',
                            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Delete icon
                    GestureDetector(
                      onTap: () {
                        // Show confirmation dialog
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Product'),
                            content: Text('Are you sure you want to delete "${product.name}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  // Delete the product files first
                                  await _deleteProductFiles(product);

                                  // Then delete the product document
                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('products')
                                        .doc(product.id)
                                        .delete();

                                    Navigator.pop(context);

                                    // Show success message
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Product deleted successfully')),
                                    );
                                  } catch (e) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error deleting product: $e')),
                                    );
                                  }
                                },
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        height: 30,
                        width: 30,
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: Colors.red,
                        ),
                      ),
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