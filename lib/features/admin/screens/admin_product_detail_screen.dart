import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../../buyer/widgets/pdf_viewer_tab.dart';
import '../../vendor/models/product_model.dart';

class AdminProductDetailScreen extends StatefulWidget {
  final Product product;
  final bool isPending;

  const AdminProductDetailScreen({
    Key? key,
    required this.product,
    this.isPending = false,
  }) : super(key: key);

  @override
  State<AdminProductDetailScreen> createState() => _AdminProductDetailScreenState();
}

class _AdminProductDetailScreenState extends State<AdminProductDetailScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

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

  Future<void> _approveProduct() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.product.id)
          .update({'verification': 'Approved'});

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product approved successfully')),
      );

      // Return to previous screen after successful approval
      if (context.mounted) {
        Navigator.pop(context, 'approved');
      }

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving product: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _rejectProduct() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.product.id)
          .update({'verification': 'Rejected'});

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product rejected')),
      );

      // Return to previous screen after successful rejection
      if (context.mounted) {
        Navigator.pop(context, 'rejected');
      }

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting product: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product Review'),
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
                  // Verification status badge
                  _buildVerificationBadge(),
                  const SizedBox(height: 8),

                  // Product name
                  Text(
                    widget.product.name,
                    style: AppTextStyles.heading1,
                  ),
                  const SizedBox(height: 8),

                  // Seller information
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.store, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Seller Information',
                                style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Email: ${widget.product.email}',
                                style: AppTextStyles.body,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

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
                          '\$${widget.product.minPrice} - \$${widget.product.maxPrice} ${widget.product.priceUnit ?? ''}',
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
                    widget.product.description,
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: 24),

                  // Specifications
                  Text(
                    'Specifications',
                    style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildSpecificationItem('HS Code', widget.product.getHsCodeWithProduct()),
                  _buildSpecificationItem('Country of Origin', widget.product.countryOfOrigin),
                  _buildSpecificationItem('Shipping Terms', widget.product.shippingTerm),
                  _buildSpecificationItem('Payment Terms', widget.product.paymentTerms),
                  _buildSpecificationItem('Dispatch Port', widget.product.dispatchPort),
                  _buildSpecificationItem('Transit Time', widget.product.transitTime),
                  _buildSpecificationItem('Buyer Inspection', widget.product.buyerInspection != null && widget.product.buyerInspection! ? 'Available' : 'Not Available'),
                  const SizedBox(height: 16),

                  // Test Report
                  if (widget.product.testReportUrl != null && widget.product.testReportUrl!.isNotEmpty)
                    InkWell(
                      onTap: () => _openPdfPreview(context, widget.product.testReportUrl!),
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
                  if (widget.product.videoUrl != null && widget.product.videoUrl!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Product Video',
                          style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _openUrl(widget.product.videoUrl),
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

                  // Admin action buttons - only show if pending
                  if (widget.isPending)
                    _buildAdminActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationBadge() {
    Color badgeColor;
    String statusText;
    IconData statusIcon;

    switch (widget.product.verification) {
      case 'Approved':
        badgeColor = Colors.green;
        statusText = 'Approved';
        statusIcon = Icons.check_circle;
        break;
      case 'Rejected':
        badgeColor = Colors.red;
        statusText = 'Rejected';
        statusIcon = Icons.cancel;
        break;
      default:
        badgeColor = Colors.orange;
        statusText = 'Pending Approval';
        statusIcon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 16,
            color: badgeColor,
          ),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: _isLoading ? 'Approving...' : 'Approve Product',
                onPressed: _isLoading ? (){} : _approveProduct,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomButton(
                text: _isLoading ? 'Rejecting...' : 'Reject Product',
                onPressed: _isLoading ? (){} : _rejectProduct,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageGallery() {
    if (widget.product.imageUrls == null || widget.product.imageUrls!.isEmpty) {
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
        itemCount: widget.product.imageUrls!.length,
        itemBuilder: (context, index) {
          return Image.network(
            widget.product.imageUrls![index],
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