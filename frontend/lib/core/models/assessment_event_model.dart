import 'package:equatable/equatable.dart';

/// Single assessment row from any of the four `*-assessment-calendar`
/// endpoints. Backend response shape is uniform:
///
/// ```
/// {
///   "id": 12,
///   "title": "Midterm",
///   "type": "exam" | "quiz" | "homework" | ...,
///   "date": "2026-05-14",
///   "maxscore": 100,
///   "subject": "Math",
///   "section": "10-A",
///   "class": "Grade 10"
/// }
/// ```
class AssessmentEventModel extends Equatable {
  final int id;
  final String title;
  final String type;
  final String date; // ISO yyyy-MM-dd
  final num? maxScore;
  final String? subject;
  final String? section;
  final String? className;

  const AssessmentEventModel({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    this.maxScore,
    this.subject,
    this.section,
    this.className,
  });

  factory AssessmentEventModel.fromJson(Map<String, dynamic> json) =>
      AssessmentEventModel(
        id: json['id'] as int,
        title: (json['title'] as String?) ?? 'Assessment',
        type: (json['type'] as String?) ?? 'assessment',
        date: (json['date'] as String?) ?? '',
        maxScore: json['maxscore'] as num?,
        subject: json['subject'] as String?,
        section: json['section'] as String?,
        className: json['class'] as String?,
      );

  /// Pulls the array out of either `{ assessments: [...], total }` or a
  /// bare `[...]`.
  static List<AssessmentEventModel> listFromResponse(dynamic res) {
    final list = switch (res) {
      List<dynamic> l => l,
      Map<String, dynamic> m => (m['assessments'] as List<dynamic>?) ??
          (m['data'] as List<dynamic>?) ??
          const [],
      _ => const [],
    };
    return list
        .whereType<Map<String, dynamic>>()
        .map(AssessmentEventModel.fromJson)
        .toList();
  }

  @override
  List<Object?> get props => [id, title, type, date];
}
