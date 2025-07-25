import 'dart:convert';
import 'package:equatable/equatable.dart';

Spm spmFromJson(String str) => Spm.fromJson(json.decode(str));
String spmToJson(Spm data) => json.encode(data.toJson());

class Spm extends Equatable {
  final String idtpms;
  final String devicename;
  final String timestamp;
  final String lat;
  final String alt;
  final String lon;
  final String pressure1;
  final String pressure2;
  final String pressure3;
  final String pressure4;
  final String pressure5;
  final String pressure6;
  final String temperature1;
  final String temperature2;
  final String temperature3;
  final String temperature4;
  final String temperature5;
  final String temperature6;
  final String press1;
  final String press2;
  final String press3;
  final String press4;
  final String press5;
  final String press6;
  final String totalpress;
  final String sumPress;
  final String idSite;
  final String rating1;
  final String rating2;
  final String rating3;
  final String rating4;
  final String rating5;
  final String rating6;

  const Spm({
    required this.idtpms,
    required this.devicename,
    required this.timestamp,
    required this.lat,
    required this.alt,
    required this.lon,
    required this.pressure1,
    required this.pressure2,
    required this.pressure3,
    required this.pressure4,
    required this.pressure5,
    required this.pressure6,
    required this.temperature1,
    required this.temperature2,
    required this.temperature3,
    required this.temperature4,
    required this.temperature5,
    required this.temperature6,
    required this.press1,
    required this.press2,
    required this.press3,
    required this.press4,
    required this.press5,
    required this.press6,
    required this.totalpress,
    required this.sumPress,
    required this.idSite,
    this.rating1 = 'N/A',
    this.rating2 = 'N/A',
    this.rating3 = 'N/A',
    this.rating4 = 'N/A',
    this.rating5 = 'N/A',
    this.rating6 = 'N/A',
  });

  Spm copyWith({
    String? rating1,
    String? rating2,
    String? rating3,
    String? rating4,
    String? rating5,
    String? rating6,
  }) {
    return Spm(
      idtpms: idtpms,
      devicename: devicename,
      timestamp: timestamp,
      lat: lat,
      alt: alt,
      lon: lon,
      pressure1: pressure1,
      pressure2: pressure2,
      pressure3: pressure3,
      pressure4: pressure4,
      pressure5: pressure5,
      pressure6: pressure6,
      temperature1: temperature1,
      temperature2: temperature2,
      temperature3: temperature3,
      temperature4: temperature4,
      temperature5: temperature5,
      temperature6: temperature6,
      press1: press1,
      press2: press2,
      press3: press3,
      press4: press4,
      press5: press5,
      press6: press6,
      totalpress: totalpress,
      sumPress: sumPress,
      idSite: idSite,
      rating1: rating1 ?? this.rating1,
      rating2: rating2 ?? this.rating2,
      rating3: rating3 ?? this.rating3,
      rating4: rating4 ?? this.rating4,
      rating5: rating5 ?? this.rating5,
      rating6: rating6 ?? this.rating6,
    );
  }

  factory Spm.fromJson(Map<String, dynamic> json) => Spm(
        idtpms: json["idtpms"] ?? '',
        timestamp: json["timestamp"] ?? '',
        devicename: json["devicename"] ?? '',
        lat: json["lat"] ?? '',
        alt: json["alt"] ?? '',
        lon: json["lon"] ?? '',
        pressure1: json["pressure_1"] ?? '',
        pressure2: json["pressure_2"] ?? '',
        pressure3: json["pressure_3"] ?? '',
        pressure4: json["pressure_4"] ?? '',
        pressure5: json["pressure_5"] ?? '',
        pressure6: json["pressure_6"] ?? '',
        temperature1: json["temperature_1"] ?? '',
        temperature2: json["temperature_2"] ?? '',
        temperature3: json["temperature_3"] ?? '',
        temperature4: json["temperature_4"] ?? '',
        temperature5: json["temperature_5"] ?? '',
        temperature6: json["temperature_6"] ?? '',
        press1: json["press1"] ?? '',
        press2: json["press2"] ?? '',
        press3: json["press3"] ?? '',
        press4: json["press4"] ?? '',
        press5: json["press5"] ?? '',
        press6: json["press6"] ?? '',
        totalpress: json["totalpress"] ?? '',
        sumPress: json["sum_press"] ?? '',
        idSite: json["id_site"] ?? '',
      );

  Map<String, dynamic> toJson() => {
        "idtpms": idtpms,
        "timestamp": timestamp,
        "devicename": devicename,
        "lat": lat,
        "alt": alt,
        "lon": lon,
        "pressure_1": pressure1,
        "pressure_2": pressure2,
        "pressure_3": pressure3,
        "pressure_4": pressure4,
        "pressure_5": pressure5,
        "pressure_6": pressure6,
        "temperature_1": temperature1,
        "temperature_2": temperature2,
        "temperature_3": temperature3,
        "temperature_4": temperature4,
        "temperature_5": temperature5,
        "temperature_6": temperature6,
        "press1": press1,
        "press2": press2,
        "press3": press3,
        "press4": press4,
        "press5": press5,
        "press6": press6,
        "totalpress": totalpress,
        "sum_press": sumPress,
        "id_site": idSite,
        "rating1": rating1,
        "rating2": rating2,
        "rating3": rating3,
        "rating4": rating4,
        "rating5": rating5,
        "rating6": rating6,
      };

