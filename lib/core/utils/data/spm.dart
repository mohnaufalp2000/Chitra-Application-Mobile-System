// import 'dart:convert';
// import 'package:equatable/equatable.dart';

// Spm spmFromJson(String str) => Spm.fromJson(json.decode(str));
// String spmToJson(Spm data) => json.encode(data.toJson());

// class Spm extends Equatable {
//   final String? idtpms;
//   final String? devicename;
//   final String? timestamp;
//   final String? lat;
//   final String? alt;
//   final String? lon;

//   final String? pressure1;
//   final String? pressure2;
//   final String? pressure3;
//   final String? pressure4;
//   final String? pressure5;
//   final String? pressure6;

//   final String? temperature1;
//   final String? temperature2;
//   final String? temperature3;
//   final String? temperature4;
//   final String? temperature5;
//   final String? temperature6;

//   final String? press1;
//   final String? press2;
//   final String? press3;
//   final String? press4;
//   final String? press5;
//   final String? press6;

//   final String? totalpress;
//   final String? sumPress;

//   final String? idSite;

//   final String? rating1;
//   final String? rating2;
//   final String? rating3;
//   final String? rating4;
//   final String? rating5;
//   final String? rating6;

//   final String? temp1;
//   final String? temp2;
//   final String? temp3;
//   final String? temp4;
//   final String? temp5;
//   final String? temp6;

//   /// NEW FIELDS (as String)
//   final String? reccAdj1;
//   final String? reccAdj2;
//   final String? reccAdj3;
//   final String? reccAdj4;
//   final String? reccAdj5;
//   final String? reccAdj6;

//   final String? tyreLength;
//   final String? model;
//   final String? selish;

//   const Spm({
//     this.idtpms,
//     this.devicename,
//     this.timestamp,
//     this.lat,
//     this.alt,
//     this.lon,
//     this.pressure1,
//     this.pressure2,
//     this.pressure3,
//     this.pressure4,
//     this.pressure5,
//     this.pressure6,
//     this.temperature1,
//     this.temperature2,
//     this.temperature3,
//     this.temperature4,
//     this.temperature5,
//     this.temperature6,
//     this.press1,
//     this.press2,
//     this.press3,
//     this.press4,
//     this.press5,
//     this.press6,
//     this.totalpress,
//     this.sumPress,
//     this.idSite,
//     this.rating1 = 'N/A',
//     this.rating2 = 'N/A',
//     this.rating3 = 'N/A',
//     this.rating4 = 'N/A',
//     this.rating5 = 'N/A',
//     this.rating6 = 'N/A',
//     this.temp1,
//     this.temp2,
//     this.temp3,
//     this.temp4,
//     this.temp5,
//     this.temp6,
//     this.reccAdj1 = '',
//     this.reccAdj2 = '',
//     this.reccAdj3 = '',
//     this.reccAdj4 = '',
//     this.reccAdj5 = '',
//     this.reccAdj6 = '',

//     /// ✅ TAMBAHAN
//     this.tyreLength,
//     this.model,
//     this.selish,
//   });

