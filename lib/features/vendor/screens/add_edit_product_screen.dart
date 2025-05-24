import 'dart:io';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:e_commerce_app/core/providers/user_provider.dart';
import 'package:e_commerce_app/features/vendor/screens/vendor_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import 'package:another_flushbar/flushbar.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/hsCodeSearch_widget.dart';
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

  String? _hsCode;
  String? _hsProduct;
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
      _hsCode = widget.product?.hsCode;
      _hsProduct = widget.product?.hsProduct;
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

  // Enhanced Flushbar helper methods
  void _showSuccessFlushbar(String message) {
    if (!mounted) return;

    Flushbar(
      message: message,
      icon: Icon(
        Icons.check_circle,
        color: Colors.white,
        size: 24,
      ),
      duration: Duration(seconds: 3),
      leftBarIndicatorColor: Colors.green,
      backgroundColor: Colors.green.shade600,
      borderRadius: BorderRadius.circular(12),
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      messageColor: Colors.white,
      messageSize: 14,
      animationDuration: Duration(milliseconds: 300),
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
    ).show(context);
  }

  void _showErrorFlushbar(String message, {String? title}) {
    if (!mounted) return;

    Flushbar(
      title: title,
      message: message,
      icon: Icon(
        Icons.error_outline,
        color: Colors.white,
        size: 24,
      ),
      duration: Duration(seconds: 4),
      leftBarIndicatorColor: Colors.red,
      backgroundColor: Colors.red.shade600,
      borderRadius: BorderRadius.circular(12),
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      titleColor: Colors.white,
      messageColor: Colors.white,
      titleSize: 16,
      messageSize: 14,
      animationDuration: Duration(milliseconds: 300),
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
    ).show(context);
  }

  void _showWarningFlushbar(String message) {
    if (!mounted) return;

    Flushbar(
      message: message,
      icon: Icon(
        Icons.warning_amber,
        color: Colors.white,
        size: 24,
      ),
      duration: Duration(seconds: 3),
      leftBarIndicatorColor: Colors.orange,
      backgroundColor: Colors.orange.shade600,
      borderRadius: BorderRadius.circular(12),
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      messageColor: Colors.white,
      messageSize: 14,
      animationDuration: Duration(milliseconds: 300),
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
    ).show(context);
  }

  void _showInfoFlushbar(String message) {
    if (!mounted) return;

    Flushbar(
      message: message,
      icon: Icon(
        Icons.info_outline,
        color: Colors.white,
        size: 24,
      ),
      duration: Duration(seconds: 3),
      leftBarIndicatorColor: Colors.blue,
      backgroundColor: Colors.blue.shade600,
      borderRadius: BorderRadius.circular(12),
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      messageColor: Colors.white,
      messageSize: 14,
      animationDuration: Duration(milliseconds: 300),
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
    ).show(context);
  }

  // Enhanced validation with comprehensive error handling
  bool _validateForm() {
    try {
      // Basic form validation
      if (!_formKey.currentState!.validate()) {
        _showErrorFlushbar('Please fill in all required fields', title: 'Validation Error');
        return false;
      }

      // Title validation
      if (_titleController.text.trim().isEmpty) {
        _showErrorFlushbar('Product title cannot be empty');
        return false;
      }

      if (_titleController.text.trim().length < 3) {
        _showErrorFlushbar('Product title must be at least 3 characters long');
        return false;
      }

      if (_titleController.text.trim().length > 100) {
        _showErrorFlushbar('Product title cannot exceed 100 characters');
        return false;
      }

      // Description validation
      if (_descriptionController.text.trim().isEmpty) {
        _showErrorFlushbar('Product description cannot be empty');
        return false;
      }

      if (_descriptionController.text.trim().length < 10) {
        _showErrorFlushbar('Product description must be at least 10 characters long');
        return false;
      }

      if (_descriptionController.text.trim().length > 1000) {
        _showErrorFlushbar('Product description cannot exceed 1000 characters');
        return false;
      }

      // Price validation
      if (!_validatePrices()) {
        return false;
      }

      // HS Code validation
      if (_hsCode == null || _hsCode!.trim().isEmpty) {
        _showErrorFlushbar('Please select a valid HS Code');
        return false;
      }

      // Images validation
      if (_selectedImages.isEmpty) {
        _showWarningFlushbar('Consider adding at least one product image for better visibility');
        return false;
      }

      // Payment terms validation
      if (_selectedPaymentTerm == 'Other' && _customPaymentTermController.text.trim().length < 2) {
        _showErrorFlushbar('Please enter custom payment terms');
        return false;
      }

      // Dispatch port validation
      if (_dispatchPortController.text.trim().isNotEmpty && _dispatchPortController.text.trim().length < 2) {
        _showErrorFlushbar('Dispatch port name must be at least 2 characters long');
        return false;
      }

      // Video URL validation
      if (_videoUrlController.text.trim().isNotEmpty) {
        final urlPattern = r'^https?:\/\/.+';
        if (!RegExp(urlPattern).hasMatch(_videoUrlController.text.trim())) {
          _showErrorFlushbar('Please enter a valid video URL (must start with http:// or https://)');
          return false;
        }
      }

      return true;
    } catch (e) {
      _showErrorFlushbar('Validation error: ${e.toString()}', title: 'Unexpected Error');
      return false;
    }
  }

  // Enhanced price validation
  bool _validatePrices() {
    try {
      if (_minPriceController.text.trim().isEmpty || _maxPriceController.text.trim().isEmpty) {
        _showErrorFlushbar('Both minimum and maximum prices are required');
        return false;
      }

      double? minPrice = double.tryParse(_minPriceController.text.trim());
      double? maxPrice = double.tryParse(_maxPriceController.text.trim());

      if (minPrice == null) {
        _showErrorFlushbar('Minimum price must be a valid number');
        return false;
      }

      if (maxPrice == null) {
        _showErrorFlushbar('Maximum price must be a valid number');
        return false;
      }

      if (minPrice <= 0) {
        _showErrorFlushbar('Minimum price must be greater than 0');
        return false;
      }

      if (maxPrice <= 0) {
        _showErrorFlushbar('Maximum price must be greater than 0');
        return false;
      }

      if (minPrice > maxPrice) {
        _showErrorFlushbar('Minimum price cannot be greater than maximum price');
        return false;
      }

      if (maxPrice > 1000000) {
        _showWarningFlushbar('Maximum price seems unusually high. Please verify.');
      }

      return true;
    } catch (e) {
      _showErrorFlushbar('Error validating prices: ${e.toString()}');
      return false;
    }
  }

  Future<void> requestPermission() async {
    try {
      if (await Permission.photos.isDenied) {
        await Permission.photos.request();
      }

      if (await Permission.photos.isPermanentlyDenied) {
        _showErrorFlushbar('Photo permission is required. Please enable it in app settings.');
        openAppSettings();
      }
    } catch (e) {
      _showErrorFlushbar('Error requesting permission: ${e.toString()}');
    }
  }

  // Enhanced image picker with comprehensive error handling
  Future<void> _pickImages() async {
    try {
      await requestPermission();

      final ImagePicker picker = ImagePicker();
      final List<XFile> pickedImages = await picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (pickedImages.isEmpty) {
        return;
      }

      if (_selectedImages.length + pickedImages.length > 3) {
        _showWarningFlushbar('Maximum 3 images allowed');

        int remainingSlots = 3 - _selectedImages.length;
        for (int i = 0; i < remainingSlots && i < pickedImages.length; i++) {
          File imageFile = File(pickedImages[i].path);

          // Check file size (max 5MB)
          int fileSizeInBytes = await imageFile.length();
          double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

          if (fileSizeInMB > 5) {
            _showWarningFlushbar('Image ${i + 1} is too large (${fileSizeInMB.toStringAsFixed(1)}MB). Maximum size is 5MB.');
            continue;
          }

          setState(() {
            _selectedImages.add(imageFile);
          });
        }
      } else {
        for (var image in pickedImages) {
          File imageFile = File(image.path);

          // Check file size (max 5MB)
          int fileSizeInBytes = await imageFile.length();
          double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

          if (fileSizeInMB > 5) {
            _showWarningFlushbar('Image is too large (${fileSizeInMB.toStringAsFixed(1)}MB). Maximum size is 5MB.');
            continue;
          }

          setState(() {
            _selectedImages.add(imageFile);
          });
        }

        if (pickedImages.length == 1) {
          _showInfoFlushbar('Image added successfully');
        } else {
          _showInfoFlushbar('${pickedImages.length} images added successfully');
        }
      }
    } catch (e) {
      _showErrorFlushbar('Error picking images: ${e.toString()}');
    }
  }

  // Enhanced test report picker
  Future<void> _pickTestReport() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        File selectedFile = File(result.files.single.path!);

        // Check file size (max 10MB for PDF)
        int fileSizeInBytes = await selectedFile.length();
        double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

        if (fileSizeInMB > 10) {
          _showErrorFlushbar('PDF file is too large (${fileSizeInMB.toStringAsFixed(1)}MB). Maximum size is 10MB.');
          return;
        }

        setState(() {
          _selectedTestReportFile = selectedFile;
          _selectedTestReportUrl = null; // Clear previous URL if any
        });

        _showInfoFlushbar('Test report selected successfully');
      }
    } catch (e) {
      _showErrorFlushbar('Error selecting test report: ${e.toString()}');
    }
  }

  // Enhanced image upload with error handling
  Future<List<String>> _uploadImages() async {
    List<String> imageUrls = [];

    try {
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
            TaskSnapshot uploadTask = await ref.putFile(image);

            if (uploadTask.state == TaskState.success) {
              String downloadUrl = await ref.getDownloadURL();
              imageUrls.add(downloadUrl);
            } else {
              throw Exception('Upload failed with state: ${uploadTask.state}');
            }
          } catch (e) {
            print('Error uploading individual image: $e');
            throw Exception('Failed to upload image: ${path.basename(image.path)}');
          }
        }
      }

      return imageUrls;
    } catch (e) {
      print('Error uploading images: $e');
      throw Exception('Failed to upload images: ${e.toString()}');
    }
  }

  // Enhanced test report upload
  Future<String?> _uploadTestReport() async {
    try {
      // Return existing URL if no new file was selected
      if (_selectedTestReportFile == null) {
        return _selectedTestReportUrl;
      }

      String fileName = '${_uuid.v4()}.pdf';
      Reference ref = _storage.ref().child('products/reports/$fileName');

      TaskSnapshot uploadTask = await ref.putFile(_selectedTestReportFile!);

      if (uploadTask.state == TaskState.success) {
        return await ref.getDownloadURL();
      } else {
        throw Exception('Upload failed with state: ${uploadTask.state}');
      }
    } catch (e) {
      print('Error uploading test report: $e');
      throw Exception('Failed to upload test report: ${e.toString()}');
    }
  }

  // Enhanced save product with comprehensive error handling
  Future<void> _saveProduct(BuildContext context) async {
    try {
      // Validate the form
      if (!_validateForm()) {
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // Check network connectivity (basic check)
      try {
        await _firestore.enableNetwork();
      } catch (e) {
        throw Exception('No internet connection. Please check your network and try again.');
      }

      // Get user email safely
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userEmail = userProvider.currentUser?.email;

      if (userEmail == null || userEmail.isEmpty) {
        throw Exception('User not authenticated. Please log in again.');
      }

      // Upload images and test report
      List<String> imageUrls = [];
      String? testReportUrl;

      try {
        imageUrls = await _uploadImages();
      } catch (e) {
        throw Exception('Failed to upload images: ${e.toString()}');
      }

      try {
        testReportUrl = await _uploadTestReport();
      } catch (e) {
        throw Exception('Failed to upload test report: ${e.toString()}');
      }

      // Determine payment terms value
      String paymentTerms = _selectedPaymentTerm;
      if (_selectedPaymentTerm == 'Other') {
        paymentTerms = _customPaymentTermController.text.trim();
      }

      // Create or update product
      Product product = Product(
        id: widget.product?.id ?? _uuid.v4(),
        email: userEmail,
        name: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        hsCode: _hsCode ?? '',
        hsProduct: _hsProduct ?? '',
        minPrice: double.parse(_minPriceController.text.trim()),
        maxPrice: double.parse(_maxPriceController.text.trim()),
        priceUnit: _priceUnit,
        shippingTerm: _shippingTerm,
        countryOfOrigin: _countryOfOrigin,
        paymentTerms: paymentTerms,
        dispatchPort: _dispatchPortController.text.trim(),
        transitTime: _transitTimeController.text.trim(),
        videoUrl: _videoUrlController.text.trim(),
        imageUrls: imageUrls,
        testReportUrl: testReportUrl,
        buyerInspection: _buyerInspection,
        createdAt: widget.product?.createdAt ?? Timestamp.now(),
        updatedAt: Timestamp.now(),
        verification: "Pending",
      );

      // Save to Firestore
      await _firestore.collection('products').doc(product.id).set(product.toMap());

      // Only show success message if widget is still mounted
      if (mounted) {
        _showSuccessFlushbar(widget.product != null ? 'Product updated successfully!' : 'Product added successfully!');

        // Delay navigation to show the success message
        // await Future.delayed(Duration(milliseconds: 1500));

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => VendorHomeScreen(flushbarMessage: widget.product != null
                  ? 'Product updated successfully!'
                  : 'Product added successfully!',), // Replace with your actual widget
            ),
          );        }
      }
    } catch (e) {
      print('Error saving product: $e');
      // Only show error message if widget is still mounted
      if (mounted) {
        _showErrorFlushbar(e.toString(), title: 'Save Failed');
      }
    } finally {
      // Only update state if widget is still mounted
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Enhanced and sleek preview dialog
  void _showPreview() {
    if (!_validateForm()) {
      return;
    }

    // Determine payment terms for preview
    String paymentTerms = _selectedPaymentTerm;
    if (_selectedPaymentTerm == 'Other') {
      paymentTerms = _customPaymentTermController.text.trim();
    }

    final screenWidth = MediaQuery.of(context).size.width;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          width: screenWidth > 600 ? 800 : screenWidth * 0.95,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Modern header with gradient
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Product Preview',
                      style: AppTextStyles.heading.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                        splashRadius: 10,
                      ),
                    ),
                  ],
                ),
              ),

              // Content with enhanced scrolling
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Enhanced images carousel with indicators
                      if (_selectedImages.isNotEmpty) ...[
                        Container(
                          height: 250,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              children: [
                                PageView.builder(
                                  itemCount: _selectedImages.length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      decoration: BoxDecoration(
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
                                // Image count indicator
                                if (_selectedImages.length > 1)
                                  Positioned(
                                    bottom: 16,
                                    right: 16,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.image, color: Colors.white, size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${_selectedImages.length}',
                                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                // Swipe indicator dots
                                if (_selectedImages.length > 1)
                                  Positioned(
                                    bottom: 16,
                                    left: 0,
                                    right: 0,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: List.generate(
                                        _selectedImages.length > 5 ? 3 : _selectedImages.length,
                                            (index) {
                                          if (_selectedImages.length > 5 && index == 2) {
                                            return Container(
                                              margin: const EdgeInsets.symmetric(horizontal: 2),
                                              child: const Text('...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                            );
                                          }
                                          return Container(
                                            margin: const EdgeInsets.symmetric(horizontal: 2),
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.7),
                                              shape: BoxShape.circle,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Product title with enhanced styling
                      Container(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _titleController.text,
                          style: AppTextStyles.heading.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                            color: AppColors.primary,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildModernDetailGrid([
                        _buildModernDetailCard('Price', '\$${_minPriceController.text} - \$${_maxPriceController.text} $_priceUnit', Icons.monetization_on_outlined, AppColors.tertiary),
                        _buildModernDetailCard('Description', _descriptionController.text, Icons.description, AppColors.tertiary),
                        _buildModernDetailCard('Video', _videoUrlController.text, Icons.video_call,AppColors.tertiary),
                        _buildModernDetailCard(
                          'HS Code',
                          '${_hsCode ?? ''} - ${_hsProduct != null && _hsProduct!.length > 40 ? _hsProduct!.substring(0, 40) + '...' : _hsProduct ?? ''}',
                          Icons.qr_code,
                          AppColors.tertiary,
                        ),
                      ]),
                      const SizedBox(height: 32),
                      // Product specifications with modern cards
                      _buildModernSectionTitle('Product Specifications', Icons.inventory),
                      const SizedBox(height: 16),
                      _buildModernDetailGrid([
                        _buildModernDetailCard('Shipping Term', _shippingTerm, Icons.local_shipping, AppColors.tertiary),
                        _buildModernDetailCard('Country of Origin', _countryOfOrigin, Icons.public,AppColors.tertiary),
                        _buildModernDetailCard('Payment Terms', paymentTerms, Icons.payment,AppColors.tertiary),
                        _buildModernDetailCard('Dispatch Port', _dispatchPortController.text, Icons.directions_boat, AppColors.tertiary),
                        _buildModernDetailCard('Transit Time', _transitTimeController.text, Icons.timelapse,AppColors.tertiary),
                        _buildModernDetailCard('Buyer Inspection', _buyerInspection ? 'Yes' : 'No', Icons.visibility,AppColors.tertiary),
                      ]),
                      // Test Report section with enhanced styling

                      if (_selectedTestReportFile != null || (_selectedTestReportUrl != null && _selectedTestReportUrl!.isNotEmpty)) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            // gradient: LinearGradient(
                            //   colors: [Colors.green[50], Colors.green[25]],
                            //   begin: Alignment.topLeft,
                            //   end: Alignment.bottomRight,
                            // ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.green[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.verified, color: Colors.green, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Test Report Available',
                                      style: AppTextStyles.subtitle.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.green[800],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (_selectedTestReportFile != null)
                                      Text(
                                        _selectedTestReportFile!.path.split('/').last,
                                        style: AppTextStyles.caption.copyWith(color: Colors.green[600]),
                                      ),
                                    if (_selectedTestReportUrl != null)
                                      Text(
                                        _selectedTestReportUrl!,
                                        style: AppTextStyles.caption.copyWith(color: Colors.green[600]),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: AppTextStyles.heading.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildModernDetailGrid(List<Widget> cards) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cards,
    );
  }

  Widget _buildModernDetailCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: (MediaQuery.of(context).size.width > 600) ? 240 : double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value.isNotEmpty ? value : 'Not specified',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              color: value.isNotEmpty ? Colors.grey[800] : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.subtitle.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? 'N/A' : value,
                  style: AppTextStyles.body,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Method to show flushbar notifications
  void _showFlushbar(BuildContext context, String message, {bool isError = false}) {
    Flushbar(
      message: message,
      duration: const Duration(seconds: 3),
      backgroundColor: isError ? Colors.red : Colors.green,
      borderRadius: BorderRadius.circular(8),
      margin: const EdgeInsets.all(16),
      flushbarPosition: FlushbarPosition.TOP,
      icon: Icon(
        isError ? Icons.error : Icons.check_circle,
        color: Colors.white,
      ),
      leftBarIndicatorColor: isError ? Colors.redAccent : Colors.greenAccent,
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return Scaffold(
      backgroundColor: AppColors.lightTertiary,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Product' : 'Add New Product',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.lightTertiary,
        foregroundColor: Colors.black87,
        elevation: 0,
        shadowColor: Colors.black12,
        surfaceTintColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Container(
        color: Colors.white.withOpacity(0.95),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      !isEditing ? "Adding product..." : "Updating product...",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      )
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Title Section
              _buildSectionCard(
                title: 'Product Information',
                icon: Icons.inventory_2_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Product Title'),
                    SizedBox(height: 8),
                    _buildStyledTextField(
                      controller: _titleController,
                      hintText: 'Enter product title',
                      // prefixIcon: Icons.title,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    _buildFieldLabel('Description'),
                    SizedBox(height: 8),
                    _buildStyledTextField(
                      controller: _descriptionController,
                      hintText: 'Enter product description',
                      // prefixIcon: Icons.description,
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    HSCodeSearchWidget(
                      initialValue: _hsCode,
                      labelText: 'HS Code',
                      hintText: 'Select HS Code',
                      onChanged: (hsCodeModel) {
                        if (hsCodeModel != null) {
                          setState(() {
                            _hsCode = hsCodeModel.hscode;
                            _hsProduct = hsCodeModel.description;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Media Section
              _buildSectionCard(
                title: 'Product Media',
                icon: Icons.photo_library_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Product Images (Max 3)'),
                    SizedBox(height: 12),
                    Container(
                      height: 120,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // Display selected images
                          for (var i = 0; i < _selectedImages.length; i++)
                            Container(
                              margin: EdgeInsets.only(right: 12),
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image(
                                      image: _selectedImages[i] is File
                                          ? FileImage(_selectedImages[i] as File) as ImageProvider
                                          : NetworkImage(_selectedImages[i].toString()),
                                      fit: BoxFit.cover,
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedImages.removeAt(i);
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Add image button
                          if (_selectedImages.length < 3)
                            GestureDetector(
                              onTap: _pickImages,
                              child: Container(
                                width: 100,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.3),
                                    width: 2,
                                    style: BorderStyle.solid,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 32,
                                      color: AppColors.primary,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Add Photo',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),

                    _buildFieldLabel('Video URL (Optional)'),
                    SizedBox(height: 8),
                    _buildStyledTextField(
                      controller: _videoUrlController,
                      hintText: 'Enter video URL',
                      prefixIcon: Icons.videocam_outlined,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Pricing Section
              _buildSectionCard(
                title: 'Pricing Information',
                icon: Icons.attach_money_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Min Price (\$)'),
                              SizedBox(height: 8),
                              _buildStyledTextField(
                                controller: _minPriceController,
                                hintText: 'Min',
                                prefixIcon: Icons.monetization_on_outlined,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required min price';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Invalid number';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Max Price (\$)'),
                              SizedBox(height: 8),
                              _buildStyledTextField(
                                controller: _maxPriceController,
                                hintText: 'Max',
                                prefixIcon: Icons.monetization_on_outlined,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required max price';
                                  }
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
                    SizedBox(height: 20),

                    _buildFieldLabel('Price Unit'),
                    SizedBox(height: 8),
                    _buildStyledDropdown(
                      value: _priceUnit,
                      items: _priceUnits,
                      hintText: 'Select price unit',
                      prefixIcon: Icons.scale_outlined,
                      onChanged: (value) {
                        setState(() {
                          _priceUnit = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Shipping & Terms Section
              _buildSectionCard(
                title: 'Shipping & Terms',
                icon: Icons.local_shipping_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Shipping Term'),
                    SizedBox(height: 8),
                    _buildStyledDropdown(
                      value: _shippingTerm,
                      items: _shippingTerms,
                      hintText: 'Select shipping term',
                      prefixIcon: Icons.local_shipping_outlined,
                      onChanged: (value) {
                        setState(() {
                          _shippingTerm = value!;
                        });
                      },
                    ),
                    SizedBox(height: 20),

                    _buildFieldLabel('Country of Origin'),
                    SizedBox(height: 8),
                    _buildStyledDropdown(
                      value: _countryOfOrigin,
                      items: _countries,
                      hintText: 'Select country',
                      prefixIcon: Icons.public_outlined,
                      onChanged: (value) {
                        setState(() {
                          _countryOfOrigin = value!;
                        });
                      },
                    ),
                    SizedBox(height: 20),

                    _buildFieldLabel('Payment Terms'),
                    SizedBox(height: 8),
                    _buildStyledDropdown(
                      value: _selectedPaymentTerm,
                      items: _paymentTerms,
                      hintText: 'Select payment terms',
                      prefixIcon: Icons.payment_outlined,
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentTerm = value!;
                          _showCustomPaymentTermField = (_selectedPaymentTerm == "Other");
                        });
                      },
                    ),

                    if (_showCustomPaymentTermField) ...[
                      SizedBox(height: 16),
                      _buildStyledTextField(
                        controller: _customPaymentTermController,
                        hintText: 'Enter custom payment terms',
                        prefixIcon: Icons.edit_outlined,
                        validator: _selectedPaymentTerm == 'Other' ? (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter payment terms';
                          }
                          return null;
                        } : null,
                      ),
                    ],
                    SizedBox(height: 20),

                    _buildFieldLabel('Dispatch Port'),
                    SizedBox(height: 8),
                    _buildStyledTextField(
                      controller: _dispatchPortController,
                      hintText: 'Enter port name',
                      prefixIcon: Icons.directions_boat_outlined,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Additional Information Section
              _buildSectionCard(
                title: 'Additional Information',
                icon: Icons.info_outline,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Fresh Test Report (PDF)'),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.upload_file_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          _selectedTestReportFile != null
                              ? path.basename(_selectedTestReportFile!.path)
                              : _selectedTestReportUrl != null
                              ? 'Test Report PDF (Already uploaded)'
                              : 'No file selected',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: (_selectedTestReportFile == null && _selectedTestReportUrl == null)
                                ? Colors.grey[600]
                                : Colors.black87,
                          ),
                        ),
                        trailing: IconButton(
                          onPressed: _pickTestReport,
                          icon: Icon(
                            Icons.folder_open_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    _buildFieldLabel('Transit Time (Optional)'),
                    SizedBox(height: 8),
                    _buildStyledTextField(
                      controller: _transitTimeController,
                      hintText: 'e.g., 15-20 days',
                      prefixIcon: Icons.schedule_outlined,
                    ),
                    SizedBox(height: 20),

                    _buildFieldLabel('Buyer Inspection'),
                    SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              title: Text('Yes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              value: true,
                              groupValue: _buyerInspection,
                              activeColor: AppColors.primary,
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
                              title: Text('No', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              value: false,
                              groupValue: _buyerInspection,
                              activeColor: AppColors.primary,
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
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32),

              // Action Buttons
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        text: 'Preview',
                        icon: Icons.visibility_outlined,
                        isPrimary: false,
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _showPreview();
                          }
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildActionButton(
                        text: isEditing ? 'Update' : 'Save',
                        icon: isEditing ? Icons.update_outlined : Icons.save_outlined,
                        isPrimary: true,
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _saveProduct(context);
                          }
                        },
                      ),
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

// Helper methods for building styled components
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.8),
            AppColors.secondary.withOpacity(0.8),
            AppColors.primary.withOpacity(0.8)
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(vertical: 8,horizontal: 0),
                decoration: BoxDecoration(
                  // color: AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppColors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String hintText,
    IconData? prefixIcon, // make it nullable
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        errorStyle: const TextStyle(
          color: Colors.redAccent, // or any bright color that pops on dark bg
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey[700],
          fontSize: 14,
        ),
        prefixIcon: prefixIcon != null
            ? Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            prefixIcon,
            color: AppColors.primary,
            size: 18,
          ),
        )
            : null,
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }


  Widget _buildStyledDropdown({
    required String value,
    required List<String> items,
    required String hintText,
    required IconData prefixIcon,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField2<String>(
      isExpanded: true,
      value: value,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey[500],
          fontSize: 14,
        ),
        prefixIcon: Container(
          margin: EdgeInsets.all(12),
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            prefixIcon,
            color: AppColors.primary,
            size: 18,
          ),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: items
          .map((item) => DropdownMenuItem<String>(
        value: item,
        child: Text(
          item,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ))
          .toList(),
      onChanged: onChanged,
      dropdownStyleData: DropdownStyleData(
        elevation: 8,
        offset: Offset(0, -4),
        maxHeight: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 18,
        color: isPrimary ? Colors.white : AppColors.primary,
      ),
      label: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isPrimary ? Colors.white : AppColors.primary,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? AppColors.primary : Colors.white,
        foregroundColor: isPrimary ? Colors.white : AppColors.primary,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isPrimary ? BorderSide.none : BorderSide(color: AppColors.primary),
        ),
        elevation: isPrimary ? 4 : 0,
        shadowColor: isPrimary ? AppColors.primary.withOpacity(0.3) : Colors.transparent,
      ),
    );
  }}