import 'package:supabase_flutter/supabase_flutter.dart';

/// Backend-ready contracts for Toko Kreativ.
///
/// This file intentionally contains no credentials and no network calls yet.
/// The current app can keep using its local demo store while a Supabase
/// implementation is wired behind these contracts.
enum StoreUserRole { buyer, premiumSeller, admin }

enum StoreProductStatus { draft, pendingReview, active, rejected, inactive }

enum StoreOrderStatus {
  pendingPayment,
  paid,
  processing,
  shipped,
  delivered,
  cancelled,
}

class BackendStoreProduct {
  final String id;
  final String sellerId;
  final String title;
  final String category;
  final int price;
  final StoreProductStatus status;
  final String? coverPath;
  final String? ebookPath;

  const BackendStoreProduct({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.category,
    required this.price,
    required this.status,
    this.coverPath,
    this.ebookPath,
  });
}

class BackendStoreOrder {
  final String id;
  final String buyerId;
  final List<String> productIds;
  final int subtotal;
  final int shippingCost;
  final int total;
  final StoreOrderStatus status;
  final String shippingAddress;
  final String phone;

  const BackendStoreOrder({
    required this.id,
    required this.buyerId,
    required this.productIds,
    required this.subtotal,
    required this.shippingCost,
    required this.total,
    required this.status,
    required this.shippingAddress,
    required this.phone,
  });
}

abstract interface class StoreBackendRepository {
  Future<List<BackendStoreProduct>> fetchActiveProducts();
  Future<List<BackendStoreProduct>> fetchSellerProducts(String sellerId);
  Future<BackendStoreProduct> submitProduct(BackendStoreProduct product);
  Future<List<BackendStoreOrder>> fetchOrders(String buyerId);
  Future<BackendStoreOrder> createOrder(BackendStoreOrder order);
  Future<bool> hasEbookAccess(String buyerId, String productId);
}

/// Session-only adapter used until the Supabase project is configured.
class LocalStoreBackendRepository implements StoreBackendRepository {
  final List<BackendStoreProduct> products = [];
  final List<BackendStoreOrder> orders = [];
  final Set<String> ebookAccess = {};

  @override
  Future<List<BackendStoreProduct>> fetchActiveProducts() async => products
      .where((product) => product.status == StoreProductStatus.active)
      .toList();

  @override
  Future<List<BackendStoreProduct>> fetchSellerProducts(
    String sellerId,
  ) async => products.where((product) => product.sellerId == sellerId).toList();

  @override
  Future<BackendStoreProduct> submitProduct(BackendStoreProduct product) async {
    products.add(product);
    return product;
  }

  @override
  Future<List<BackendStoreOrder>> fetchOrders(String buyerId) async =>
      orders.where((order) => order.buyerId == buyerId).toList();

  @override
  Future<BackendStoreOrder> createOrder(BackendStoreOrder order) async {
    orders.add(order);
    ebookAccess.addAll(order.productIds);
    return order;
  }

  @override
  Future<bool> hasEbookAccess(String buyerId, String productId) async =>
      ebookAccess.contains(productId);
}

class SupabaseStoreBackendRepository implements StoreBackendRepository {
  final SupabaseClient client;

  const SupabaseStoreBackendRepository(this.client);

  StoreProductStatus _productStatus(String value) =>
      StoreProductStatus.values.firstWhere(
        (status) => status.name == value,
        orElse: () => StoreProductStatus.pendingReview,
      );

  StoreOrderStatus _orderStatus(String value) =>
      StoreOrderStatus.values.firstWhere(
        (status) => status.name == value,
        orElse: () => StoreOrderStatus.pendingPayment,
      );

  BackendStoreProduct _productFromMap(Map<String, dynamic> row) =>
      BackendStoreProduct(
        id: row['id'] as String,
        sellerId: row['seller_id'] as String,
        title: row['title'] as String,
        category: row['category'] as String,
        price: row['price'] as int,
        status: _productStatus(row['status'] as String),
        coverPath: row['cover_path'] as String?,
        ebookPath: row['ebook_path'] as String?,
      );

  @override
  Future<List<BackendStoreProduct>> fetchActiveProducts() async {
    final rows = await client.from('products').select().eq('status', 'active');
    return (rows as List)
        .map((row) => _productFromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  @override
  Future<List<BackendStoreProduct>> fetchSellerProducts(String sellerId) async {
    final rows = await client
        .from('products')
        .select()
        .eq('seller_id', sellerId);
    return (rows as List)
        .map((row) => _productFromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  @override
  Future<BackendStoreProduct> submitProduct(BackendStoreProduct product) async {
    final row = await client
        .from('products')
        .insert({
          'seller_id': product.sellerId,
          'title': product.title,
          'category': product.category,
          'price': product.price,
          'status': 'pending_review',
          'cover_path': product.coverPath,
          'ebook_path': product.ebookPath,
        })
        .select()
        .single();
    return _productFromMap(Map<String, dynamic>.from(row));
  }

  @override
  Future<List<BackendStoreOrder>> fetchOrders(String buyerId) async {
    final rows = await client
        .from('orders')
        .select()
        .eq('buyer_id', buyerId)
        .order('created_at', ascending: false);
    return (rows as List).map((row) {
      final data = Map<String, dynamic>.from(row);
      return BackendStoreOrder(
        id: data['id'] as String,
        buyerId: data['buyer_id'] as String,
        productIds: const [],
        subtotal: data['subtotal'] as int,
        shippingCost: data['shipping_cost'] as int,
        total: data['total'] as int,
        status: _orderStatus(data['status'] as String),
        shippingAddress: '',
        phone: '',
      );
    }).toList();
  }

  @override
  Future<BackendStoreOrder> createOrder(BackendStoreOrder order) async {
    final row = await client
        .from('orders')
        .insert({
          'buyer_id': order.buyerId,
          'subtotal': order.subtotal,
          'shipping_cost': order.shippingCost,
          'total': order.total,
          'status': order.status.name,
        })
        .select()
        .single();
    final data = Map<String, dynamic>.from(row);
    return BackendStoreOrder(
      id: data['id'] as String,
      buyerId: data['buyer_id'] as String,
      productIds: order.productIds,
      subtotal: data['subtotal'] as int,
      shippingCost: data['shipping_cost'] as int,
      total: data['total'] as int,
      status: _orderStatus(data['status'] as String),
      shippingAddress: order.shippingAddress,
      phone: order.phone,
    );
  }

  @override
  Future<bool> hasEbookAccess(String buyerId, String productId) async {
    final row = await client
        .from('ebook_library')
        .select('product_id')
        .eq('buyer_id', buyerId)
        .eq('product_id', productId)
        .maybeSingle();
    return row != null;
  }
}
