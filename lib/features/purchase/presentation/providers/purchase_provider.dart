import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/purchase_repository.dart';

// Repository provider
final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  return PurchaseRepository();
});

// Products with cost provider
final purchaseProductsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(purchaseRepositoryProvider);
  return await repository.getProductsWithCost();
});

// Products search provider
final purchaseProductsSearchProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
        (ref, query) async {
  if (query.isEmpty) return [];
  final repository = ref.watch(purchaseRepositoryProvider);
  return await repository.getProductsWithCost(searchQuery: query);
});

// Suppliers provider
final suppliersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(purchaseRepositoryProvider);
  return await repository.getSuppliers();
});

// Supplier detail provider
final supplierDetailProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>?, int>(
        (ref, supplierId) async {
  final repository = ref.watch(purchaseRepositoryProvider);
  return await repository.getSupplierDetail(supplierId);
});

// Market price entry state
class MarketPriceState {
  final bool isLoading;
  final String? error;
  final int? createdId;

  const MarketPriceState({
    this.isLoading = false,
    this.error,
    this.createdId,
  });

  MarketPriceState copyWith({
    bool? isLoading,
    String? error,
    int? createdId,
  }) {
    return MarketPriceState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      createdId: createdId ?? this.createdId,
    );
  }
}

class MarketPriceNotifier extends StateNotifier<MarketPriceState> {
  final PurchaseRepository _repository;

  MarketPriceNotifier(this._repository) : super(const MarketPriceState());

  Future<bool> createEntry({
    required int productId,
    required double price,
    int? supplierId,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final id = await _repository.createMarketPriceEntry(
        productId: productId,
        price: price,
        supplierId: supplierId,
        notes: notes,
      );

      state = state.copyWith(isLoading: false, createdId: id);
      return id != null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void reset() {
    state = const MarketPriceState();
  }
}

final marketPriceNotifierProvider =
    StateNotifierProvider<MarketPriceNotifier, MarketPriceState>((ref) {
  final repository = ref.watch(purchaseRepositoryProvider);
  return MarketPriceNotifier(repository);
});
