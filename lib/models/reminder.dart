class Reminder {
  final String id;
  final String title;
  final String date;
  final int daysLeft;
  final String urgency; // Importante, Normal
  final String status; // pending, completed

  Reminder({
    required this.id,
    required this.title,
    required this.date,
    required this.daysLeft,
    required this.urgency,
    required this.status,
  });

  Reminder copyWith({
    String? id,
    String? title,
    String? date,
    int? daysLeft,
    String? urgency,
    String? status,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      daysLeft: daysLeft ?? this.daysLeft,
      urgency: urgency ?? this.urgency,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date,
        'days_left': daysLeft,
        'urgency': urgency,
        'status': status,
      };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
        id: json['id'] as String,
        title: json['title'] as String,
        date: json['date'] as String,
        daysLeft: (json['days_left'] ?? json['daysLeft']) as int,
        urgency: json['urgency'] as String,
        status: json['status'] as String,
      );
}