  @override
  List<Object?> get props => [
        idtpms,
        timestamp,
        devicename,
        lat,
        alt,
        lon,
        pressure1,
        pressure2,
        pressure3,
        pressure4,
        pressure5,
        pressure6,
        temperature1,
        temperature2,
        temperature3,
        temperature4,
        temperature5,
        temperature6,
        press1,
        press2,
        press3,
        press4,
        press5,
        press6,
        totalpress,
        sumPress,
        idSite,
        rating1,
        rating2,
        rating3,
        rating4,
        rating5,
        rating6,
      ];
}

// import 'dart:convert';
// import 'package:equatable/equatable.dart';

// Spm spmFromJson(String str) => Spm.fromJson(json.decode(str));

// String spmToJson(Spm data) => json.encode(data.toJson());

// class Spm extends Equatable {
//   final String idtpms;
//   final String timestamp;
//   final String devicename;
//   final String lat;
//   final String alt;
//   final String lon;
//   final String pressure1;
//   final String pressure2;
//   final String pressure3;
//   final String pressure4;
//   final String pressure5;
//   final String pressure6;
//   final String temperature1;
//   final String temperature2;
//   final String temperature3;
//   final String temperature4;
//   final String temperature5;
//   final String temperature6;
//   final String press1;
//   final String press2;
//   final String press3;
//   final String press4;
//   final String press5;
//   final String press6;
//   final String totalpress;
//   final String sumPress;
//   final String idSite;

//   const Spm({
//     required this.idtpms,
//     required this.timestamp,
//     required this.devicename,
//     required this.lat,
//     required this.alt,
//     required this.lon,
//     required this.pressure1,
//     required this.pressure2,
//     required this.pressure3,
//     required this.pressure4,
//     required this.pressure5,
//     required this.pressure6,
//     required this.temperature1,
//     required this.temperature2,
//     required this.temperature3,
//     required this.temperature4,
//     required this.temperature5,
//     required this.temperature6,
//     required this.press1,
//     required this.press2,
//     required this.press3,
//     required this.press4,
//     required this.press5,
//     required this.press6,
//     required this.totalpress,
//     required this.sumPress,
//     required this.idSite,
//   });

//   factory Spm.fromJson(Map<String, dynamic> json) => Spm(
//         idtpms: json["idtpms"] ?? '',
//         timestamp: json["timestamp"] ?? '',
//         devicename: json["devicename"] ?? '',
//         lat: json["lat"] ?? '',
//         alt: json["alt"] ?? '',
//         lon: json["lon"] ?? '',
//         pressure1: json["pressure_1"] ?? '',
//         pressure2: json["pressure_2"] ?? '',
//         pressure3: json["pressure_3"] ?? '',
//         pressure4: json["pressure_4"] ?? '',
//         pressure5: json["pressure_5"] ?? '',
//         pressure6: json["pressure_6"] ?? '',
//         temperature1: json["temperature_1"] ?? '',
//         temperature2: json["temperature_2"] ?? '',
//         temperature3: json["temperature_3"] ?? '',
//         temperature4: json["temperature_4"] ?? '',
//         temperature5: json["temperature_5"] ?? '',
//         temperature6: json["temperature_6"] ?? '',
//         press1: json["press1"] ?? '',
//         press2: json["press2"] ?? '',
//         press3: json["press3"] ?? '',
//         press4: json["press4"] ?? '',
//         press5: json["press5"] ?? '',
//         press6: json["press6"] ?? '',
//         totalpress: json["totalpress"] ?? '',
//         sumPress: json["sum_press"] ?? '',
//         idSite: json["id_site"] ?? '',
//       );

//   Map<String, dynamic> toJson() => {
//         "idtpms": idtpms,
//         "timestamp": timestamp,
//         "devicename": devicename,
//         "lat": lat,
//         "alt": alt,
//         "lon": lon,
//         "pressure_1": pressure1,
//         "pressure_2": pressure2,
//         "pressure_3": pressure3,
//         "pressure_4": pressure4,
//         "pressure_5": pressure5,
//         "pressure_6": pressure6,
//         "temperature_1": temperature1,
//         "temperature_2": temperature2,
//         "temperature_3": temperature3,
//         "temperature_4": temperature4,
//         "temperature_5": temperature5,
//         "temperature_6": temperature6,
//         "press1": press1,
//         "press2": press2,
//         "press3": press3,
//         "press4": press4,
//         "press5": press5,
//         "press6": press6,
//         "totalpress": totalpress,
//         "sum_press": sumPress,
//         "id_site": idSite,
//       };

//   @override
//   List<Object?> get props => [
//         idtpms,
//         timestamp,
//         devicename,
//         lat,
//         alt,
//         lon,
//         pressure1,
//         pressure2,
//         pressure3,
//         pressure4,
//         pressure5,
//         pressure6,
//         temperature1,
//         temperature2,
//         temperature3,
//         temperature4,
//         temperature5,
//         temperature6,
//         press1,
//         press2,
//         press3,
//         press4,
//         press5,
//         press6,
//         totalpress,
//         sumPress,
//         idSite,
//       ];

//   @override
//   String toString() {
//     return 'Spm{idtpms: $idtpms, timestamp: $timestamp, devicename: $devicename, lat: $lat, alt: $alt, lon: $lon, pressure1: $pressure1, pressure2: $pressure2, pressure3: $pressure3, pressure4: $pressure4, pressure5: $pressure5, pressure6: $pressure6, temperature1: $temperature1, temperature2: $temperature2, temperature3: $temperature3, temperature4: $temperature4, temperature5: $temperature5, temperature6: $temperature6, press1: $press1, press2: $press2, press3: $press3, press4: $press4, press5: $press5, press6: $press6, totalpress: $totalpress, sumPress: $sumPress, idSite: $idSite}';
//   }
// }
