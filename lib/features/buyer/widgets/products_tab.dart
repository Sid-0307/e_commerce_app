import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../vendor/models/product_model.dart';
import '../../vendor/widgets/search_widget.dart';
import '../screens/product_detail_screen.dart';

class BuyerProductsTab extends StatefulWidget {
  const BuyerProductsTab({Key? key}) : super(key: key);

  @override
  State<BuyerProductsTab> createState() => _BuyerProductsTabState();
}

class _BuyerProductsTabState extends State<BuyerProductsTab> {
  String _searchQuery = '';
  String _selectedShippingTerm = 'All';
  bool _isFilterPanelOpen = false;
  String _sortBy = 'none'; // Add this for sorting state
  List<Product> _allProducts = []; // Store all products
  Product? _selectedProduct;
  List<Product> _filteredProducts = []; // Store filtered products
  bool _showingSelectedProduct = false;
  bool _initialized = false; // Add this flag to track initialization
  bool _displayFilter= false;

  // Price range filter
  RangeValues _priceRange = const RangeValues(0, 10000);
  double _minPrice = 0;
  double _maxPrice = 10000;

  // Country filter
  String _selectedCountry = 'All';
  final List<String> _countries = ['All', 'China', 'USA', 'India', 'Germany', 'Japan'];

  // List of shipping terms for filtering
  final List<String> _shippingTerms = ['All', 'FOB', 'CIF', 'EXW', 'DDP', 'CFR'];

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _showingSelectedProduct = false;
      _applyAllFilters();
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
      _displayFilter = true;
      _isFilterPanelOpen = false;
      _applyAllFilters();
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedShippingTerm = 'All';
      _selectedCountry = 'All';
      _priceRange = const RangeValues(0, 10000);
      _minPrice = 0;
      _maxPrice = 10000;
      _applyAllFilters();
      _displayFilter = false;
    });
  }

  // Add toggle sort method
  void _toggleSortOrder() {
    setState(() {
      // Cycle through sort orders: none -> low to high -> high to low -> none
      if (_sortBy == 'none') {
        _sortBy = 'lowToHigh';
      } else if (_sortBy == 'lowToHigh') {
        _sortBy = 'highToLow';
      } else {
        _sortBy = 'none';
      }
      _applyAllFilters();
    });
  }

  // Central function to apply all filters and sorting
  void _applyAllFilters() {
    print("Applying all filters");
    setState(() {
      if (_showingSelectedProduct && _selectedProduct != null) {
        _filteredProducts = [_selectedProduct!];
        return;
      }

      // Start with all products
      _filteredProducts = List.from(_allProducts);
      print("After copying all products: ${_filteredProducts.length}");

      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        _filteredProducts = _filteredProducts.where((product) =>
        product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product.description.toLowerCase().contains(_searchQuery.toLowerCase())
        ).toList();
        print("After search filter: ${_filteredProducts.length}");
      }

      // Apply shipping term filter
      if (_selectedShippingTerm != 'All') {
        _filteredProducts = _filteredProducts.where((product) =>
        product.shippingTerm == _selectedShippingTerm
        ).toList();
        print("After shipping filter: ${_filteredProducts.length}");
      }

      // Apply country filter
      if (_selectedCountry != 'All') {
        _filteredProducts = _filteredProducts.where((product) =>
        product.countryOfOrigin == _selectedCountry
        ).toList();
        print("After country filter: ${_filteredProducts.length}");
      }

      // Apply price filter
      _filteredProducts = _filteredProducts.where((product) =>
      product.minPrice >= _minPrice && product.maxPrice <= _maxPrice
      ).toList();
      print("After price filter: ${_filteredProducts.length}");

      // Apply sorting
      if (_sortBy == 'lowToHigh') {
        _filteredProducts.sort((a, b) => a.minPrice.compareTo(b.minPrice));
      } else if (_sortBy == 'highToLow') {
        _filteredProducts.sort((a, b) => b.minPrice.compareTo(a.minPrice));
      }
    });
  }

  // New search method compatible with ProductSearchWidget
  void _filterProducts(String query) {
    setState(() {
      _searchQuery = query;
      _showingSelectedProduct = false;
      _applyAllFilters();
    });
  }

  // Select a specific product method compatible with ProductSearchWidget
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

                // Wrapping the rest of the content in Expanded
                Expanded(
                  child:
                      // Using ProductSearchWidget from vendor module
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('products').snapshots(),
                        builder: (context, snapshot) {
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
                          if ((!snapshot.hasData || snapshot.data!.docs.isEmpty) && snapshot.connectionState == ConnectionState.active) {
                            return _buildEmptyState(context);
                          }

                          // Convert to list of products
                          _allProducts = snapshot.data!.docs.map((doc) {
                            return Product.fromFirestore(doc);
                          }).toList();

                          print("Total products loaded: ${_allProducts.length}");

                          // Initialize filtered products if needed
                          if (!_initialized) {
                            print("Initializing filtered products");
                            _filteredProducts = List.from(_allProducts);
                            _initialized = true;

                            // Apply any active filters
                            if (_selectedShippingTerm != 'All' ||
                                _selectedCountry != 'All' ||
                                _minPrice > 0 ||
                                _maxPrice < 10000 ||
                                _searchQuery.isNotEmpty) {
                              _applyAllFilters();
                            }
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ProductSearchWidget(
                                products: _allProducts,
                                onSearch: _filterProducts,
                                onProductSelected: _selectProduct,
                                initialSearchText: _searchQuery,
                              ),
                              const SizedBox(height: 16),

                              // Filter row
                              Row(
                                children: [
                                  // Filter button
                                  Container(
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
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.tune,
                                                color: AppColors.primary,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Filter',
                                                style: TextStyle(
                                                  color: AppColors.primary,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const Spacer(),

                                  // Sort button
                                  GestureDetector(
                                    onTap: _toggleSortOrder,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _sortBy != 'none'
                                            ? AppColors.primary.withOpacity(0.1)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.textSecondary.withOpacity(0.2),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _sortBy == 'lowToHigh'
                                                ? 'Low to High'
                                                : _sortBy == 'highToLow'
                                                ? 'High to Low'
                                                : 'Sort by Price',
                                            style: TextStyle(
                                              color: _sortBy != 'none'
                                                  ? AppColors.primary
                                                  : AppColors.textSecondary,
                                              fontSize: 12,
                                              fontWeight: _sortBy != 'none'
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            _sortBy == 'lowToHigh'
                                                ? Icons.arrow_upward
                                                : _sortBy == 'highToLow'
                                                ? Icons.arrow_downward
                                                : Icons.sort,
                                            size: 14,
                                            color: _sortBy != 'none'
                                                ? AppColors.primary
                                                : AppColors.textSecondary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Active filters display row
                              if (_displayFilter && (_selectedShippingTerm != 'All' || _selectedCountry != 'All' || _minPrice > 0 || _maxPrice < 10000))
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
                                            _applyAllFilters();
                                          });
                                        }),

                                      if (_selectedCountry != 'All')
                                        _buildActiveFilterChip(_selectedCountry, () {
                                          setState(() {
                                            _selectedCountry = 'All';
                                            _applyAllFilters();
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
                                                _applyAllFilters();
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

                              // Products count
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${_filteredProducts.length} products found',
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Products list - Now we wrap this in Expanded
                              Expanded(
                                child: _filteredProducts.isEmpty
                                    ? _buildEmptyState(context)
                                    : _buildProductsList(context, _filteredProducts),
                              ),
                            ],
                          );
                        },
                      ),
                  ),
              ],
            ),
          ),

          // Filter Panel - positioned in the Stack
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
          alignment: Alignment.centerLeft,
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

  Widget _buildEmptyState(BuildContext context) {
    print("Building empty state, search query: $_searchQuery");
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
            _searchQuery.isEmpty
                ? 'No products available'
                : 'No products matching "$_searchQuery"',
            style: AppTextStyles.subtitle,
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Try a different search term',
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductsList(BuildContext context, List<Product> products) {
    print("Building products list with ${products.length} products");

    return ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
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
                      child: product.imageUrls != null &&
                          product.imageUrls!.isNotEmpty
                          ? Image.network(
                        product.imageUrls![0],
                        width: 115,
                        height: 115,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                              width: 115,
                              height: 115,
                              color: AppColors.border,
                              child: const Icon(Icons.image_not_supported,
                                  color: AppColors.textSecondary),
                            ),
                      )
                          : Container(
                        width: 115,
                        height: 115,
                        color: AppColors.border,
                        child: const Icon(
                            Icons.image, color: AppColors.textSecondary),
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
                              Expanded(
                                child: Text(
                                  product.name,
                                  style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '\$${product.minPrice} - \$${product
                                  .maxPrice} ${product.priceUnit ?? ''}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (product.shippingTerm != null &&
                              product.countryOfOrigin != null)
                            Text(
                              '• ${product.shippingTerm} • ${product
                                  .countryOfOrigin}',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }
}