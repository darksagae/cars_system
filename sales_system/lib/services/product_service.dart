import '../database/database_helper.dart';
import '../models/product.dart';

class ProductService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Create a new product
  Future<int> createProduct(Product product) async {
    final db = await _dbHelper.database;
    return await db.insert('products', product.toMap());
  }

  // Get all products
  Future<List<Product>> getAllProducts() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  // Get active products only
  Future<List<Product>> getActiveProducts() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'isActive = 1',
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  // Get product by ID
  Future<Product?> getProductById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  // Get product by SKU
  Future<Product?> getProductBySku(String sku) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'sku = ?',
      whereArgs: [sku],
    );
    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory(String category) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'category = ? AND isActive = 1',
      whereArgs: [category],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  // Search products
  Future<List<Product>> searchProducts(String query) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: '(name LIKE ? OR description LIKE ? OR sku LIKE ?) AND isActive = 1',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  // Get low stock products
  Future<List<Product>> getLowStockProducts() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'stock <= lowStockThreshold AND isActive = 1',
      orderBy: 'stock ASC',
    );
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  // Update product
  Future<int> updateProduct(Product product) async {
    final db = await _dbHelper.database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  // Delete product (soft delete)
  Future<int> deleteProduct(int id) async {
    final db = await _dbHelper.database;
    return await db.update(
      'products',
      {'isActive': 0, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Permanently delete product
  Future<int> permanentlyDeleteProduct(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Update product stock
  Future<int> updateStock(int productId, int newStock) async {
    final db = await _dbHelper.database;
    return await db.update(
      'products',
      {
        'stock': newStock,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  // Get product categories
  Future<List<String>> getCategories() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      columns: ['category'],
      where: 'category IS NOT NULL AND category != "" AND isActive = 1',
      groupBy: 'category',
      orderBy: 'category ASC',
    );
    return maps.map((map) => map['category'] as String).toList();
  }

  // Get products count
  Future<int> getProductsCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM products WHERE isActive = 1');
    return result.first['count'] as int;
  }

  // Get low stock count
  Future<int> getLowStockCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products WHERE stock <= lowStockThreshold AND isActive = 1'
    );
    return result.first['count'] as int;
  }
}