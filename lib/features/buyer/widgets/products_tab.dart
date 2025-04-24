import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../vendor/models/product_model.dart';
import '../screens/product_detail_screen.dart';

class BuyerProductsTab extends StatefulWidget {
  const BuyerProductsTab({Key? key}) : super(key: key);

  @override
  State<BuyerProductsTab> createState() => _BuyerProductsTabState();
}

class _BuyerProductsTabState extends State<BuyerProductsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedShippingTerm = 'All';
  bool _isFilterPanelOpen = false;

  // Price range filter
  RangeValues _priceRange = const RangeValues(0, 10000);
  double _minPrice = 0;
  double _maxPrice = 10000;

  // Country filter
  String _selectedCountry = 'All';
  final List<String> _countries = ['All', 'China', 'USA', 'India', 'Germany', 'Japan'];

  // List of shipping terms for filtering
  final List<String> _shippingTerms = ['All', 'FOB', 'CIF', 'EXW', 'DDP', 'CFR'];

  void _performSearch() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
    });
  }

  void _openFilterPanel() {
    setState(() {
      _isFilterPanelOpen = true;
    });
  }

  void _closeFilterPanel() {
    setState(() {
      _isFilterPanelOpen = false;
    });
  }

  void _applyFilters() {
    setState(() {
      _minPrice = _priceRange.start;
      _maxPrice = _priceRange.end;
      _isFilterPanelOpen = false;
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedShippingTerm = 'All';
      _selectedCountry = 'All';
      _priceRange = const RangeValues(0, 10000);
      _minPrice = 0;
      _maxPrice = 10000;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Discover Products',
                style: AppTextStyles.heading1,
              ),
              const SizedBox(height: 16),

              // Search bar with improved design and filter icon
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          // Text field
                          Expanded(
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.horizontal(
                                  left: const Radius.circular(12),
                                  right: Radius.zero,
                                ),
                              ),
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search products...',
                                  hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.7)),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                    onPressed: _clearSearch,
                                    icon: Icon(
                                      Icons.close,
                                      size: 18,
                                      color: AppColors.textSecondary.withOpacity(1),
                                    ),
                                    splashRadius: 20,
                                  )
                                      : IconButton(
                                        onPressed: null,
                                        icon: Icon(
                                        Icons.close,
                                        size: 18,
                                        color: Colors.transparent,
                                        ),
                                      splashRadius: 20,
                                      ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                ),
                                onSubmitted: (_) => _performSearch(),
                                textInputAction: TextInputAction.search,
                                textAlignVertical: TextAlignVertical.center,
                              ),
                            ),
                          ),

                          // Search button
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: const BorderRadius.horizontal(
                                left: Radius.zero,
                                right: Radius.circular(12),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primary,
                                  AppColors.primary.withOpacity(0.8),
                                ],
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _performSearch,
                                borderRadius: const BorderRadius.horizontal(
                                  left: Radius.zero,
                                  right: Radius.circular(12),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.search,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Filter button
                  Container(
                    margin: const EdgeInsets.only(left: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _openFilterPanel,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            Icons.tune,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Active filters display row
              if (_selectedShippingTerm != 'All' || _selectedCountry != 'All' || _minPrice > 0 || _maxPrice < 10000)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_selectedShippingTerm != 'All')
                        _buildActiveFilterChip(_selectedShippingTerm, () {
                          setState(() {
                            _selectedShippingTerm = 'All';
                          });
                        }),

                      if (_selectedCountry != 'All')
                        _buildActiveFilterChip(_selectedCountry, () {
                          setState(() {
                            _selectedCountry = 'All';
                          });
                        }),

                      if (_minPrice > 0 || _maxPrice < 10000)
                        _buildActiveFilterChip(
                            '\$${_minPrice.toInt()} - \$${_maxPrice.toInt()}',
                                () {
                              setState(() {
                                _priceRange = const RangeValues(0, 10000);
                                _minPrice = 0;
                                _maxPrice = 10000;
                              });
                            }
                        ),

                      // Clear all filters button
                      GestureDetector(
                        onTap: _resetFilters,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.textSecondary.withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.clear_all,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Clear all',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Products grid
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('products').snapshots(),
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
                      return _buildEmptyState();
                    }

                    // Convert to list of products
                    List<Product> products = snapshot.data!.docs.map((doc) {
                      return Product.fromFirestore(doc);
                    }).toList();

                    // Apply search filter
                    if (_searchQuery.isNotEmpty) {
                      products = products.where((product) =>
                      product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          product.description.toLowerCase().contains(_searchQuery.toLowerCase())
                      ).toList();
                    }

                    // Apply shipping term filter
                    if (_selectedShippingTerm != 'All') {
                      products = products.where((product) =>
                      product.shippingTerm == _selectedShippingTerm
                      ).toList();
                    }

                    // Apply country filter
                    if (_selectedCountry != 'All') {
                      products = products.where((product) =>
                      product.countryOfOrigin == _selectedCountry
                      ).toList();
                    }

                    // Apply price filter
                    products = products.where((product) =>
                    product.minPrice >= _minPrice && product.maxPrice <= _maxPrice
                    ).toList();

                    // If no products match the filters
                    if (products.isEmpty) {
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
                              'No products found',
                              style: AppTextStyles.subtitle,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    // Display products grid
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${products.length} products found',
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              return _buildProductCard(context, products[index]);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Filter Panel
        if (_isFilterPanelOpen)
          _buildFilterPanel(),
      ],
    );
  }

  Widget _buildActiveFilterChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 16,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Align(
          alignment: Alignment.centerRight,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: MediaQuery.of(context).size.width * 0.85,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Filter panel header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Products',
                        style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _closeFilterPanel,
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),

                // Filter options
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price range filter
                        Text(
                          'Price Range',
                          style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '\$${_priceRange.start.toInt()}',
                              style: AppTextStyles.body,
                            ),
                            Text(
                              '\$${_priceRange.end.toInt()}',
                              style: AppTextStyles.body,
                            ),
                          ],
                        ),
                        RangeSlider(
                          values: _priceRange,
                          min: 0,
                          max: 10000,
                          divisions: 100,
                          activeColor: AppColors.primary,
                          inactiveColor: AppColors.border,
                          labels: RangeLabels(
                            '\$${_priceRange.start.toInt()}',
                            '\$${_priceRange.end.toInt()}',
                          ),
                          onChanged: (values) {
                            setState(() {
                              _priceRange = values;
                            });
                          },
                        ),

                        const Divider(height: 32),

                        // Shipping Terms filter
                        Text(
                          'Shipping Terms',
                          style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _shippingTerms.map((term) {
                            final isSelected = term == _selectedShippingTerm;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedShippingTerm = term;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : AppColors.border,
                                  ),
                                ),
                                child: Text(
                                  term,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : AppColors.textPrimary,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const Divider(height: 32),

                        // Country of Origin filter
                        Text(
                          'Country of Origin',
                          style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _countries.map((country) {
                            final isSelected = country == _selectedCountry;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedCountry = country;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : AppColors.border,
                                  ),
                                ),
                                child: Text(
                                  country,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : AppColors.textPrimary,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                // Apply & Reset buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Reset button
                      Expanded(
                        child: TextButton(
                          onPressed: _resetFilters,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Colors.white,
                            side: BorderSide(color: AppColors.border),
                          ),
                          child: Text(
                            'Reset',
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Apply button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _applyFilters,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: AppColors.primary,
                          ),
                          child: const Text(
                            'Apply',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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

  Widget _buildProductCard(BuildContext context, Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: product.imageUrls != null && product.imageUrls!.isNotEmpty
                  ? Image.network(
                product.imageUrls![0],
                height: 120, // Reduced height to prevent overflow
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 120,
                  color: AppColors.border,
                  child: const Icon(Icons.image_not_supported, color: AppColors.textSecondary),
                ),
              )
                  : Container(
                height: 120,
                color: AppColors.border,
                child: const Icon(Icons.image, color: AppColors.textSecondary),
              ),
            ),

            // Product info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0), // Reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13, // Slightly smaller font
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2), // Reduced spacing
                    Text(
                      '\$${product.minPrice} - \$${product.maxPrice} ${product.priceUnit ?? ''}',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 12, // Smaller font
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Country of origin with icon
                    if (product.countryOfOrigin != null && product.countryOfOrigin!.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 12, // Smaller icon
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              product.countryOfOrigin!,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11, // Smaller font
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    // Shipping term
                    if (product.shippingTerm != null && product.shippingTerm!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 1.0), // Reduced padding
                        child: Row(
                          children: [
                            Icon(
                              Icons.local_shipping_outlined,
                              size: 12, // Smaller icon
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                product.shippingTerm!,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 11, // Smaller font
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
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