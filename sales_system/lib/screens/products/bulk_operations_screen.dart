
class BulkOperationsScreen extends StatefulWidget {
  const BulkOperationsScreen({super.key});

  @override
  State<BulkOperationsScreen> createState() => _BulkOperationsScreenState();
}

class _BulkOperationsScreenState extends State<BulkOperationsScreen> {
  final ImportExportService _importExportService = ImportExportService();
  bool _isLoading = false;
  List<Product> _selectedProducts = [];
  bool _selectAll = false;

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
          'Bulk Operations',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_selectedProducts.isNotEmpty)
            TextButton(
              onPressed: _clearSelection,
              child: Text(
                'Clear (${_selectedProducts.length})',
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSelectionBar(),
            Expanded(
              child: _buildProductsList(),
            ),
            if (_selectedProducts.isNotEmpty) _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bulk Operations',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select products to perform bulk operations like export, status changes, or deletion.',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionBar() {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Checkbox(
                  value: _selectAll,
                  onChanged: (value) {
                    setState(() {
                      _selectAll = value ?? false;
                      if (_selectAll) {
                        _selectedProducts = List.from(provider.products);
                      } else {
                        _selectedProducts.clear();
                      }
                    });
                  },
                  activeColor: GlassLiquidTheme.accentBlue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectAll 
                        ? 'All ${provider.products.length} products selected'
                        : '${_selectedProducts.length} products selected',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_selectedProducts.isNotEmpty) ...[
                  IconButton(
                    onPressed: _exportSelected,
                    icon: const FaIcon(
                      FontAwesomeIcons.download,
                      color: Colors.green,
                      size: 20,
                    ),
                    tooltip: 'Export Selected',
                  ),
                  IconButton(
                    onPressed: _showBulkStatusDialog,
                    icon: const FaIcon(
                      FontAwesomeIcons.toggleOn,
                      color: GlassLiquidTheme.accentBlue,
                      size: 20,
                    ),
                    tooltip: 'Change Status',
                  ),
                  IconButton(
                    onPressed: _showBulkDeleteDialog,
                    icon: const FaIcon(
                      FontAwesomeIcons.trash,
                      color: Colors.red,
                      size: 20,
                    ),
                    tooltip: 'Delete Selected',
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductsList() {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (provider.products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(
                  FontAwesomeIcons.boxes,
                  size: 64,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No products found',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add some products to perform bulk operations',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.products.length,
          itemBuilder: (context, index) {
            final product = provider.products[index];
            final isSelected = _selectedProducts.contains(product);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedProducts.add(product);
                          } else {
                            _selectedProducts.remove(product);
                          }
                          _updateSelectAllState();
                        });
                      },
                      activeColor: GlassLiquidTheme.accentBlue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'SKU: ${product.sku} | Stock: ${product.stock} | \$${product.price.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _buildStatusChip(product.status),
                              const SizedBox(width: 8),
                              if (product.barcode != null)
                                _buildInfoChip(
                                  'Barcode',
                                  FontAwesomeIcons.barcode,
                                  Colors.orange,
                                ),
                              if (product.images != null && product.images!.isNotEmpty)
                                _buildInfoChip(
                                  'Images',
                                  FontAwesomeIcons.image,
                                  Colors.purple,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusChip(ProductStatus status) {
    Color color;
    switch (status) {
      case ProductStatus.active:
        color = Colors.green;
        break;
      case ProductStatus.inactive:
        color = Colors.orange;
