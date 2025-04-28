import 'dart:io';
import 'package:e_commerce_app/core/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../models/product_model.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? product; // Null for add, non-null for edit

  const AddEditProductScreen({Key? key, this.product}) : super(key: key);

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storage = FirebaseStorage.instance;
  final _firestore = FirebaseFirestore.instance;
  final _uuid = Uuid();
  bool _isLoading = false;

  // Form controllers
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  late TextEditingController _dispatchPortController;
  late TextEditingController _transitTimeController;
  late TextEditingController _videoUrlController;

  // New payment terms controllers and state
  String _selectedPaymentTerm = '50% advance, 50% after delivery';
  final List<String> _paymentTerms = ['50% advance, 50% after delivery', 'Other'];
  bool _showCustomPaymentTermField = false;
  late TextEditingController _customPaymentTermController;

  String _priceUnit = 'per kg';
  String _shippingTerm = 'FOB';
  String _countryOfOrigin = 'United States';
  bool _buyerInspection = false;

  // For image and file uploads
  List<dynamic> _selectedImages = []; // Can be File or String (URL)
  File? _selectedTestReportFile;
  String? _selectedTestReportUrl;

  // Countries list for dropdown
  final List<String> _countries = ['United States', 'China', 'India', 'United Kingdom', 'Germany', 'Japan', 'Brazil'];

  // Price units
  final List<String> _priceUnits = ['per kg', 'per tonne', 'per piece', 'per lot'];

  // Shipping terms
  final List<String> _shippingTerms = ['FOB', 'CIF', 'EXW', 'DDP', 'FCA'];

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing data if editing
    _titleController = TextEditingController(text: widget.product?.name ?? '');
    _descriptionController = TextEditingController(text: widget.product?.description ?? '');
    _minPriceController = TextEditingController(text: widget.product?.minPrice.toString() ?? '');
    _maxPriceController = TextEditingController(text: widget.product?.maxPrice.toString() ?? '');
    _dispatchPortController = TextEditingController(text: widget.product?.dispatchPort ?? '');
    _transitTimeController = TextEditingController(text: widget.product?.transitTime ?? '');
    _videoUrlController = TextEditingController(text: widget.product?.videoUrl ?? '');
    _customPaymentTermController = TextEditingController();

    // Initialize dropdown values if editing
    if (widget.product != null) {
      _priceUnit = widget.product!.priceUnit ?? _priceUnit;
      _shippingTerm = widget.product!.shippingTerm ?? _shippingTerm;
      _countryOfOrigin = widget.product!.countryOfOrigin ?? _countryOfOrigin;
      _buyerInspection = widget.product!.buyerInspection ?? _buyerInspection;

      // Check if payment term matches any preset option
      if (widget.product!.paymentTerms != null) {
        if (_paymentTerms.contains(widget.product!.paymentTerms)) {
          _selectedPaymentTerm = widget.product!.paymentTerms!;
          _showCustomPaymentTermField = false;
        } else {
          _selectedPaymentTerm = 'Other';
          _showCustomPaymentTermField = true;
          _customPaymentTermController.text = widget.product!.paymentTerms!;
        }
      }

      // Initialize images if any
      if (widget.product!.imageUrls != null) {
        _selectedImages = List.from(widget.product!.imageUrls!);
      }

      // Initialize test report if any
      _selectedTestReportUrl = widget.product!.testReportUrl;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _dispatchPortController.dispose();
    _transitTimeController.dispose();
    _videoUrlController.dispose();
    _customPaymentTermController.dispose();
    super.dispose();
  }

  // Function to validate min and max price
  bool _validatePrices() {
    if (_minPriceController.text.isEmpty || _maxPriceController.text.isEmpty) {
      return false;
    }

    double minPrice = double.tryParse(_minPriceController.text) ?? 0;
    double maxPrice = double.tryParse(_maxPriceController.text) ?? 0;

    if (minPrice > maxPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Minimum price cannot be greater than maximum price'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> requestPermission() async {
    if (await Permission.photos.isDenied) {
      await Permission.photos.request();
    }

    if (await Permission.photos.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  // Pick images from gallery
  Future<void> _pickImages() async {
    await requestPermission();
    final ImagePicker picker = ImagePicker();
    final List<XFile> pickedImages = await picker.pickMultiImage(
      imageQuality: 80,
    );

    if (pickedImages.isNotEmpty) {
      if (_selectedImages.length + pickedImages.length > 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 3 images allowed')),
        );
        return;
      }

      setState(() {
        for (var image in pickedImages) {
          _selectedImages.add(File(image.path));
        }
      });
    }
  }

  // Pick test report PDF
  Future<void> _pickTestReport() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _selectedTestReportFile = File(result.files.single.path!);
        _selectedTestReportUrl = null; // Clear previous URL if any
      });
    }
  }

  // Upload images to Firebase Storage
  Future<List<String>> _uploadImages() async {
    List<String> imageUrls = [];

    // Keep existing URLs
    for (var image in _selectedImages) {
      if (image is String) {
        imageUrls.add(image);
      }
    }

    // Upload new images
    for (var image in _selectedImages) {
      if (image is File) {
        String fileName = '${_uuid.v4()}${path.extension(image.path)}';
        Reference ref = _storage.ref().child('products/images/$fileName');

        try {
          await ref.putFile(image);
          String downloadUrl = await ref.getDownloadURL();
          imageUrls.add(downloadUrl);
        } catch (e) {
          print('Error uploading image: $e');
          throw Exception('Failed to upload image');
        }
      }
    }

    return imageUrls;
  }

  // Upload test report to Firebase Storage
  Future<String?> _uploadTestReport() async {
    // Return existing URL if no new file was selected
    if (_selectedTestReportFile == null) {
      return _selectedTestReportUrl;
    }

    String fileName = '${_uuid.v4()}.pdf';
    Reference ref = _storage.ref().child('products/reports/$fileName');

    try {
      await ref.putFile(_selectedTestReportFile!);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading test report: $e');
      throw Exception('Failed to upload test report');
    }
  }

  // Save product to Firestore
  Future<void> _saveProduct(BuildContext context) async {
    // Store a mounted flag to check if widget is still mounted before using context
    final bool isMounted = mounted;

    // Validate the form and check min/max price relationship
    if (!_formKey.currentState!.validate() || !_validatePrices()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload images and test report
      List<String> imageUrls = await _uploadImages();
      String? testReportUrl = await _uploadTestReport();

      // Determine payment terms value
      String paymentTerms = _selectedPaymentTerm;
      if (_selectedPaymentTerm == 'Other') {
        paymentTerms = _customPaymentTermController.text;
      }

      // Get user email safely
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userEmail = userProvider.currentUser?.email ?? '';

      // Create or update product
      Product product = Product(
        id: widget.product?.id ?? _uuid.v4(),
        email: userEmail,
        name: _titleController.text,
        description: _descriptionController.text,
        minPrice: double.parse(_minPriceController.text),
        maxPrice: double.parse(_maxPriceController.text),
        priceUnit: _priceUnit,
        shippingTerm: _shippingTerm,
        countryOfOrigin: _countryOfOrigin,
        paymentTerms: paymentTerms,
        dispatchPort: _dispatchPortController.text,
        transitTime: _transitTimeController.text,
        videoUrl: _videoUrlController.text,
        imageUrls: imageUrls,
        testReportUrl: testReportUrl,
        buyerInspection: _buyerInspection,
        createdAt: widget.product?.createdAt ?? Timestamp.now(),
        updatedAt: Timestamp.now(),
        verified:false,
      );

      // Save to Firestore
      await _firestore.collection('products').doc(product.id).set(product.toMap());

      // Only show success message if widget is still mounted
      if (isMounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.product != null ? 'Product updated successfully' : 'Product added successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error saving product: $e');
      // Only show error message if widget is still mounted
      if (isMounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save product')),
        );
      }
    } finally {
      // Only update state if widget is still mounted
      if (isMounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  // Show an enhanced preview
  void _showPreview() {
    // Validate the form and check min/max price relationship
    if (!_formKey.currentState!.validate() || !_validatePrices()) {
      return;
    }

    // Determine payment terms for preview
    String paymentTerms = _selectedPaymentTerm;
    if (_selectedPaymentTerm == 'Other') {
      paymentTerms = _customPaymentTermController.text;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Product Preview',
                    style: AppTextStyles.heading.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Images
                      if (_selectedImages.isNotEmpty)
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedImages.length,
                            itemBuilder: (context, index) {
                              return Container(
                                width: 200,
                                height: 200,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: _selectedImages[index] is File
                                        ? FileImage(_selectedImages[index] as File) as ImageProvider
                                        : NetworkImage(_selectedImages[index].toString()),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Title
                      Text(
                        _titleController.text,
                        style: AppTextStyles.heading.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      // Price
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Price: \$${_minPriceController.text} - \$${_maxPriceController.text} $_priceUnit',
                          style: AppTextStyles.subtitle.copyWith(color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      Text('Description:', style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(_descriptionController.text),
                      const SizedBox(height: 16),

                      // Details
                      Text('Details:', style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      _buildDetailRow('Shipping Term', _shippingTerm),
                      _buildDetailRow('Country of Origin', _countryOfOrigin),
                      _buildDetailRow('Payment Terms', paymentTerms),
                      _buildDetailRow('Dispatch Port', _dispatchPortController.text),
                      _buildDetailRow('Transit Time', _transitTimeController.text),
                      _buildDetailRow('Buyer Inspection', _buyerInspection ? 'Yes' : 'No'),

                      // Test Report
                      if (_selectedTestReportFile != null || _selectedTestReportUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Row(
                            children: [
                              const Icon(Icons.description, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Test Report Available',
                                style: AppTextStyles.body.copyWith(color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Buttons
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Edit'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _saveProduct(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: Text(widget.product != null ? 'Update' : 'Save'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Product' : 'Add New Product'),
          elevation: 0,
        ),
        body: _isLoading
            ? Center(child: Container(
          color: Colors.white.withOpacity(0.7),
          width: double.infinity,
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(!isEditing?"Adding product...":"Updating product...",
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ))
            : Form(
            key: _formKey,
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    // Title
                    Text('Product Title', style: AppTextStyles.subtitle),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _titleController,
                  labelText: 'Enter product title',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Description
                Text('Description', style: AppTextStyles.subtitle),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _descriptionController,
                  labelText: 'Enter product description',
                  // maxLines: 4,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Images
                Text('Product Images (Max 3)', style: AppTextStyles.subtitle),
                const SizedBox(height: 8),
                Container(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // Display selected images
                      for (var i = 0; i < _selectedImages.length; i++)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: _selectedImages[i] is File
                                  ? FileImage(_selectedImages[i] as File) as ImageProvider
                                  : NetworkImage(_selectedImages[i].toString()),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.topRight,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _selectedImages.removeAt(i);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                      // Add image button
                      if (_selectedImages.length < 3)
                        GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.add_photo_alternate,
                              size: 40,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Video URL
                Text('Video URL (Optional)', style: AppTextStyles.subtitle),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _videoUrlController,
                  labelText: 'Enter video URL',
                ),
                const SizedBox(height: 24),

                // Price Range
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Min Price (\$)', style: AppTextStyles.subtitle),
                          const SizedBox(height: 8),
                          CustomTextField(
                            controller: _minPriceController,
                            labelText: 'Min',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              // Check if it's a valid number
                              if (double.tryParse(value) == null) {
                                return 'Invalid number';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Max Price (\$)', style: AppTextStyles.subtitle),
                          const SizedBox(height: 8),
                          CustomTextField(
                            controller: _maxPriceController,
                            labelText: 'Max',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              // Check if it's a valid number
                              if (double.tryParse(value) == null) {
                                return 'Invalid number';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Price Unit
                Text('Price Unit', style: AppTextStyles.subtitle),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _priceUnit,
                      isExpanded: true,
                      items: _priceUnits.map((String unit) {
                        return DropdownMenuItem<String>(
                          value: unit,
                          child: Text(unit),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _priceUnit = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Shipping Term
                Text('Shipping Term', style: AppTextStyles.subtitle),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _shippingTerm,
                      isExpanded: true,
                      items: _shippingTerms.map((String term) {
                        return DropdownMenuItem<String>(
                          value: term,
                          child: Text(term),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _shippingTerm = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Country of Origin
                Text('Country of Origin', style: AppTextStyles.subtitle),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _countryOfOrigin,
                      isExpanded: true,
                      items: _countries.map((String country) {
                        return DropdownMenuItem<String>(
                          value: country,
                          child: Text(country),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _countryOfOrigin = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Payment Terms - REPLACED with dropdown + optional text field
                Text('Payment Terms', style: AppTextStyles.subtitle),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedPaymentTerm,
                      isExpanded: true,
                      items: _paymentTerms.map((String term) {
                        return DropdownMenuItem<String>(
                          value: term,
                          child: Text(term),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedPaymentTerm = newValue;
                            _showCustomPaymentTermField = (newValue == 'Other');
                          });
                        }
                      },
                    ),
                  ),
                ),

                // Custom Payment Terms field (shown only when "Other" is selected)
                if (_showCustomPaymentTermField) ...[
            const SizedBox(height: 16),
        CustomTextField(
          controller: _customPaymentTermController,
          labelText: 'Enter custom payment terms',
          validator: _selectedPaymentTerm == 'Other' ? (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter payment terms';
            }
            return null;
          } : null,
        ),
        ],
        const SizedBox(height: 24),
        // Dispatch Port
        Text('Dispatch Port', style: AppTextStyles.subtitle),
        const SizedBox(height: 8),
        CustomTextField(
          controller: _dispatchPortController,
          labelText: 'Enter port name',
        ),
        const SizedBox(height: 24),
        // Test Report
        Text('Fresh Test Report (PDF)', style: AppTextStyles.subtitle),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _selectedTestReportFile != null
                  ? path.basename(_selectedTestReportFile!.path)
                      : _selectedTestReportUrl != null
                  ? 'Test Report PDF (Already uploaded)'
                      : 'No file selected',
                  style: (_selectedTestReportFile == null && _selectedTestReportUrl == null)
                  ? AppTextStyles.body.copyWith(color: AppColors.textSecondary)
                      : AppTextStyles.body,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _pickTestReport,
              icon: const Icon(Icons.upload_file, color: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Transit Time
        Text('Transit Time (Optional)', style: AppTextStyles.subtitle),
        const SizedBox(height: 8),
        CustomTextField(
          controller: _transitTimeController,
          labelText: 'e.g., 15-20 days',
        ),
        const SizedBox(height: 24),

        // Buyer Inspection
        Text('Buyer Inspection', style: AppTextStyles.subtitle),
        const SizedBox(height: 8),
        Row(
        children: [
        Expanded(
        child: RadioListTile<bool>(
        title: const Text('Yes'),
        value: true,
        groupValue: _buyerInspection,
        onChanged: (bool? value) {
        if (value != null) {
        setState(() {
        _buyerInspection = value;
        });
        }
        },
        ),
        ),
        Expanded(
        child: RadioListTile<bool>(
        title: const Text('No'),
        value: false,
        groupValue: _buyerInspection,
        onChanged: (bool? value) {
        if (value != null) {
        setState(() {
        _buyerInspection = value;
        });
        }
        },
        ),
        ),
        ],
        ),
        const SizedBox(height: 32),

        // Preview and Save buttons
        Row(
        children: [
        Expanded(
        child: CustomButton(
        text: 'Preview',
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _showPreview();
            }
          },
          // buttonColor: Colors.grey.shade200,
          // textColor: AppColors.textPrimary,
        ),
        ),
          const SizedBox(width: 16),
          Expanded(
            child: CustomButton(
              text: isEditing ? 'Update' : 'Save',
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _saveProduct(context);
                }
              },
              // buttonColor: AppColors.primary,
              // textColor: Colors.white,
            ),
          ),
        ],
        ),
                          const SizedBox(height: 24),
                        ],
                    ),
                ),
            ),
        );
  }
}