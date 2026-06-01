import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/menu_item.dart';

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return MenuRepository(ref.watch(dioProvider));
});

class MenuRepository {
  const MenuRepository(this._dio);

  final Dio _dio;

  Future<List<MenuItem>> fetchMenu({String? category}) async {
    final response = await _dio.get<List<dynamic>>(
      '/menu',
      queryParameters: category == null ? null : {'category': category},
    );
    final data = response.data ?? const [];
    return data
        .map((item) => MenuItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> createOrder({
    required String userId,
    required Map<int, int> quantitiesByItemId,
  }) async {
    await _dio.post(
      '/orders',
      data: {
        'user_id': userId,
        'items': quantitiesByItemId.entries
            .map(
              (entry) => {
                'menu_item_id': entry.key,
                'quantity': entry.value,
              },
            )
            .toList(),
      },
    );
  }
}
