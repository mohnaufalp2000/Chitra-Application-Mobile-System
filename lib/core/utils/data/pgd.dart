// ignore_for_file: public_member_api_docs, sort_constructors_first
class Pgd {
  final int position;
  final String pressure;
  final String tireDamage;
  final String remarks;
  final List<Map<String, dynamic>> category;
  Pgd({
    required this.position,
    required this.pressure,
    required this.tireDamage,
    required this.remarks,
    required this.category,
  });
}