//   Spm copyWith({
//     String? rating1,
//     String? rating2,
//     String? rating3,
//     String? rating4,
//     String? rating5,
//     String? rating6,
//     String? temp1,
//     String? temp2,
//     String? temp3,
//     String? temp4,
//     String? temp5,
//     String? temp6,
//     String? reccAdj1,
//     String? reccAdj2,
//     String? reccAdj3,
//     String? reccAdj4,
//     String? reccAdj5,
//     String? reccAdj6,
//     String? tyreLength,
//     String? model,
//     String? selish,
//   }) {
//     return Spm(
//       idtpms: idtpms,
//       devicename: devicename,
//       timestamp: timestamp,
//       lat: lat,
//       alt: alt,
//       lon: lon,
//       pressure1: pressure1,
//       pressure2: pressure2,
//       pressure3: pressure3,
//       pressure4: pressure4,
//       pressure5: pressure5,
//       pressure6: pressure6,
//       temperature1: temperature1,
//       temperature2: temperature2,
//       temperature3: temperature3,
//       temperature4: temperature4,
//       temperature5: temperature5,
//       temperature6: temperature6,
//       press1: press1,
//       press2: press2,
//       press3: press3,
//       press4: press4,
//       press5: press5,
//       press6: press6,
//       totalpress: totalpress,
//       sumPress: sumPress,
//       idSite: idSite,
//       rating1: rating1 ?? this.rating1,
//       rating2: rating2 ?? this.rating2,
//       rating3: rating3 ?? this.rating3,
//       rating4: rating4 ?? this.rating4,
//       rating5: rating5 ?? this.rating5,
//       rating6: rating6 ?? this.rating6,
//       temp1: temp1 ?? this.temp1,
//       temp2: temp2 ?? this.temp2,
//       temp3: temp3 ?? this.temp3,
//       temp4: temp4 ?? this.temp4,
//       temp5: temp5 ?? this.temp5,
//       temp6: temp6 ?? this.temp6,
//       reccAdj1: reccAdj1 ?? this.reccAdj1,
//       reccAdj2: reccAdj2 ?? this.reccAdj2,
//       reccAdj3: reccAdj3 ?? this.reccAdj3,
//       reccAdj4: reccAdj4 ?? this.reccAdj4,
//       reccAdj5: reccAdj5 ?? this.reccAdj5,
//       reccAdj6: reccAdj6 ?? this.reccAdj6,
//       tyreLength: tyreLength ?? this.tyreLength,
//       model: model ?? this.model,
//       selish: selish ?? this.selish,
//     );
//   }

//   factory Spm.fromJson(Map<String, dynamic> json) => Spm(
//         idtpms: json["idtpms"]?.toString() ?? '',
//         timestamp: json["timestamp"]?.toString() ?? '',
//         devicename: json["devicename"]?.toString() ?? '',
//         lat: json["lat"]?.toString() ?? '',
//         alt: json["alt"]?.toString() ?? '',
//         lon: json["lon"]?.toString() ?? '',
//         pressure1: json["pressure_1"]?.toString() ?? '',
//         pressure2: json["pressure_2"]?.toString() ?? '',
//         pressure3: json["pressure_3"]?.toString() ?? '',
//         pressure4: json["pressure_4"]?.toString() ?? '',
//         pressure5: json["pressure_5"]?.toString() ?? '',
//         pressure6: json["pressure_6"]?.toString() ?? '',
//         temperature1: json["temperature_1"]?.toString() ?? '',
//         temperature2: json["temperature_2"]?.toString() ?? '',
//         temperature3: json["temperature_3"]?.toString() ?? '',
//         temperature4: json["temperature_4"]?.toString() ?? '',
//         temperature5: json["temperature_5"]?.toString() ?? '',
//         temperature6: json["temperature_6"]?.toString() ?? '',
//         press1: json["press1"]?.toString() ?? '',
//         press2: json["press2"]?.toString() ?? '',
//         press3: json["press3"]?.toString() ?? '',
//         press4: json["press4"]?.toString() ?? '',
//         press5: json["press5"]?.toString() ?? '',
//         press6: json["press6"]?.toString() ?? '',
//         totalpress: json["totalpress"]?.toString() ?? '',
//         sumPress: json["sum_press"]?.toString() ?? '',
//         idSite: json["id_site"]?.toString() ?? '',
//         rating1: json["rating1"]?.toString() ?? 'N/A',
//         rating2: json["rating2"]?.toString() ?? 'N/A',
//         rating3: json["rating3"]?.toString() ?? 'N/A',
//         rating4: json["rating4"]?.toString() ?? 'N/A',
//         rating5: json["rating5"]?.toString() ?? 'N/A',
//         rating6: json["rating6"]?.toString() ?? 'N/A',
//         temp1: json["temp1"]?.toString() ?? '',
//         temp2: json["temp2"]?.toString() ?? '',
//         temp3: json["temp3"]?.toString() ?? '',
//         temp4: json["temp4"]?.toString() ?? '',
//         temp5: json["temp5"]?.toString() ?? '',
//         temp6: json["temp6"]?.toString() ?? '',
//         reccAdj1: json["recc_adj_1"]?.toString() ?? '',
//         reccAdj2: json["recc_adj_2"]?.toString() ?? '',
//         reccAdj3: json["recc_adj_3"]?.toString() ?? '',
//         reccAdj4: json["recc_adj_4"]?.toString() ?? '',
//         reccAdj5: json["recc_adj_5"]?.toString() ?? '',
//         reccAdj6: json["recc_adj_6"]?.toString() ?? '',
//         model: json["model"]?.toString() ?? '',
//         tyreLength: json["tyrelength"]?.toString() ?? '',
//         selish: json["selish"]?.toString() ?? '',
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
//         "rating1": rating1,
//         "rating2": rating2,
//         "rating3": rating3,
//         "rating4": rating4,
//         "rating5": rating5,
//         "rating6": rating6,
//         "temp1": temp1,
//         "temp2": temp2,
//         "temp3": temp3,
//         "temp4": temp4,
//         "temp5": temp5,
//         "temp6": temp6,
//         "recc_adj_1": reccAdj1,
//         "recc_adj_2": reccAdj2,
//         "recc_adj_3": reccAdj3,
//         "recc_adj_4": reccAdj4,
//         "recc_adj_5": reccAdj5,
//         "recc_adj_6": reccAdj6,
//         "model": model,
//         "tyrelength": tyreLength,
//         "selish": selish,
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
//         rating1,
//         rating2,
//         rating3,
//         rating4,
//         rating5,
//         rating6,
//         temp1,
//         temp2,
//         temp3,
//         temp4,
//         temp5,
//         temp6,
//         reccAdj1,
//         reccAdj2,
//         reccAdj3,
//         reccAdj4,
//         reccAdj5,
//         reccAdj6,
//         model,
//         tyreLength,
//         selish,
//       ];

