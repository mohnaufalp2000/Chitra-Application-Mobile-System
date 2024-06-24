import 'package:objectbox/objectbox.dart';

// untuk menampung data site condition
@Entity()
class SiteConditionEntity {
  int id;

  final String siteConditionId;
  final String name;
  final double latitude;
  final double longitude;
  final String remarks;
  final String date;
  final List<String> image;

  SiteConditionEntity(
      {this.id = 0,
      required this.name,
      this.siteConditionId = '',
      required this.latitude,
      required this.longitude,
      required this.remarks,
      required this.date,
      required this.image});

  @override
  String toString() {
    return 'SiteConditionEntity(id: $id, name: $name, latitude: $latitude, longitude: $longitude, remarks: $remarks, image: $image)';
  }
}
