class TopicNote {
  final int? id;
  final int topicId;
  final String content;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  TopicNote({
    this.id,
    required this.topicId,
    this.content = '',
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'topic_id': topicId,
      'content': content,
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory TopicNote.fromMap(Map<String, dynamic> map) {
    return TopicNote(
      id: map['id'] as int?,
      topicId: map['topic_id'] as int,
      content: map['content'] as String? ?? '',
      imagePath: map['image_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  TopicNote copyWith({
    int? id,
    int? topicId,
    String? content,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TopicNote(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      content: content ?? this.content,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'TopicNote(id: $id, topicId: $topicId, content: $content, imagePath: $imagePath, createdAt: $createdAt)';
  }
}
