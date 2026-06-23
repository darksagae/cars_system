import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();
  
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _filterCategory;
  ProductStatus? _filterStatus;

  // Getters
  List<Product> get products => _filteredProducts;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get filterCategory => _filterCategory;
  ProductStatus? get filterStatus => _filterStatus;

  // Initialize products
  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _products = await _productService.getAllProducts();
      _filteredProducts = List.from(_products);
    } catch (e) {
      print('Error loading products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search products
  void searchProducts(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  // Filter by category
  void filterByCategory(String? category) {
    _filterCategory = category;
    _applyFilters();
  }

  // Filter by status
  void filterByStatus(ProductStatus status) {
    _filterStatus = status;
    _applyFilters();
  }

  // Clear filters
  void clearFilters() {
    _searchQuery = '';
    _filterCategory = null;
    _filterStatus = null;
    _applyFilters();
  }

  // Apply all filters
  void _applyFilters() {
    _filteredProducts = _filterByCategoryAndStatus(_products);
    
    if (_searchQuery.isNotEmpty) {
      _filteredProducts = _filteredProducts.where((product) =>
          product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.sku.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.description.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    notifyListeners();
  }

  // Filter by category and status
  List<Product> _filterByCategoryAndStatus(List<Product> products) {
    return products.where((product) {
      bool categoryMatch = _filterCategory == null || product.category == _filterCategory;
      bool statusMatch = _filterStatus == null || product.status == _filterStatus;
      return categoryMatch && statusMatch;
    }).toList();
  }

  // Add product
  Future<bool> addProduct(Product product) async {
    try {
      final id = await _productService.createProduct(product);
      if (id > 0) {
        product = product.copyWith(id: id);
        _products.add(product);
        _applyFilters();
        return true;
      }
      return false;
    } catch (e) {
      print('Error adding product: $e');
      return false;
    }
  }

  // Update product
  Future<bool> updateProduct(Product product) async {
    try {
      final success = await _productService.updateProduct(product);
      if (success > 0) {
        final index = _products.indexWhere((p) => p.id == product.id);
        if (index != -1) {
          _products[index] = product;
          _applyFilters();
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating product: $e');
      return false;
    }
  }

  // Delete product
  Future<bool> deleteProduct(int id) async {
    try {
      final success = await _productService.deleteProduct(id);
      if (success > 0) {
        _products.removeWhere((product) => product.id == id);
        _applyFilters();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting product: $e');
      return false;
    }
  }

  // Get product by ID
  Product? getProductById(int id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get products by category
  List<Product> getProductsByCategory(String category) {
    return _products.where((product) => product.category == category).toList();
  }

  // Get product statistics
  Map<String, dynamic> getProductStats() {
    final total = _products.length;
    final active = _products.where((p) => p.status == ProductStatus.active).length;
    final inactive = _products.where((p) => p.status == ProductStatus.inactive).length;
    final lowStock = _products.where((p) => p.stock <= p.lowStockThreshold).length;
    final outOfStock = _products.where((p) => p.stock == 0).length;
    
    final totalValue = _products.fold<double>(0, (sum, product) => sum + (product.price * product.stock));
    final averagePrice = total > 0 ? totalValue / total : 0.0;
    
    return {
      'totalProducts': total,
      'activeProducts': active,
      'inactiveProducts': inactive,
      'lowStockProducts': lowStock,
      'outOfStockProducts': outOfStock,
      'totalValue': totalValue,
      'averagePrice': averagePrice,
    };
  }

  // Get low stock products
  List<Product> getLowStockProducts() {
    return _products.where((product) => 
        product.stock <= product.lowStockThreshold && product.stock > 0).toList();
  }

  // Get out of stock products
  List<Product> getOutOfStockProducts() {
    return _products.where((product) => product.stock == 0).toList();
  }

  // Update product stock
  Future<bool> updateProductStock(int productId, int newStock) async {
    try {
      final product = getProductById(productId);
      if (product != null) {
        final updatedProduct = product.copyWith(stock: newStock);
        return await updateProduct(updatedProduct);
      }
      return false;
    } catch (e) {
      print('Error updating product stock: $e');
      return false;
    }
  }

  // Update product price
  Future<bool> updateProductPrice(int productId, double newPrice) async {
    try {
      final product = getProductById(productId);
      if (product != null) {
        final updatedProduct = product.copyWith(price: newPrice);
        return await updateProduct(updatedProduct);
      }
      return false;
    } catch (e) {
      print('Error updating product price: $e');
      return false;
    }
  }

  // Update product status
  Future<bool> updateProductStatus(int productId, ProductStatus newStatus) async {
    try {
      final product = getProductById(productId);
      if (product != null) {
        final updatedProduct = product.copyWith(status: newStatus);
        return await updateProduct(updatedProduct);
      }
      return false;
    } catch (e) {
      print('Error updating product status: $e');
      return false;
    }
  }

  // Get products by status
  List<Product> getProductsByStatus(ProductStatus status) {
    return _products.where((product) => product.status == status).toList();
  }

  // Get product by SKU
  Product? getProductBySku(String sku) {
    try {
      return _products.firstWhere((product) => product.sku == sku);
    } catch (e) {
      return null;
    }
  }

  // Get products with low stock
  List<Product> getProductsWithLowStock() {
    return _products.where((product) => 
        product.stock <= product.lowStockThreshold).toList();
  }

  // Get products by price range
  List<Product> getProductsByPriceRange(double minPrice, double maxPrice) {
    return _products.where((product) => 
        product.price >= minPrice && product.price <= maxPrice).toList();
  }

  // Get top selling products (placeholder - would need sales data)
  List<Product> getTopSellingProducts() {
    // This would require sales data integration
    return _products.take(10).toList();
  }

  // Refresh products
  Future<void> refreshProducts() async {
    await loadProducts();
  }
}