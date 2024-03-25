// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class SiteTrack {
  final String nameTrack;
  final Uint8List? mapTrack;
  final XFile? hazardPicture;
  final double latitude;
  final double longitude;
  final double altitude;
  SiteTrack({
    required this.nameTrack,
    required this.mapTrack,
    required this.hazardPicture,
    required this.latitude,
    required this.longitude,
    required this.altitude,
  });

  @override
  String toString() {
    return 'SiteTrack(mapTrack: $mapTrack, hazardPicture: $hazardPicture, latitude: $latitude, longitude: $longitude, altitude: $altitude)';
  }
}
