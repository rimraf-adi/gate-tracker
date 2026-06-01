class StudySession {
  final int? id;
  final int topicId;
  final DateTime date;
  final int durationMinutes; // in minutes

  StudySession({
    this.id,
    required this.topicId,
    required this.date,
    required this.durationMinutes,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'topic_id': topicId,
      'date': date.toIso8601String(),
      'duration_minutes': durationMinutes,
    };
  }

  factory StudySession.fromMap(Map<String, dynamic> map) {
    return StudySession(
      id: map['id'] as int?,
      topicId: map['topic_id'] as int,
      date: DateTime.parse(map['date'] as String),
      durationMinutes: map['duration_minutes'] as int,
    );
  }

  StudySession copyWith({
    int? id,
    int? topicId,
    DateTime? date,
    int? durationMinutes,
  }) {
    return StudySession(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      date: date ?? this.date,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }

  @override
  String toString() {
    return 'StudySession(id: $id, topicId: $topicId, date: $date, durationMinutes: $durationMinutes)';
  }
}
