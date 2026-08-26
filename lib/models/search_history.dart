class SearchHistory {
  final int? id;
  final String targetObject;
  final bool found;
  final DateTime timestamp;

  SearchHistory({
    this.id,
    required this.targetObject,
    required this.found,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'target_object': targetObject,
      'found': found ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SearchHistory.fromMap(Map<String, dynamic> map) {
    return SearchHistory(
      id: map['id'],
      targetObject: map['target_object'],
      found: map['found'] == 1,
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
