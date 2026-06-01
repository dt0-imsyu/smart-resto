class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isUser,
  });

  final String text;
  final bool isUser;
}

class UpsellItem {
  const UpsellItem({
    required this.id,
    required this.title,
    required this.reason,
  });

  final int id;
  final String title;
  final String reason;

  factory UpsellItem.fromJson(Map<String, dynamic> json) {
    return UpsellItem(
      id: json['id'] as int,
      title: json['title'] as String,
      reason: json['reason'] as String,
    );
  }
}
