// To parse this JSON data, do
//
//     final dailyCheckFirebase = dailyCheckFirebaseFromJson(jsonString);

import 'dart:convert';

DailyCheckFirebase dailyCheckFirebaseFromJson(String str) =>
    DailyCheckFirebase.fromJson(json.decode(str));

String dailyCheckFirebaseToJson(DailyCheckFirebase data) =>
    json.encode(data.toJson());

class DailyCheckFirebase {
  final String idSite;
  final String pit;
  final List<Posisi> posisi;
  final String tanggal;
  final String unit;
  final String user;
  final String hm;

  DailyCheckFirebase({
    required this.idSite,
    required this.pit,
    required this.posisi,
    required this.tanggal,
    required this.unit,
    required this.user,
    required this.hm,
  });

  DailyCheckFirebase copyWith({
    String? idSite,
    String? pit,
    List<Posisi>? posisi,
    String? tanggal,
    String? unit,
    String? user,
    String? hm,
  }) =>
      DailyCheckFirebase(
        idSite: idSite ?? this.idSite,
        pit: pit ?? this.pit,
        posisi: posisi ?? this.posisi,
        tanggal: tanggal ?? this.tanggal,
        unit: unit ?? this.unit,
        user: user ?? this.user,
        hm: hm ?? this.hm,
      );

  factory DailyCheckFirebase.fromJson(Map<String, dynamic> json) =>
      DailyCheckFirebase(
        idSite: json["idSite"],
        pit: json["pit"],
        posisi:
            List<Posisi>.from(json["posisi"].map((x) => Posisi.fromJson(x))),
        tanggal: json["tanggal"],
        unit: json["unit"],
        user: json["user"],
        hm: json["hm"],
      );

  Map<String, dynamic> toJson() => {
        "idSite": idSite,
        "pit": pit,
        "posisi": List<dynamic>.from(posisi.map((x) => x.toJson())),
        "tanggal": tanggal,
        "unit": unit,
        "user": user,
        "hm": hm,
      };
}

class Posisi {
  final String adjusmentPressure;
  final List<String> luka;
  final String pos;
  final String pressure;

  Posisi({
    required this.adjusmentPressure,
    required this.luka,
    required this.pos,
    required this.pressure,
  });

  Posisi copyWith({
    String? adjusmentPressure,
    List<String>? luka,
    String? pos,
    String? pressure,
  }) =>
      Posisi(
        adjusmentPressure: adjusmentPressure ?? this.adjusmentPressure,
        luka: luka ?? this.luka,
        pos: pos ?? this.pos,
        pressure: pressure ?? this.pressure,
      );

  factory Posisi.fromJson(Map<String, dynamic> json) => Posisi(
        adjusmentPressure: json["adjusmentPressure"],
        luka: json["luka"] != null
            ? List<String>.from(json["luka"].map((x) => x))
            : [],
        pos: json["pos"],
        pressure: json["pressure"],
      );

  Map<String, dynamic> toJson() => {
        "adjusmentPressure": adjusmentPressure,
        "luka": List<dynamic>.from(luka.map((x) => x)),
        "pos": pos,
        "pressure": pressure,
      };
}
