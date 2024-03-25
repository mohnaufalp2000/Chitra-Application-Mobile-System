// ignore_for_file: public_member_api_docs, sort_constructors_first
class OustandingTask {
  final DateTime id;
  final String serialNumber;
  final List<dynamic> condition;
  final String tireSize;
  final int position;
  final String unit;
  final String tireDamage;
  final String remarks;

  OustandingTask({
    required this.id,
    required this.serialNumber,
    required this.condition,
    required this.tireSize,
    required this.position,
    required this.unit,
    required this.tireDamage,
    required this.remarks,
  });
}

var listOustandingTask = [];
