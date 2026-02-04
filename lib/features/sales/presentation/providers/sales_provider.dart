import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/invoice_model.dart';
import '../../data/repositories/sales_repository.dart';

// Repository provider
final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  return SalesRepository();
});

// Invoices provider
final invoicesProvider = FutureProvider.autoDispose<List<InvoiceModel>>((ref) async {
  final repository = ref.watch(salesRepositoryProvider);
  return await repository.getInvoices();
});

// Invoice detail provider
final invoiceDetailProvider =
    FutureProvider.autoDispose.family<InvoiceModel?, int>((ref, id) async {
  final repository = ref.watch(salesRepositoryProvider);
  return await repository.getInvoice(id);
});

// Customer credits provider
final customerCreditsProvider =
    FutureProvider.autoDispose<List<CustomerCreditModel>>((ref) async {
  final repository = ref.watch(salesRepositoryProvider);
  return await repository.getCustomerCredits();
});

// Products provider (all products)
final productsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(salesRepositoryProvider);
  return await repository.getProducts();
});

// Product search provider
final productSearchProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final repository = ref.watch(salesRepositoryProvider);
  return await repository.searchProducts(query);
});