//   @override
//   String toString() {
//     return 'Spm('
//         'idtpms: $idtpms, '
//         'devicename: $devicename, '
//         'model: $model, '
//         'tyreLength: $tyreLength, '
//         'selish: $selish, '
//         'timestamp: $timestamp, '
//         'lat: $lat, '
//         'lon: $lon, '
//         'alt: $alt, '
//         'pressure: [$pressure1, $pressure2, $pressure3, $pressure4, $pressure5, $pressure6], '
//         'temperature: [$temperature1, $temperature2, $temperature3, $temperature4, $temperature5, $temperature6], '
//         'press: [$press1, $press2, $press3, $press4, $press5, $press6], '
//         'rating: [$rating1, $rating2, $rating3, $rating4, $rating5, $rating6], '
//         'temp: [$temp1, $temp2, $temp3, $temp4, $temp5, $temp6], '
//         'reccAdj: [$reccAdj1, $reccAdj2, $reccAdj3, $reccAdj4, $reccAdj5, $reccAdj6], '
//         'totalpress: $totalpress, '
//         'sumPress: $sumPress, '
//         'idSite: $idSite'
//         ')';
//   }
// }

import 'dart:convert';
import 'package:equatable/equatable.dart';

Spm spmFromJson(String str) => Spm.fromJson(json.decode(str));
String spmToJson(Spm data) => json.encode(data.toJson());

class Spm extends Equatable {
  final String? idtpms;
  final String? devicename;
  final String? timestamp;
  final String? lat;
  final String? alt;
  final String? lon;

  final String? pressure1;
  final String? pressure2;
  final String? pressure3;
  final String? pressure4;
  final String? pressure5;
  final String? pressure6;

  final String? temperature1;
  final String? temperature2;
  final String? temperature3;
  final String? temperature4;
  final String? temperature5;
  final String? temperature6;

  final String? press1;
  final String? press2;
  final String? press3;
  final String? press4;
  final String? press5;
  final String? press6;

  final String? totalpress;
  final String? sumPress;

  final String? idSite;

  final String? rating1;
  final String? rating2;
  final String? rating3;
  final String? rating4;
  final String? rating5;
  final String? rating6;

  final String? temp1;
  final String? temp2;
  final String? temp3;
  final String? temp4;
  final String? temp5;
  final String? temp6;

