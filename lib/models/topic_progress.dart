enum ProgressStatus { pending, completed }

class TopicProgress {
  final int? id;
  final int topicId;
  final ProgressStatus status;
  final DateTime? lastUpdated;

  TopicProgress({
    this.id,
    required this.topicId,
    required this.status,
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'topic_id': topicId,
      'status': status.name,
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }

  factory TopicProgress.fromMap(Map<String, dynamic> map) {
    return TopicProgress(
      id: map['id'] as int?,
      topicId: map['topic_id'] as int,
      status: _parseStatus(map['status'] as String?),
      lastUpdated: map['last_updated'] != null
          ? DateTime.tryParse(map['last_updated'] as String)
          : null,
    );
  }

  static ProgressStatus _parseStatus(String? name) {
    if (name == null) return ProgressStatus.pending;
    // Map legacy values
    if (name == 'completed') return ProgressStatus.completed;
    // 'notStarted', 'inProgress', or anything else → pending
    return ProgressStatus.pending;
  }

  TopicProgress copyWith({
    int? id,
    int? topicId,
    ProgressStatus? status,
    DateTime? lastUpdated,
  }) {
    return TopicProgress(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      status: status ?? this.status,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() {
    return 'TopicProgress(id: $id, topicId: $topicId, status: $status, lastUpdated: $lastUpdated)';
  }
}
