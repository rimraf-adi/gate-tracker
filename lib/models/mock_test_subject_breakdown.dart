class MockTestSubjectBreakdown {
  final int? id;
  final int mockTestId;
  final int subjectId;
  final int marksObtained;
  final int totalMarks;

  MockTestSubjectBreakdown({
    this.id,
    required this.mockTestId,
    required this.subjectId,
    required this.marksObtained,
    required this.totalMarks,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'mock_test_id': mockTestId,
      'subject_id': subjectId,
      'marks_obtained': marksObtained,
      'total_marks': totalMarks,
    };
  }

  factory MockTestSubjectBreakdown.fromMap(Map<String, dynamic> map) {
    return MockTestSubjectBreakdown(
      id: map['id'] as int?,
      mockTestId: map['mock_test_id'] as int,
      subjectId: map['subject_id'] as int,
      marksObtained: map['marks_obtained'] as int,
      totalMarks: map['total_marks'] as int,
    );
  }

  MockTestSubjectBreakdown copyWith({
    int? id,
    int? mockTestId,
    int? subjectId,
    int? marksObtained,
    int? totalMarks,
  }) {
    return MockTestSubjectBreakdown(
      id: id ?? this.id,
      mockTestId: mockTestId ?? this.mockTestId,
      subjectId: subjectId ?? this.subjectId,
      marksObtained: marksObtained ?? this.marksObtained,
      totalMarks: totalMarks ?? this.totalMarks,
    );
  }

  @override
  String toString() {
    return 'MockTestSubjectBreakdown(id: $id, mockTestId: $mockTestId, subjectId: $subjectId, marksObtained: $marksObtained, totalMarks: $totalMarks)';
  }
}
