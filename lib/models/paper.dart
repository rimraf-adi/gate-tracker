class Paper {
  final int? id;
  final String code;            // "CSE", "ECE", "CUSTOM-001"
  final String fullName;        // "Computer Science & Information Technology"
  final bool isCustom;          // true for user-created exams
  final String? syllabusSource; // raw syllabus text for custom exams; null for built-in
  final int sortOrder;          // ordering in the paper selector

  Paper({
    this.id,
    required this.code,
    required this.fullName,
    this.isCustom = false,
    this.syllabusSource,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'code': code,
      'full_name': fullName,
      'is_custom': isCustom ? 1 : 0,
      'syllabus_source': syllabusSource,
      'sort_order': sortOrder,
    };
  }

  factory Paper.fromMap(Map<String, dynamic> map) {
    return Paper(
      id: map['id'] as int?,
      code: map['code'] as String,
      fullName: map['full_name'] as String,
      isCustom: (map['is_custom'] as int? ?? 0) == 1,
      syllabusSource: map['syllabus_source'] as String?,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  Paper copyWith({
    int? id,
    String? code,
    String? fullName,
    bool? isCustom,
    String? syllabusSource,
    int? sortOrder,
  }) {
    return Paper(
      id: id ?? this.id,
      code: code ?? this.code,
      fullName: fullName ?? this.fullName,
      isCustom: isCustom ?? this.isCustom,
      syllabusSource: syllabusSource ?? this.syllabusSource,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  String toString() {
    return 'Paper(id: $id, code: $code, fullName: $fullName, isCustom: $isCustom, sortOrder: $sortOrder)';
  }
}
