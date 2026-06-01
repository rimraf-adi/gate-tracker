class TopicRevision {
  final int? id;
  final int topicId;
  final DateTime scheduledDate;
  final DateTime? completedDate;
  final int intervalDays;

  TopicRevision({
    this.id,
    required this.topicId,
    required this.scheduledDate,
    this.completedDate,
    required this.intervalDays,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'topic_id': topicId,
      'scheduled_date': scheduledDate.toIso8601String(),
      'completed_date': completedDate?.toIso8601String(),
      'interval_days': intervalDays,
    };
  }

  factory TopicRevision.fromMap(Map<String, dynamic> map) {
    return TopicRevision(
      id: map['id'] as int?,
      topicId: map['topic_id'] as int,
      scheduledDate: DateTime.parse(map['scheduled_date'] as String),
      completedDate: map['completed_date'] != null
          ? DateTime.parse(map['completed_date'] as String)
          : null,
      intervalDays: map['interval_days'] as int,
    );
  }

  TopicRevision copyWith({
    int? id,
    int? topicId,
    DateTime? scheduledDate,
    DateTime? completedDate,
    int? intervalDays,
  }) {
    return TopicRevision(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      completedDate: completedDate ?? this.completedDate,
      intervalDays: intervalDays ?? this.intervalDays,
    );
  }
}
