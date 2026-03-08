class PeopleCountModel {
  final String id;
  final DateTime timestamp;
  final int inCount;
  final int outCount;
  final int totalPeople;
  final int frameNumber;

  const PeopleCountModel({
    required this.id,
    required this.timestamp,
    required this.inCount,
    required this.outCount,
    required this.totalPeople,
    required this.frameNumber,
  });

  factory PeopleCountModel.fromJson(Map<String, dynamic> json) {
    return PeopleCountModel(
      id: json['_id'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      inCount: json['in_count'] ?? 0,
      outCount: json['out_count'] ?? 0,
      totalPeople: json['total_people'] ?? 0,
      frameNumber: json['frame_number'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'timestamp': timestamp.toIso8601String(),
      'in_count': inCount,
      'out_count': outCount,
      'total_people': totalPeople,
      'frame_number': frameNumber,
    };
  }
}
