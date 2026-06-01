import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../ai_chat/presentation/ai_chat_screen.dart';
import '../../cart/presentation/cart_controller.dart';
import '../../cart/presentation/cart_screen.dart';
import '../domain/menu_item.dart';
import 'menu_controller.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  String? _selectedCategory;
  final _currency = NumberFormat.currency(locale: 'en_US', symbol: 'RUB ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final menu = ref.watch(menuProvider);
    final cartCount = ref.watch(cartItemsProvider).fold<int>(
          0,
          (total, item) => total + item.quantity,
        );

    return Scaffold(
      body: SafeArea(
        child: menu.when(
          data: (items) {
            final categories = items.map((item) => item.category).toSet().toList()..sort();
            final filtered = _selectedCategory == null
                ? items
                : items.where((item) => item.category == _selectedCategory).toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _Header(
                    cartCount: cartCount,
                    onCart: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const CartScreen()),
                    ),
                    onAi: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const AiChatScreen()),
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _CategoryBarDelegate(
                    categories: categories,
                    selectedCategory: _selectedCategory,
                    onSelected: (category) => setState(() => _selectedCategory = category),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.crossAxisExtent;
                      final crossAxisCount = width >= 980 ? 3 : width >= 640 ? 2 : 1;
                      return SliverGrid.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: crossAxisCount == 1 ? 2.2 : 1.02,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) => _MenuCard(
                          item: filtered[index],
                          price: _currency.format(filtered[index].price),
                          onAdd: () {
                            ref.read(cartProvider.notifier).add(filtered[index]);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${filtered[index].title} added to cart'),
                                duration: const Duration(milliseconds: 900),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load menu: $error'),
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.cartCount,
    required this.onCart,
    required this.onAi,
  });

  final int cartCount;
  final VoidCallback onCart;
  final VoidCallback onAi;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SmartResto',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Chef menu, instant order, AI pairing',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              Badge(
                isLabelVisible: cartCount > 0,
                label: Text(cartCount.toString()),
                child: IconButton.filledTonal(
                  tooltip: 'Cart',
                  onPressed: onCart,
                  icon: const Icon(Icons.shopping_bag_outlined),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _AiHero(onAi: onAi),
          const SizedBox(height: 14),
          const _SearchSurface(),
        ],
      ),
    );
  }
}

class _AiHero extends StatelessWidget {
  const _AiHero({required this.onAi});

  final VoidCallback onAi;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF15110F),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFE85D2A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ask the AI waiter',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Get allergy-safe picks, wine pairings, and cart upsell ideas from the live menu.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                          height: 1.25,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: onAi,
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Chat'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchSurface extends StatelessWidget {
  const _SearchSurface();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7DED2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.black45),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Browse pizza, sushi, drinks, desserts',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black45,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const Icon(Icons.tune, color: Colors.black45),
        ],
      ),
    );
  }
}

class _CategoryBarDelegate extends SliverPersistentHeaderDelegate {
  const _CategoryBarDelegate({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onSelected;

  @override
  double get minExtent => 58;

  @override
  double get maxExtent => 58;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ColoredBox(
      color: const Color(0xFFF7F4EE),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final category = index == 0 ? null : categories[index - 1];
          final selected = category == selectedCategory;
          return ChoiceChip(
            label: Text(category ?? 'All'),
            selected: selected,
            onSelected: (_) => onSelected(category),
            showCheckmark: false,
            selectedColor: const Color(0xFF15110F),
            labelStyle: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w800,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: categories.length + 1,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CategoryBarDelegate oldDelegate) {
    return oldDelegate.categories != categories ||
        oldDelegate.selectedCategory != selectedCategory;
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.item,
    required this.price,
    required this.onAdd,
  });

  final MenuItem item;
  final String price;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onAdd,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: _categoryColor(item.category),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_categoryIcon(item.category), color: Colors.white),
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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.category,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: const Color(0xFFE85D2A),
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    price,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                      height: 1.25,
                    ),
              ),
              const Spacer(),
              Row(
                children: [
                  _InfoPill(icon: Icons.local_fire_department_outlined, label: '${item.calories} kcal'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.ingredients.take(3).join(' / '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black45),
                    ),
                  ),
                  IconButton.filled(
                    tooltip: 'Add to cart',
                    onPressed: item.isAvailable ? onAdd : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Пицца':
        return Icons.local_pizza_outlined;
      case 'Суши':
        return Icons.set_meal_outlined;
      case 'Напитки':
        return Icons.local_bar_outlined;
      case 'Десерты':
        return Icons.cake_outlined;
      case 'Салаты':
        return Icons.eco_outlined;
      default:
        return Icons.restaurant_menu;
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Пицца':
        return const Color(0xFFE85D2A);
      case 'Суши':
        return const Color(0xFF2563EB);
      case 'Напитки':
        return const Color(0xFF0F766E);
      case 'Десерты':
        return const Color(0xFFDB2777);
      case 'Салаты':
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFF6B4F3A);
    }
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F4EE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: Colors.black54),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
