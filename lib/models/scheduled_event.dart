class ScheduledEvent {
  final int? id;
  final int topicId;
  final DateTime scheduledDate;
  final bool isCompleted;

  ScheduledEvent({
    this.id,
    required this.topicId,
    required this.scheduledDate,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'topic_id': topicId,
      'scheduled_date': scheduledDate.toIso8601String(),
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  factory ScheduledEvent.fromMap(Map<String, dynamic> map) {
    return ScheduledEvent(
      id: map['id'] as int?,
      topicId: map['topic_id'] as int,
      scheduledDate: DateTime.parse(map['scheduled_date'] as String),
      isCompleted: (map['is_completed'] as int) == 1,
    );
  }

  ScheduledEvent copyWith({
    int? id,
    int? topicId,
    DateTime? scheduledDate,
    bool? isCompleted,
  }) {
    return ScheduledEvent(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
