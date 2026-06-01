import '../../menu/domain/menu_item.dart';

class CartItem {
  const CartItem({
    required this.menuItem,
    required this.quantity,
  });

  final MenuItem menuItem;
  final int quantity;

  double get totalPrice => menuItem.price * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      menuItem: menuItem,
      quantity: quantity ?? this.quantity,
    );
  }
}
