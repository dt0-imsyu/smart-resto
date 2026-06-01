import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/chat_message.dart';

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepository(ref.watch(dioProvider));
});

class AiRepository {
  const AiRepository(this._dio);

  final Dio _dio;

  Future<String> sendMessage({
    required String userMessage,
    required List<int> currentCart,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/ai/chat',
      data: {
        'user_message': userMessage,
        'current_cart': currentCart,
      },
    );
    return response.data?['answer'] as String? ??
        'Не удалось получить ответ ИИ-официанта.';
  }

  Future<List<UpsellItem>> fetchUpsell(List<int> currentCart) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/ai/upsell',
      data: {'current_cart': currentCart},
    );
    final rawItems = response.data?['upsell_items'] as List<dynamic>? ?? const [];
    return rawItems
        .map((item) => UpsellItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
