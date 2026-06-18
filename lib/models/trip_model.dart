class Trip {
  final int? id;
  final String title;
  final String startDate;

  Trip({this.id, required this.title, required this.startDate});

  // 給 SQLite 用的轉換
  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'startDate': startDate};
  }
}