import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cart/presentation/cart_controller.dart';
import '../data/ai_repository.dart';
import '../domain/chat_message.dart';

class AiChatState {
  const AiChatState({
    required this.messages,
    required this.isLoading,
  });

  final List<ChatMessage> messages;
  final bool isLoading;

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final aiChatProvider = StateNotifierProvider<AiChatController, AiChatState>((ref) {
  return AiChatController(ref);
});

class AiChatController extends StateNotifier<AiChatState> {
  AiChatController(this._ref)
      : super(
          const AiChatState(
            messages: [
              ChatMessage(
                text: 'Hi, I am the SmartResto AI waiter. Tell me your taste, diet, or allergy needs and I will recommend dishes from the live menu.',
                isUser: false,
              ),
            ],
            isLoading: false,
          ),
        );

  final Ref _ref;

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isLoading) {
      return;
    }
    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(text: trimmed, isUser: true),
      ],
      isLoading: true,
    );
    try {
      final answer = await _ref.read(aiRepositoryProvider).sendMessage(
            userMessage: trimmed,
            currentCart: _ref.read(cartIdsProvider),
          );
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(text: answer, isUser: false),
        ],
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        messages: [
          ...state.messages,
          const ChatMessage(
            text: 'I cannot reach the restaurant server right now. Please try again.',
            isUser: false,
          ),
        ],
        isLoading: false,
      );
    }
  }
}
