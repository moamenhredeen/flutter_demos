enum GtdTaskStatus {
  inbox,
  nextAction,
  waitingFor,
  someday,
  reference,
  done;

  static GtdTaskStatus fromJson(String value) => switch (value) {
        'inbox' => inbox,
        'next_action' => nextAction,
        'waiting_for' => waitingFor,
        'someday' => someday,
        'reference' => reference,
        'done' => done,
        _ => throw FormatException('Unknown task status: $value'),
      };

  String toJson() => switch (this) {
        GtdTaskStatus.nextAction => 'next_action',
        GtdTaskStatus.waitingFor => 'waiting_for',
        _ => name,
      };
}

enum GtdEnergy {
  low,
  medium,
  high;

  static GtdEnergy fromJson(String value) => switch (value) {
        'low' => low,
        'medium' => medium,
        'high' => high,
        _ => throw FormatException('Unknown energy: $value'),
      };

  String toJson() => name;
}

class GtdTask {
  const GtdTask({
    required this.id,
    required this.title,
    required this.status,
    required this.createdAt,
    this.notes,
    this.energy,
    this.timeEstimate,
    this.dueDate,
    this.project,
    this.context,
    this.area,
  });

  final int id;
  final String title;
  final String? notes;
  final GtdTaskStatus status;
  final GtdEnergy? energy;
  final int? timeEstimate;
  final String? dueDate;
  final String createdAt;
  final ({int id, String title})? project;
  final ({int id, String name, String icon})? context;
  final ({int id, String name})? area;

  factory GtdTask.fromJson(Map<String, dynamic> json) {
    final p = json['project'] as Map<String, dynamic>?;
    final c = json['context'] as Map<String, dynamic>?;
    final a = json['area'] as Map<String, dynamic>?;
    return GtdTask(
      id: json['id'] as int,
      title: json['title'] as String,
      notes: json['notes'] as String?,
      status: GtdTaskStatus.fromJson(json['status'] as String),
      energy: json['energy'] != null
          ? GtdEnergy.fromJson(json['energy'] as String)
          : null,
      timeEstimate: json['time_estimate'] as int?,
      dueDate: json['due_date'] as String?,
      createdAt: json['created_at'] as String,
      project: p != null
          ? (id: p['id'] as int, title: p['title'] as String)
          : null,
      context: c != null
          ? (id: c['id'] as int, name: c['name'] as String, icon: c['icon'] as String)
          : null,
      area: a != null
          ? (id: a['id'] as int, name: a['name'] as String)
          : null,
    );
  }
}
