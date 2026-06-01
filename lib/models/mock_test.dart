class MockTest {
  final int? id;
  final int paperId;
  final String testName;
  final DateTime date;
  final int totalMarks;
  final int marksObtained;
  final double? percentile;
  final int? rank;

  MockTest({
    this.id,
    required this.paperId,
    required this.testName,
    required this.date,
    required this.totalMarks,
    required this.marksObtained,
    this.percentile,
    this.rank,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'paper_id': paperId,
      'test_name': testName,
      'date': date.toIso8601String(),
      'total_marks': totalMarks,
      'marks_obtained': marksObtained,
      'percentile': percentile,
      'rank_value': rank,
    };
  }

  factory MockTest.fromMap(Map<String, dynamic> map) {
    return MockTest(
      id: map['id'] as int?,
      paperId: map['paper_id'] as int,
      testName: map['test_name'] as String,
      date: DateTime.parse(map['date'] as String),
      totalMarks: map['total_marks'] as int,
      marksObtained: map['marks_obtained'] as int,
      percentile: map['percentile'] != null ? (map['percentile'] as num).toDouble() : null,
      rank: map['rank_value'] as int?,
    );
  }

  MockTest copyWith({
    int? id,
    int? paperId,
    String? testName,
    DateTime? date,
    int? totalMarks,
    int? marksObtained,
    double? percentile,
    int? rank,
  }) {
    return MockTest(
      id: id ?? this.id,
      paperId: paperId ?? this.paperId,
      testName: testName ?? this.testName,
      date: date ?? this.date,
      totalMarks: totalMarks ?? this.totalMarks,
      marksObtained: marksObtained ?? this.marksObtained,
      percentile: percentile ?? this.percentile,
      rank: rank ?? this.rank,
    );
  }

  @override
  String toString() {
    return 'MockTest(id: $id, paperId: $paperId, testName: $testName, date: $date, totalMarks: $totalMarks, marksObtained: $marksObtained, percentile: $percentile, rank: $rank)';
  }
}
