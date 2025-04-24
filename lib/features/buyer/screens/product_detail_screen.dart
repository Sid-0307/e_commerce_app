// lib/features/buyer/screens/product_detail_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../../vendor/models/product_model.dart';
import '../widgets/pdf_viewer_tab.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Replace the current _openUrl method with this enhanced version
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
                    product.name,
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
                          '\$${product.minPrice} - \$${product.maxPrice} ${product.priceUnit ?? ''}',
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
                    product.description,
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: 24),

                  // Specifications
                  Text(
                    'Specifications',
                    style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildSpecificationItem('Country of Origin', product.countryOfOrigin),
                  _buildSpecificationItem('Shipping Terms', product.shippingTerm),
                  _buildSpecificationItem('Payment Terms', product.paymentTerms),
                  _buildSpecificationItem('Dispatch Port', product.dispatchPort),
                  _buildSpecificationItem('Transit Time', product.transitTime),
                  _buildSpecificationItem('Buyer Inspection', product.buyerInspection != null && product.buyerInspection! ? 'Available' : 'Not Available'),
                  const SizedBox(height: 16),

                  // Test Report
                  if (product.testReportUrl != null && product.testReportUrl!.isNotEmpty)
                    InkWell(
                      onTap: () => _openPdfPreview(context, product.testReportUrl!),
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
                  if (product.videoUrl != null && product.videoUrl!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Product Video',
                          style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _openUrl(product.videoUrl),
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
                    text: 'Contact Supplier',
                    onPressed: () {
                      // Show contact info or message dialog
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Contact Supplier'),
                          content: Text('Would you like to contact the supplier about "${product.name}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                // Here you would typically launch email or messaging
                                Navigator.pop(context);
                                if (product.email.isNotEmpty) {
                                  _openUrl('mailto:${product.email}?subject=Inquiry about ${product.name}');
                                }
                              },
                              child: const Text('Contact'),
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
    if (product.imageUrls == null || product.imageUrls!.isEmpty) {
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
        itemCount: product.imageUrls!.length,
        itemBuilder: (context, index) {
          return Image.network(
            product.imageUrls![index],
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