class Topic {
  final int? id;
  final int subjectId;
  final String name;
  final String chapter;
  final int sortOrder;

  Topic({
    this.id,
    required this.subjectId,
    required this.name,
    this.chapter = '',
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'subject_id': subjectId,
      'name': name,
      'chapter': chapter,
      'sort_order': sortOrder,
    };
  }

  factory Topic.fromMap(Map<String, dynamic> map) {
    return Topic(
      id: map['id'] as int?,
      subjectId: map['subject_id'] as int,
      name: map['name'] as String,
      chapter: map['chapter'] as String? ?? '',
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  Topic copyWith({
    int? id,
    int? subjectId,
    String? name,
    String? chapter,
    int? sortOrder,
  }) {
    return Topic(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      name: name ?? this.name,
      chapter: chapter ?? this.chapter,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  String toString() {
    return 'Topic(id: $id, subjectId: $subjectId, name: $name, chapter: $chapter, sortOrder: $sortOrder)';
  }
}
