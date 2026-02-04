import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/odoo_rpc_client.dart';
import '../../../../core/storage/secure_storage_service.dart';

class PurchaseRepository {
  final OdooRpcClient _rpcClient;
  final SecureStorageService _storage;

  PurchaseRepository({
    OdooRpcClient? rpcClient,
    SecureStorageService? storage,
  })  : _rpcClient = rpcClient ?? OdooRpcClient.instance,
        _storage = storage ?? SecureStorageService.instance;

  // Get products with cost price and supplier info
  Future<List<Map<String, dynamic>>> getProductsWithCost({
    int limit = 50,
    int offset = 0,
    String? searchQuery,
  }) async {
    try {
      List<dynamic> domain = [
        ['purchase_ok', '=', true],
      ];

      if (searchQuery != null && searchQuery.isNotEmpty) {
        domain = [
          '&',
          ['purchase_ok', '=', true],
          '|',
          ['name', 'ilike', searchQuery],
          ['default_code', 'ilike', searchQuery],
        ];
      }

      final result = await _rpcClient.searchRead(
        model: AppConstants.modelProductTemplate,
        domain: domain,
        fields: [
          'name',
          'default_code',
          'standard_price',
          'list_price',
          'qty_available',
          'seller_ids',
        ],
        limit: limit,
        offset: offset,
        order: 'name',
      );

      // Enrich with supplier info
      final enrichedProducts = <Map<String, dynamic>>[];
      for (final product in result) {
        final enriched = Map<String, dynamic>.from(product);

        // Get supplier info if seller_ids exist
        final sellerIds = product['seller_ids'] as List<dynamic>? ?? [];
        if (sellerIds.isNotEmpty) {
          try {
            final suppliers = await _rpcClient.read(
              model: 'product.supplierinfo',
              ids: sellerIds.cast<int>().take(3).toList(),
              fields: ['partner_id', 'price', 'min_qty'],
            );
            enriched['suppliers'] = suppliers;
          } catch (_) {
            enriched['suppliers'] = [];
          }
        } else {
          enriched['suppliers'] = [];
        }

        enrichedProducts.add(enriched);
      }

      return enrichedProducts;
    } catch (e) {
      // Fallback without purchase_ok filter
      try {
        final result = await _rpcClient.searchRead(
          model: AppConstants.modelProductTemplate,
          domain: searchQuery != null && searchQuery.isNotEmpty
              ? [
                  '|',
                  ['name', 'ilike', searchQuery],
                  ['default_code', 'ilike', searchQuery],
                ]
              : [],
          fields: [
            'name',
            'default_code',
            'standard_price',
            'list_price',
            'qty_available',
          ],
          limit: limit,
          offset: offset,
          order: 'name',
        );
        return result.map((p) => {...p, 'suppliers': []}).toList();
      } catch (_) {
        return [];
      }
    }
  }

  // Get suppliers list
  Future<List<Map<String, dynamic>>> getSuppliers({
    int limit = 50,
    int offset = 0,
    String? searchQuery,
  }) async {
    try {
      List<dynamic> domain = [
        ['supplier_rank', '>', 0],
      ];

      if (searchQuery != null && searchQuery.isNotEmpty) {
        domain = [
          '&',
          ['supplier_rank', '>', 0],
          ['name', 'ilike', searchQuery],
        ];
      }

      final result = await _rpcClient.searchRead(
        model: AppConstants.modelPartner,
        domain: domain,
        fields: [
          'name',
          'email',
          'phone',
          'mobile',
          'city',
          'country_id',
        ],
        limit: limit,
        offset: offset,
        order: 'name',
      );

      return result;
    } catch (e) {
      return [];
    }
  }

  // Get supplier details
  Future<Map<String, dynamic>?> getSupplierDetail(int supplierId) async {
    try {
      final result = await _rpcClient.read(
        model: AppConstants.modelPartner,
        ids: [supplierId],
        fields: [
          'name',
          'email',
          'phone',
          'mobile',
          'street',
          'street2',
          'city',
          'state_id',
          'country_id',
          'zip',
          'website',
          'supplier_rank',
        ],
      );

      if (result.isEmpty) return null;

      final supplier = Map<String, dynamic>.from(result[0]);

      // Get recent purchase orders for this supplier
      try {
        final orders = await _rpcClient.searchRead(
          model: 'purchase.order',
          domain: [
            ['partner_id', '=', supplierId],
            ['state', 'in', ['purchase', 'done']],
          ],
          fields: ['name', 'date_order', 'amount_total', 'state'],
          limit: 5,
          order: 'date_order desc',
        );
        supplier['recent_orders'] = orders;
      } catch (_) {
        supplier['recent_orders'] = [];
      }

      // Get products supplied by this supplier
      try {
        final supplierInfo = await _rpcClient.searchRead(
          model: 'product.supplierinfo',
          domain: [
            ['partner_id', '=', supplierId],
          ],
          fields: ['product_tmpl_id', 'price', 'min_qty'],
          limit: 10,
        );
        supplier['supplied_products'] = supplierInfo;
      } catch (_) {
        supplier['supplied_products'] = [];
      }

      return supplier;
    } catch (e) {
      return null;
    }
  }

  // Create market price entry
  Future<int?> createMarketPriceEntry({
    required int productId,
    required double price,
    int? supplierId,
    String? notes,
  }) async {
    try {
      final userId = await _storage.getUserId();

      final id = await _rpcClient.create(
        model: 'purchase.market.price',
        values: {
          'product_id': productId,
          'price': price,
          if (supplierId != null) 'supplier_id': supplierId,
          if (notes != null) 'notes': notes,
          'user_id': userId,
          'date': DateTime.now().toIso8601String().split('T')[0],
        },
      );

      return id;
    } catch (e) {
      // Model might not exist, ignore
      return null;
    }
  }
}
