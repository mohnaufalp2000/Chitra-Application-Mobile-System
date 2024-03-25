class DailyPressure {
  final DateTime id;
  final String date;
  final String unit;
  final String pressure;
  final int position;
  final List<String> damage;
  final String pit;

  DailyPressure(
      {required this.id,
      required this.date,
      required this.unit,
      required this.pressure,
      required this.position,
      required this.damage,
      required this.pit});
}
