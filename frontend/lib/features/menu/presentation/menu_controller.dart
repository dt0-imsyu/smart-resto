import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/menu_repository.dart';
import '../domain/menu_item.dart';

final menuProvider = FutureProvider<List<MenuItem>>((ref) {
  return ref.watch(menuRepositoryProvider).fetchMenu();
});

final menuCategoriesProvider = Provider<List<String>>((ref) {
  final menu = ref.watch(menuProvider).valueOrNull ?? const <MenuItem>[];
  final categories = menu.map((item) => item.category).toSet().toList()..sort();
  return categories;
});
