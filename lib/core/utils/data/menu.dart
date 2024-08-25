// ignore_for_file: public_member_api_docs, sort_constructors_first
class Menu {
  final int id;
  final String name;
  final String image;
  Menu({
    required this.id,
    required this.name,
    required this.image,
  });
}

var menus = [
  Menu(id: 1, name: 'Inspection Tire', image: 'pressure_gauge_icon.png'),
  // Menu(id: 1, name: 'Pressure Gauge Digital', image: 'pressure_gauge_icon.png'),
  Menu(id: 2, name: 'Site Condition', image: 'site_condition_icon.png'),
  Menu(id: 3, name: 'TKPH Calculator', image: 'tkph_calculator_icon.png'),
  // Menu(id: 4, name: 'Tire Repair Form', image: 'tire_repair_icon.png'),
  Menu(id: 4, name: 'CTS', image: 'cts_logo_icon.png'),
  Menu(id: 5, name: 'TPMS', image: 'tpms_icon.png'),
  Menu(id: 6, name: 'Attendance', image: 'attendance_icon.png'),
];
