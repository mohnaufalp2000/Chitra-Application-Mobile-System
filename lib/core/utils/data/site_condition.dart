// ignore_for_file: public_member_api_docs, sort_constructors_first
class SiteCondition {
  String name;
  double latitude;
  double longitude;
  String remarks;
  String date;
  List<String> image;

  SiteCondition({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.remarks,
    required this.date,
    required this.image,
  });

  @override
  String toString() {
    return 'SiteCondition(name: $name, latitude: $latitude, longitude: $longitude, remarks: $remarks, image: $image)';
  }
}
