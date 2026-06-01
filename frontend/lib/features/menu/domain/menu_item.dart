import 'dart:convert';

class MenuItem {
  const MenuItem({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.ingredients,
    required this.calories,
    required this.isAvailable,
  });

  final int id;
  final String title;
  final String description;
  final double price;
  final String category;
  final List<String> ingredients;
  final int calories;
  final bool isAvailable;

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    final rawIngredients = json['ingredients'];
    return MenuItem(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      category: json['category'] as String,
      ingredients: _parseIngredients(rawIngredients),
      calories: json['calories'] as int,
      isAvailable: json['is_available'] as bool,
    );
  }

  static List<String> _parseIngredients(dynamic raw) {
    if (raw is List) {
      return raw.map((item) => item.toString()).toList();
    }
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map((item) => item.toString()).toList();
        }
      } catch (_) {
        return [raw];
      }
    }
    return const [];
  }
}
