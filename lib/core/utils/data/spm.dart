// To parse this JSON data, do
//
//     final spm = spmFromJson(jsonString);

import 'dart:convert';

Spm spmFromJson(String str) => Spm.fromJson(json.decode(str));

String spmToJson(Spm data) => json.encode(data.toJson());

class Spm {
  String idtpms;
  String timestamp;
  String devicename;
  String lat;
  String alt;
  String lon;
  String pressure1;
  String pressure2;
  String pressure3;
  String pressure4;
  String pressure5;
  String pressure6;
  String temperature1;
  String temperature2;
  String temperature3;
  String temperature4;
  String temperature5;
  String temperature6;
  String press1;
  String press2;
  String press3;
  String press4;
  String press5;
  String press6;
  String totalpress;
  String sumPress;
  String idSite;

  Spm({
    required this.idtpms,
    required this.timestamp,
    required this.devicename,
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
  });

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
      };

  @override
  String toString() {
    return 'Spm{idtpms: $idtpms, timestamp: $timestamp, devicename: $devicename, lat: $lat, alt: $alt, lon: $lon, pressure1: $pressure1, pressure2: $pressure2, pressure3: $pressure3, pressure4: $pressure4, pressure5: $pressure5, pressure6: $pressure6, temperature1: $temperature1, temperature2: $temperature2, temperature3: $temperature3, temperature4: $temperature4, temperature5: $temperature5, temperature6: $temperature6, press1: $press1, press2: $press2, press3: $press3, press4: $press4, press5: $press5, press6: $press6, totalpress: $totalpress, sumPress: $sumPress, idSite: $idSite}';
  }
}
