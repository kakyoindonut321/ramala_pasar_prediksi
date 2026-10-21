class Market {
  const Market({
    required this.id,
    required this.title,
    required this.category,
    required this.status,
    required this.closeAt,
    required this.b,
    required this.qYes,
    required this.qNo,
    required this.priceYes,
    required this.volume,
    this.description,
    this.imageUrl,
    this.outcome,
  });

  final String id, title, category, status;
  final String? description, imageUrl, outcome;
  final DateTime closeAt;
  final double b, qYes, qNo, priceYes, volume;

  bool get isOpen => status == 'open' && closeAt.isAfter(DateTime.now());

  factory Market.fromMap(Map<String, dynamic> m) => Market(
    id: m['id'] as String,
    title: m['title'] as String,
    description: m['description'] as String?,
    category: m['category'] as String,
    imageUrl: m['image_url'] as String?,
    status: m['status'] as String,
    outcome: m['outcome'] as String?,
    closeAt: DateTime.parse(m['close_at'] as String),
    b: (m['b'] as num).toDouble(),
    qYes: (m['q_yes'] as num).toDouble(),
    qNo: (m['q_no'] as num).toDouble(),
    priceYes: (m['price_yes'] as num).toDouble(),
    volume: (m['volume'] as num).toDouble(),
  );
}
