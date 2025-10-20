// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

class Menu {
  final int id;
  final String name;
  final String image;
  final Color color;
  Menu(
      {required this.id,
      required this.name,
      required this.image,
      required this.color});
}

var menus = [
  Menu(
      id: 1,
      name: 'Inspection Tire',
      image: 'pressure_gauge_icon.png',
      color: Colors.red),
  // Menu(id: 1, name: 'Pressure Gauge Digital', image: 'pressure_gauge_icon.png'),
  Menu(
      id: 2,
      name: 'Site Condition',
      image: 'site_condition_icon.png',
      color: Colors.orange),
  Menu(
      id: 3,
      name: 'TKPH Calculator',
      image: 'tkph_calculator_icon.png',
      color: Colors.green.shade400),
  Menu(id: 4, name: 'TPMS/SPM', image: 'tpms_icon.png', color: Colors.orange),
  Menu(
      id: 5,
      name: 'Tire Repair Form',
      image: 'tire_repair_icon.png',
      color: Colors.blue),
  // Menu(id: 4, name: 'CTS', image: 'cts_logo_icon.png'),

  Menu(
      id: 6,
      name: 'Attendance',
      image: 'attendance_icon.png',
      color: Colors.blue),
];
