class AppNotification {
  const AppNotification(
    this.id,
    this.title,
    this.body,
    this.isRead,
    this.createdAt,
    this.marketId,
  );
  final String id, title, body;
  final bool isRead;
  final DateTime createdAt;
  final String? marketId;

  factory AppNotification.fromMap(Map<String, dynamic> m) => AppNotification(
    m['id'] as String,
    m['title'] as String,
    m['body'] as String,
    m['is_read'] as bool,
    DateTime.parse(m['created_at'] as String),
    (m['data'] as Map?)?['market_id'] as String?,
  );
}
