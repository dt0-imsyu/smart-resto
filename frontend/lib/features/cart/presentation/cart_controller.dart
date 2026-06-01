import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../menu/domain/menu_item.dart';
import '../domain/cart_item.dart';

final cartProvider = StateNotifierProvider<CartController, Map<int, CartItem>>(
  (ref) => CartController(),
);

class CartController extends StateNotifier<Map<int, CartItem>> {
  CartController() : super(const {});

  void add(MenuItem item) {
    final existing = state[item.id];
    state = {
      ...state,
      item.id: existing == null
          ? CartItem(menuItem: item, quantity: 1)
          : existing.copyWith(quantity: existing.quantity + 1),
    };
  }

  void decrement(int itemId) {
    final existing = state[itemId];
    if (existing == null) {
      return;
    }
    if (existing.quantity <= 1) {
      remove(itemId);
      return;
    }
    state = {
      ...state,
      itemId: existing.copyWith(quantity: existing.quantity - 1),
    };
  }

  void remove(int itemId) {
    final next = {...state}..remove(itemId);
    state = next;
  }

  void clear() {
    state = const {};
  }
}

final cartItemsProvider = Provider<List<CartItem>>((ref) {
  return ref.watch(cartProvider).values.toList();
});

final cartTotalProvider = Provider<double>((ref) {
  return ref.watch(cartItemsProvider).fold<double>(
        0,
        (total, item) => total + item.totalPrice,
      );
});

final cartIdsProvider = Provider<List<int>>((ref) {
  return ref.watch(cartItemsProvider).map((item) => item.menuItem.id).toList();
});
