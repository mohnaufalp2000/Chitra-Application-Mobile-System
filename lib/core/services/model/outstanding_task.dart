// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

class OutstandingTask {
  final String id;
  final String idSite;
  final String user;
  final String unit;
  final String serialNumber;
  final List<String> condition;
  final String tireSize;
  final int position;
  final String brand;
  final String tireDamage;
  final String remarks;
  final String rtd;
  final String pressure;
  final String lastUpdate;
  final bool isDone;
  final List<String>? images;
  final String sn;
  final String kunciUnit;
  final String kunciTire;
  OutstandingTask({
    required this.id,
    required this.idSite,
    required this.user,
    required this.unit,
    required this.serialNumber,
    required this.condition,
    required this.tireSize,
    required this.position,
    required this.brand,
    required this.tireDamage,
    required this.remarks,
    required this.rtd,
    required this.pressure,
    required this.lastUpdate,
    required this.isDone,
    required this.images,
    required this.sn,
    required this.kunciUnit,
    required this.kunciTire,
  });
}