  final String? reccAdj1;
  final String? reccAdj2;
  final String? reccAdj3;
  final String? reccAdj4;
  final String? reccAdj5;
  final String? reccAdj6;

  final String? tyreLength;
  final String? model;
  final String? selish;

  /// NEW FIELD
  final String? pressureUnit;

  const Spm({
    this.idtpms,
    this.devicename,
    this.timestamp,
    this.lat,
    this.alt,
    this.lon,
    this.pressure1,
    this.pressure2,
    this.pressure3,
    this.pressure4,
    this.pressure5,
    this.pressure6,
    this.temperature1,
    this.temperature2,
    this.temperature3,
    this.temperature4,
    this.temperature5,
    this.temperature6,
    this.press1,
    this.press2,
    this.press3,
    this.press4,
    this.press5,
    this.press6,
    this.totalpress,
    this.sumPress,
    this.idSite,
    this.rating1 = 'N/A',
    this.rating2 = 'N/A',
    this.rating3 = 'N/A',
    this.rating4 = 'N/A',
    this.rating5 = 'N/A',
    this.rating6 = 'N/A',
    this.temp1,
    this.temp2,
    this.temp3,
    this.temp4,
    this.temp5,
    this.temp6,
    this.reccAdj1 = '',
    this.reccAdj2 = '',
    this.reccAdj3 = '',
    this.reccAdj4 = '',
    this.reccAdj5 = '',
    this.reccAdj6 = '',
    this.tyreLength,
    this.model,
    this.selish,

    /// NEW
    this.pressureUnit,
  });

  Spm copyWith({
    String? rating1,
    String? rating2,
    String? rating3,
    String? rating4,
    String? rating5,
    String? rating6,
    String? temp1,
    String? temp2,
    String? temp3,
    String? temp4,
    String? temp5,
    String? temp6,
    String? reccAdj1,
    String? reccAdj2,
    String? reccAdj3,
    String? reccAdj4,
    String? reccAdj5,
    String? reccAdj6,
    String? tyreLength,
    String? model,
    String? selish,
    String? pressureUnit,
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
      temp1: temp1 ?? this.temp1,
      temp2: temp2 ?? this.temp2,
      temp3: temp3 ?? this.temp3,
      temp4: temp4 ?? this.temp4,
      temp5: temp5 ?? this.temp5,
      temp6: temp6 ?? this.temp6,
      reccAdj1: reccAdj1 ?? this.reccAdj1,
      reccAdj2: reccAdj2 ?? this.reccAdj2,
      reccAdj3: reccAdj3 ?? this.reccAdj3,
      reccAdj4: reccAdj4 ?? this.reccAdj4,
      reccAdj5: reccAdj5 ?? this.reccAdj5,
      reccAdj6: reccAdj6 ?? this.reccAdj6,
      tyreLength: tyreLength ?? this.tyreLength,
      model: model ?? this.model,
      selish: selish ?? this.selish,
      pressureUnit: pressureUnit ?? this.pressureUnit,
    );
  }

