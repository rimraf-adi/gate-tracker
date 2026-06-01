class Subject {
  final int? id;
  final int paperId;
  final String name;       // "Engineering Mathematics"
  final int sortOrder;     // section ordering

  Subject({
    this.id,
    required this.paperId,
    required this.name,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'paper_id': paperId,
      'name': name,
      'sort_order': sortOrder,
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'] as int?,
      paperId: map['paper_id'] as int,
      name: map['name'] as String,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  Subject copyWith({
    int? id,
    int? paperId,
    String? name,
    int? sortOrder,
  }) {
    return Subject(
      id: id ?? this.id,
      paperId: paperId ?? this.paperId,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  String toString() {
    return 'Subject(id: $id, paperId: $paperId, name: $name, sortOrder: $sortOrder)';
  }
}
