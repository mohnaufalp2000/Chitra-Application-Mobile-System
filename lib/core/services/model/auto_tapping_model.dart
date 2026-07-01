import 'package:meta/meta.dart';
import 'dart:convert';

class AutoTappingModel {
  String id;
  String devicename;
  String posisi;
  String sn;
  String pressureBefore;
  String pressureAfter;
  String timestampBefore;
  String timestampAfter;
  String idSite;
  String insertTime;

  AutoTappingModel({
    required this.id,
    required this.devicename,
    required this.posisi,
    required this.sn,
    required this.pressureBefore,
    required this.pressureAfter,
    required this.timestampBefore,
    required this.timestampAfter,
    required this.idSite,
    required this.insertTime,
  });

  AutoTappingModel copyWith({
    String? id,
    String? devicename,
    String? posisi,
    String? sn,
    String? pressureBefore,
    String? pressureAfter,
    String? timestampBefore,
    String? timestampAfter,
    String? idSite,
    String? insertTime,
  }) =>
      AutoTappingModel(
        id: id ?? this.id,
        devicename: devicename ?? this.devicename,
        posisi: posisi ?? this.posisi,
        sn: sn ?? this.sn,
        pressureBefore: pressureBefore ?? this.pressureBefore,
        pressureAfter: pressureAfter ?? this.pressureAfter,
        timestampBefore: timestampBefore ?? this.timestampBefore,
        timestampAfter: timestampAfter ?? this.timestampAfter,
        idSite: idSite ?? this.idSite,
        insertTime: insertTime ?? this.insertTime,
      );

  factory AutoTappingModel.fromJson(String str) =>
      AutoTappingModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory AutoTappingModel.fromMap(Map<String, dynamic> json) =>
      AutoTappingModel(
        id: json["id"].toString(),
        devicename: json["devicename"].toString(),
        posisi: json["posisi"].toString(),
        sn: json["sn"].toString(),
        pressureBefore: json["pressure_before"].toString(),
        pressureAfter: json["pressure_after"].toString(),
        timestampBefore: json["timestamp_before"].toString(),
        timestampAfter: json["timestamp_after"].toString(),
        idSite: json["id_site"].toString(),
        insertTime: json["insert_time"].toString(),
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "devicename": devicename,
        "posisi": posisi,
        "sn": sn,
        "pressure_before": pressureBefore,
        "pressure_after": pressureAfter,
        "timestamp_before": timestampBefore,
        "timestamp_after": timestampAfter,
        "id_site": idSite,
        "insert_time": insertTime,
      };
}
