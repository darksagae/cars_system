
class EnhancedProductFormScreen extends StatefulWidget {
  final Product? product;

  const EnhancedProductFormScreen({super.key, this.product});

  @override
  State<EnhancedProductFormScreen> createState() => _EnhancedProductFormScreenState();
}

class _EnhancedProductFormScreenState extends State<EnhancedProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _skuController = TextEditingController();
  final _priceController = TextEditingController();
  final _costController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();
  final _lowStockThresholdController = TextEditingController();
  final _unitController = TextEditingController();
  final _taxRateController = TextEditingController();
  final _barcodeController = TextEditingController();

  String _category = 'General';
  ProductStatus _selectedStatus = ProductStatus.active;
  bool _isActive = true;
  bool _isLoading = false;
  bool _isEdit = false;
  List<File> _selectedImages = [];
  String? _barcodeType;

  final BarcodeScannerService _barcodeService = BarcodeScannerService();
  final ImagePickerService _imageService = ImagePickerService();

  final List<String> _categories = [
    'General',
    'Electronics',
    'Clothing',
    'Books',
    'Food',
    'Tools',
    'Furniture',
    'Health & Beauty',
    'Sports',
    'Toys',
    'Automotive',
    'Office Supplies',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _isEdit = true;
      _initializeForm();
    }
  }

  void _initializeForm() {
    final product = widget.product!;
    _nameController.text = product.name;
    _descriptionController.text = product.description;
    _skuController.text = product.sku;
    _priceController.text = product.price.toStringAsFixed(2);
    _costController.text = '0.0'; // Add cost field if needed
    _stockController.text = product.stock.toString();
    _minStockController.text = product.minStock.toString();
    _lowStockThresholdController.text = product.lowStockThreshold.toString();
    _unitController.text = product.unit;
    _taxRateController.text = product.taxRate.toStringAsFixed(2);
    _barcodeController.text = product.barcode ?? '';
    _barcodeType = product.barcodeType;
    _category = product.category;
    _selectedStatus = product.status;
    _isActive = product.isActive;
    
    // Load images if they exist
    if (product.images != null && product.images!.isNotEmpty) {
      // Convert image paths to File objects
      _selectedImages = product.images!.map((path) => File(path)).toList();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _lowStockThresholdController.dispose();
    _unitController.dispose();
    _taxRateController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEdit ? 'Edit Product' : 'Add Product',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.trash, color: Colors.red),
              onPressed: _deleteProduct,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildBasicInfo(),
                const SizedBox(height: 24),
                _buildBarcodeSection(),
                const SizedBox(height: 24),
                _buildImageSection(),
                const SizedBox(height: 24),
                _buildPricingSection(),
                const SizedBox(height: 24),
                _buildInventorySection(),
                const SizedBox(height: 24),
                _buildSettingsSection(),
                const SizedBox(height: 32),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEdit ? 'Edit Product' : 'Add New Product',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isEdit 
                ? 'Update product information and settings'
                : 'Create a new product with barcode and images',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _nameController,
            label: 'Product Name',
            icon: FontAwesomeIcons.tag,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter product name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _descriptionController,
            label: 'Description',
            icon: FontAwesomeIcons.alignLeft,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _skuController,
            label: 'SKU',
            icon: FontAwesomeIcons.barcode,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter SKU';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildCategoryDropdown(),
        ],
      ),
    );
  }

  Widget _buildBarcodeSection() {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Barcode Information',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _barcodeController,
                  label: 'Barcode',
                  icon: FontAwesomeIcons.barcode,
                  readOnly: true,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _scanBarcode,
                icon: const FaIcon(FontAwesomeIcons.qrcode, size: 16),
                label: Text(
                  'Scan',
                  style: GoogleFonts.poppins(),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlassLiquidTheme.accentBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          if (_barcodeType != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: GlassLiquidTheme.accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: GlassLiquidTheme.accentBlue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.infoCircle,
                    color: GlassLiquidTheme.accentBlue,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Barcode Type: $_barcodeType',
                    style: GoogleFonts.poppins(
                      color: GlassLiquidTheme.accentBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Product Images',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                '${_selectedImages.length}/5',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_selectedImages.isEmpty)
            _buildEmptyImageState()
          else
            _buildImageGrid(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickImages,
                  icon: const FaIcon(FontAwesomeIcons.image, size: 16),
                  label: Text(
                    'Add Images',
                    style: GoogleFonts.poppins(),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: _takePhoto,
                icon: const FaIcon(FontAwesomeIcons.camera, size: 16),
                label: Text(
                  'Camera',
                  style: GoogleFonts.poppins(),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
