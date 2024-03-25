// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:objectbox/objectbox.dart';

@Entity()
class OutstandingTaskEntity {
  int id;
  final String idTask;
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
  final String pressure;
  final String lastUpdate;
  final bool isDone;

  OutstandingTaskEntity({
    this.id = 0,
    this.idTask = '',
    this.idSite = '',
    this.user = '',
    this.unit = '',
    this.serialNumber = '',
    this.tireSize = '',
    this.condition = const [],
    this.position = 0,
    this.brand = '',
    this.tireDamage = '',
    this.remarks = '',
    this.pressure = '',
    this.lastUpdate = '',
    this.isDone = false,
  });

  @override
  String toString() {
    return 'OutstandingTaskEntity(id: $id, idTask: $idTask, idSite: $idSite, user: $user, unit: $unit, serialNumber: $serialNumber, condition: $condition, tireSize: $tireSize, position: $position, brand: $brand, tireDamage: $tireDamage, remarks: $remarks, pressure: $pressure, lastUpdate: $lastUpdate, isDone: $isDone)';
  }
}
