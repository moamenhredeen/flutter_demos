import 'gtd_area.dart';

enum GtdProjectStatus {
  active,
  completed,
  someday;

  static GtdProjectStatus fromJson(String value) => switch (value) {
        'active' => active,
        'completed' => completed,
        'someday' => someday,
        _ => throw FormatException('Unknown project status: $value'),
      };
}

class GtdProject {
  const GtdProject({
    required this.id,
    required this.title,
    required this.status,
    required this.taskCount,
    this.area,
  });

  final int id;
  final String title;
  final GtdProjectStatus status;
  final GtdArea? area;
  final int taskCount;

  factory GtdProject.fromJson(Map<String, dynamic> json) => GtdProject(
        id: json['id'] as int,
        title: json['title'] as String,
        status: GtdProjectStatus.fromJson(json['status'] as String),
        area: json['area'] != null
            ? GtdArea.fromJson(json['area'] as Map<String, dynamic>)
            : null,
        taskCount: json['task_count'] as int,
      );
}
