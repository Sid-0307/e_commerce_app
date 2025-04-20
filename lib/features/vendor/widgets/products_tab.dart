// lib/features/vendor/widgets/products_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/widgets/custom_button.dart';
import '../models/product_model.dart';
import '../screens/add_edit_product_screen.dart';

class ProductsTab extends StatelessWidget {
  const ProductsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mock data for products - this would come from your database in a real app
    // For testing empty state, you can set this to an empty list
    final List<Product> products = [
      // Product(
      //   name: 'T-shirt',
      //   price: 20,
      //   minPrice: 15,
      //   maxPrice: 25,
      //   description: 'Cotton T-shirt',
      //   priceUnit: 'per piece',
      //   shippingTerm: 'FOB',
      //   countryOfOrigin: 'India',
      //   paymentTerms: '100% advance payment',
      //   dispatchPort: 'Mumbai Port',
      //   iconData: Icons.accessibility,
      // ),
      // Product(
      //   name: 'Laptop',
      //   price: 999,
      //   minPrice: 899,
      //   maxPrice: 1099,
      //   description: 'High-performance laptop',
      //   priceUnit: 'per piece',
      //   shippingTerm: 'CIF',
      //   countryOfOrigin: 'China',
      //   paymentTerms: '50% advance, 50% on delivery',
      //   dispatchPort: 'Shanghai Port',
      //   iconData: Icons.laptop,
      // ),
    ];
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;
    print(user);

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
                  'Products' ,
                  style: AppTextStyles.heading1,
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/vendor/product/add');
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
              child: products.isEmpty
                  ? _buildEmptyState(context)
                  : _buildProductsList(context, products),
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
              Navigator.pushNamed(context, '/vendor/product/add');
            },
            // buttonColor: AppColors.primary,
            // textColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList(BuildContext context, List<Product> products) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            // Navigate to product detail or direct to edit screen
            Navigator.pushNamed(
              context,
              '/vendor/product/edit',
              arguments: products[index],
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
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(4),
                ),
                // child: Icon(products[index].iconData, size: 30),
              ),
              title: Text(
                products[index].name,
                style: AppTextStyles.bodyLarge,
              ),
              subtitle: Text(
                '${products[index].shippingTerm} • ${products[index].countryOfOrigin}',
                style: AppTextStyles.caption,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${products[index].minPrice} - \$${products[index].maxPrice}',
                    style: AppTextStyles.caption,
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