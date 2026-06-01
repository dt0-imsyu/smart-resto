import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../ai_chat/data/ai_repository.dart';
import '../../ai_chat/domain/chat_message.dart';
import '../../menu/data/menu_repository.dart';
import '../../menu/presentation/menu_controller.dart';
import '../domain/cart_item.dart';
import 'cart_controller.dart';

final upsellProvider = FutureProvider.autoDispose<List<UpsellItem>>((ref) {
  final ids = ref.watch(cartIdsProvider);
  if (ids.isEmpty) {
    return const [];
  }
  return ref.watch(aiRepositoryProvider).fetchUpsell(ids);
});

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartItemsProvider);
    final total = ref.watch(cartTotalProvider);
    final currency = NumberFormat.currency(locale: 'en_US', symbol: 'RUB ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          if (items.isNotEmpty)
            TextButton.icon(
              onPressed: () => ref.read(cartProvider.notifier).clear(),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Clear'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: items.isEmpty
          ? const _EmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemBuilder: (context, index) => _CartRow(
                      cartItem: items[index],
                      price: currency.format(items[index].totalPrice),
                    ),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemCount: items.length,
                  ),
                ),
                _UpsellRail(currency: currency),
                _CheckoutBar(total: currency.format(total)),
              ],
            ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shopping_bag_outlined, size: 34),
            ),
            const SizedBox(height: 18),
            Text(
              'Your cart is empty',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text('Add a dish and SmartResto will recommend the best pairings.'),
          ],
        ),
      ),
    );
  }
}

class _CartRow extends ConsumerWidget {
  const _CartRow({
    required this.cartItem,
    required this.price,
  });

  final CartItem cartItem;
  final String price;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = cartItem.menuItem;
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F4EE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.restaurant_menu),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(price, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            _QuantityStepper(
              quantity: cartItem.quantity,
              onMinus: () => ref.read(cartProvider.notifier).decrement(item.id),
              onPlus: () => ref.read(cartProvider.notifier).add(item),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onMinus,
    required this.onPlus,
  });

  final int quantity;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF15110F),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Decrease',
            onPressed: onMinus,
            icon: const Icon(Icons.remove, color: Colors.white),
          ),
          Text(
            quantity.toString(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          IconButton(
            tooltip: 'Increase',
            onPressed: onPlus,
            icon: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _UpsellRail extends ConsumerWidget {
  const _UpsellRail({required this.currency});

  final NumberFormat currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upsell = ref.watch(upsellProvider);
    final menu = ref.watch(menuProvider).valueOrNull ?? const [];
    return SizedBox(
      height: 172,
      child: upsell.when(
        data: (items) {
          if (items.isEmpty) {
            return const SizedBox.shrink();
          }
          return DecoratedBox(
            decoration: const BoxDecoration(color: Color(0xFF15110F)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFFFFC46B), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'AI recommends adding',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final suggestion = items[index];
                      final matches = menu.where((item) => item.id == suggestion.id);
                      final menuItem = matches.isEmpty ? null : matches.first;
                      return SizedBox(
                        width: 272,
                        child: Card(
                          color: Colors.white,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: menuItem == null
                                ? null
                                : () => ref.read(cartProvider.notifier).add(menuItem),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    suggestion.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    suggestion.reason,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.black54),
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      Text(
                                        menuItem == null ? 'Unavailable' : currency.format(menuItem.price),
                                        style: const TextStyle(fontWeight: FontWeight.w900),
                                      ),
                                      const Spacer(),
                                      const Icon(Icons.add_circle, color: Color(0xFFE85D2A)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemCount: items.length,
                  ),
                ),
              ],
            ),
          );
        },
        error: (_, __) => const SizedBox.shrink(),
        loading: () => const Center(child: LinearProgressIndicator()),
      ),
    );
  }
}

class _CheckoutBar extends ConsumerWidget {
  const _CheckoutBar({required this.total});

  final String total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartItemsProvider);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(color: Colors.white),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total', style: TextStyle(color: Colors.black54)),
                  Text(
                    total,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: items.isEmpty ? null : () => _checkout(context, ref),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Place order'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkout(BuildContext context, WidgetRef ref) async {
    final cart = ref.read(cartProvider);
    try {
      await ref.read(menuRepositoryProvider).createOrder(
            userId: 'guest',
            quantitiesByItemId: {
              for (final entry in cart.entries) entry.key: entry.value.quantity,
            },
          );
      ref.read(cartProvider.notifier).clear();
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order created')),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not create order')),
      );
    }
  }
}