  factory Spm.fromJson(Map<String, dynamic> json) => Spm(
        idtpms: json["idtpms"]?.toString() ?? '',
        timestamp: json["timestamp"]?.toString() ?? '',
        devicename: json["devicename"]?.toString() ?? '',
        lat: json["lat"]?.toString() ?? '',
        alt: json["alt"]?.toString() ?? '',
        lon: json["lon"]?.toString() ?? '',
        pressure1: json["pressure_1"]?.toString() ?? '',
        pressure2: json["pressure_2"]?.toString() ?? '',
        pressure3: json["pressure_3"]?.toString() ?? '',
        pressure4: json["pressure_4"]?.toString() ?? '',
        pressure5: json["pressure_5"]?.toString() ?? '',
        pressure6: json["pressure_6"]?.toString() ?? '',
        temperature1: json["temperature_1"]?.toString() ?? '',
        temperature2: json["temperature_2"]?.toString() ?? '',
        temperature3: json["temperature_3"]?.toString() ?? '',
        temperature4: json["temperature_4"]?.toString() ?? '',
        temperature5: json["temperature_5"]?.toString() ?? '',
        temperature6: json["temperature_6"]?.toString() ?? '',
        press1: json["press1"]?.toString() ?? '',
        press2: json["press2"]?.toString() ?? '',
        press3: json["press3"]?.toString() ?? '',
        press4: json["press4"]?.toString() ?? '',
        press5: json["press5"]?.toString() ?? '',
        press6: json["press6"]?.toString() ?? '',
        totalpress: json["totalpress"]?.toString() ?? '',
        sumPress: json["sum_press"]?.toString() ?? '',
        idSite: json["id_site"]?.toString() ?? '',
        rating1: json["rating1"]?.toString() ?? 'N/A',
        rating2: json["rating2"]?.toString() ?? 'N/A',
        rating3: json["rating3"]?.toString() ?? 'N/A',
        rating4: json["rating4"]?.toString() ?? 'N/A',
        rating5: json["rating5"]?.toString() ?? 'N/A',
        rating6: json["rating6"]?.toString() ?? 'N/A',
        temp1: json["temp1"]?.toString() ?? '',
        temp2: json["temp2"]?.toString() ?? '',
        temp3: json["temp3"]?.toString() ?? '',
        temp4: json["temp4"]?.toString() ?? '',
        temp5: json["temp5"]?.toString() ?? '',
        temp6: json["temp6"]?.toString() ?? '',
        reccAdj1: json["recc_adj_1"]?.toString() ?? '',
        reccAdj2: json["recc_adj_2"]?.toString() ?? '',
        reccAdj3: json["recc_adj_3"]?.toString() ?? '',
        reccAdj4: json["recc_adj_4"]?.toString() ?? '',
        reccAdj5: json["recc_adj_5"]?.toString() ?? '',
        reccAdj6: json["recc_adj_6"]?.toString() ?? '',
        model: json["model"]?.toString() ?? '',
        tyreLength: json["tyrelength"]?.toString() ?? '',
        selish: json["selish"]?.toString() ?? '',
        pressureUnit: json["pressure_unit"]?.toString() ?? '',
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
        "temp1": temp1,
        "temp2": temp2,
        "temp3": temp3,
        "temp4": temp4,
        "temp5": temp5,
        "temp6": temp6,
        "recc_adj_1": reccAdj1,
        "recc_adj_2": reccAdj2,
        "recc_adj_3": reccAdj3,
        "recc_adj_4": reccAdj4,
        "recc_adj_5": reccAdj5,
        "recc_adj_6": reccAdj6,
        "model": model,
        "tyrelength": tyreLength,
        "selish": selish,
        "pressure_unit": pressureUnit,
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
        temp1,
        temp2,
        temp3,
        temp4,
        temp5,
        temp6,
        reccAdj1,
        reccAdj2,
        reccAdj3,
        reccAdj4,
        reccAdj5,
        reccAdj6,
        model,
        tyreLength,
        selish,
        pressureUnit,
      ];

  @override
  String toString() {
    return 'Spm('
        'idtpms: $idtpms, '
        'devicename: $devicename, '
        'model: $model, '
        'tyreLength: $tyreLength, '
        'selish: $selish, '
        'pressureUnit: $pressureUnit, '
        'timestamp: $timestamp, '
        'lat: $lat, '
        'lon: $lon, '
        'alt: $alt, '
        'pressure: [$pressure1, $pressure2, $pressure3, $pressure4, $pressure5, $pressure6], '
        'temperature: [$temperature1, $temperature2, $temperature3, $temperature4, $temperature5, $temperature6], '
        'press: [$press1, $press2, $press3, $press4, $press5, $press6], '
        'rating: [$rating1, $rating2, $rating3, $rating4, $rating5, $rating6], '
        'temp: [$temp1, $temp2, $temp3, $temp4, $temp5, $temp6], '
        'reccAdj: [$reccAdj1, $reccAdj2, $reccAdj3, $reccAdj4, $reccAdj5, $reccAdj6], '
        'totalpress: $totalpress, '
        'sumPress: $sumPress, '
        'idSite: $idSite'
        ')';
  }
}
