import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/odoo_rpc_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/invoice_model.dart';

class SalesRepository {
  final OdooRpcClient _rpcClient;
  final SecureStorageService _storage;

  SalesRepository({
    OdooRpcClient? rpcClient,
    SecureStorageService? storage,
  })  : _rpcClient = rpcClient ?? OdooRpcClient.instance,
        _storage = storage ?? SecureStorageService.instance;

  Future<int?> get _userId async {
    return await _storage.getUserId();
  }

  // Get customer invoices (invoices where current user is the salesperson)
  Future<List<InvoiceModel>> getInvoices({
    int limit = 50,
    int offset = 0,
    String? paymentState,
  }) async {
    final userId = await _userId;

    final domain = <List<dynamic>>[
      ['move_type', '=', 'out_invoice'],
      ['state', '=', 'posted'],
    ];

    // Filter by payment state if specified
    if (paymentState != null && paymentState.isNotEmpty) {
      domain.add(['payment_state', '=', paymentState]);
    }

    // Try to filter by salesperson (user_id), but don't fail if not accessible
    if (userId != null) {
      try {
        domain.add(['invoice_user_id', '=', userId]);
      } catch (_) {
        // Field might not exist or not accessible
      }
    }

    try {
      final result = await _rpcClient.searchRead(
        model: AppConstants.modelInvoice,
        domain: domain,
        fields: [
          'name',
          'partner_id',
          'amount_total',
          'amount_residual',
          'invoice_date',
          'invoice_date_due',
          'state',
          'payment_state',
          'currency_id',
        ],
        limit: limit,
        offset: offset,
        order: 'invoice_date desc',
      );

      return result.map((json) => InvoiceModel.fromJson(json)).toList();
    } catch (e) {
      // Fallback: try without user filter
      final fallbackDomain = <List<dynamic>>[
        ['move_type', '=', 'out_invoice'],
        ['state', '=', 'posted'],
      ];

      if (paymentState != null && paymentState.isNotEmpty) {
        fallbackDomain.add(['payment_state', '=', paymentState]);
      }

      final result = await _rpcClient.searchRead(
        model: AppConstants.modelInvoice,
        domain: fallbackDomain,
        fields: [
          'name',
          'partner_id',
          'amount_total',
          'amount_residual',
          'invoice_date',
          'invoice_date_due',
          'state',
          'payment_state',
          'currency_id',
        ],
        limit: limit,
        offset: offset,
        order: 'invoice_date desc',
      );

      return result.map((json) => InvoiceModel.fromJson(json)).toList();
    }
  }

  // Get single invoice details
  Future<InvoiceModel?> getInvoice(int id) async {
    final result = await _rpcClient.read(
      model: AppConstants.modelInvoice,
      ids: [id],
      fields: [
        'name',
        'partner_id',
        'amount_total',
        'amount_residual',
        'invoice_date',
        'invoice_date_due',
        'state',
        'payment_state',
        'currency_id',
        'invoice_line_ids',
      ],
    );

    return result.isNotEmpty ? InvoiceModel.fromJson(result[0]) : null;
  }

  // Get customer credit info
  Future<List<CustomerCreditModel>> getCustomerCredits() async {
    try {
      // Get partners with credit info
      final partners = await _rpcClient.searchRead(
        model: AppConstants.modelPartner,
        domain: [
          ['customer_rank', '>', 0],
        ],
        fields: ['name', 'credit_limit', 'credit', 'total_due'],
        limit: 50,
        order: 'total_due desc',
      );

      return partners.map((json) {
        final credit = (json['credit'] as num?)?.toDouble() ?? 0.0;
        final creditLimit = (json['credit_limit'] as num?)?.toDouble() ?? 0.0;
        final totalDue = (json['total_due'] as num?)?.toDouble() ?? 0.0;

        return CustomerCreditModel(
          partnerId: json['id'] as int,
          partnerName: json['name'] as String? ?? '',
          creditLimit: creditLimit,
          creditUsed: credit,
          creditAvailable: creditLimit > 0 ? creditLimit - credit : 0,
          totalDue: totalDue,
          totalOverdue: 0, // Would need separate calculation
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Get all products
  Future<List<Map<String, dynamic>>> getProducts({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final result = await _rpcClient.searchRead(
        model: AppConstants.modelProductTemplate,
        domain: [
          ['sale_ok', '=', true],
        ],
        fields: ['name', 'default_code', 'list_price', 'qty_available'],
        limit: limit,
        offset: offset,
        order: 'name',
      );

      return result;
    } catch (e) {
      // Fallback without sale_ok filter
      try {
        final result = await _rpcClient.searchRead(
          model: AppConstants.modelProductTemplate,
          domain: [],
          fields: ['name', 'default_code', 'list_price', 'qty_available'],
          limit: limit,
          offset: offset,
          order: 'name',
        );
        return result;
      } catch (_) {
        return [];
      }
    }
  }

  // Search products
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    try {
      final result = await _rpcClient.searchRead(
        model: AppConstants.modelProductTemplate,
        domain: [
          '|',
          ['name', 'ilike', query],
          ['default_code', 'ilike', query],
        ],
        fields: ['name', 'default_code', 'list_price', 'qty_available', 'image_128'],
        limit: 20,
      );

      return result;
    } catch (e) {
      return [];
    }
  }
}
