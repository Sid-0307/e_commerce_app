import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';

class ProductSearchWidget extends StatefulWidget {
  final List<Product> products;
  final Function(String) onSearch;
  final Function(Product) onProductSelected;
  final String initialSearchText;

  const ProductSearchWidget({
    Key? key,
    required this.products,
    required this.onSearch,
    required this.onProductSelected,
    this.initialSearchText = '',
  }) : super(key: key);

  @override
  State<ProductSearchWidget> createState() => _ProductSearchWidgetState();
}

class _ProductSearchWidgetState extends State<ProductSearchWidget> {
  late final TextEditingController _searchController;
  final FocusNode _focusNode = FocusNode();
  bool _showDropdown = false;
  List<Product> _filteredDropdownItems = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearchText);
    _filteredDropdownItems = widget.products;

    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void didUpdateWidget(ProductSearchWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.products != widget.products) {
      _updateDropdownItems();
    }

    if (oldWidget.initialSearchText != widget.initialSearchText) {
      _searchController.text = widget.initialSearchText;
    }
  }

  void _onSearchTextChanged() {
    _updateDropdownItems();
    setState(() {
      _showDropdown = _searchController.text.isNotEmpty;
    });
  }

  void _updateDropdownItems() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _filteredDropdownItems = widget.products;
      } else {
        _filteredDropdownItems = widget.products
            .where((product) => product.name
            .toLowerCase()
            .contains(_searchController.text.toLowerCase()))
            .toList();
      }
    });
  }

  void _executeSearch() {
    widget.onSearch(_searchController.text);
    setState(() {
      _showDropdown = false;
    });
    _focusNode.unfocus();
  }

  void _selectProduct(Product product) {
    widget.onProductSelected(product);
    _searchController.text = product.name;
    setState(() {
      _showDropdown = false;
    });
    _focusNode.unfocus();
  }

  void _clearSearch() {
    _searchController.clear();
    widget.onSearch('');
    setState(() {
      _showDropdown = false;
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // Search Field
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: "Search products",
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: _clearSearch,
                    )
                        : null,
                  ),
                  onSubmitted: (_) => _executeSearch(),
                  onTap: () {
                    if (_searchController.text.isNotEmpty) {
                      setState(() {
                        _showDropdown = true;
                      });
                    }
                  },
                ),
              ),

              // Search Button
              InkWell(
                onTap: _executeSearch,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.horizontal(right: Radius.circular(11)),
                  ),
                  child: const Icon(
                    Icons.search,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Dropdown with reduced vertical spacing
        if (_showDropdown && _filteredDropdownItems.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredDropdownItems.length,
              itemBuilder: (context, index) {
                final product = _filteredDropdownItems[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _selectProduct(product),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: SizedBox(
                        height: 36, // Fixed height to reduce gap
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            product.name,
                            style: AppTextStyles.body,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}