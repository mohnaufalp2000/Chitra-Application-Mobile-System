// ignore_for_file: public_member_api_docs, sort_constructors_first
// To parse this JSON data, do
//
//     final tireSpec = tireSpecFromJson(jsonString);

import 'dart:convert';

TireSpec tireSpecFromJson(String str) => TireSpec.fromJson(json.decode(str));

String tireSpecToJson(TireSpec data) => json.encode(data.toJson());

class TireSpec {
  String? idTire;
  String? sn;
  String? size;
  String? pattern;
  String? brand;
  String? status;
  String? lifetime;
  String? lastJob;
  String? idSite;

  TireSpec({
    this.idTire,
    this.sn,
    this.size,
    this.pattern,
    this.brand,
    this.status,
    this.lifetime,
    this.lastJob,
    this.idSite,
  });

  factory TireSpec.fromJson(Map<String, dynamic> json) => TireSpec(
        idTire: json["id_tire"] ?? 'empty',
        sn: json["sn"] ?? 'empty',
        size: json["size"] ?? 'empty',
        pattern: json["pattern"] ?? 'empty',
        brand: json["brand"] ?? 'empty',
        status: json["status"] ?? 'empty',
        lifetime: json["lifetime"] ?? 'empty',
        // lastJob:
        //     json["last_job"] == null ? null : DateTime.parse(json["last_job"]),
        lastJob: json["last_job"] ?? 'empty',
        idSite: json["id_site"],
      );

  Map<String, dynamic> toJson() => {
        "id_tire": idTire,
        "sn": sn,
        "size": size,
        "pattern": pattern,
        "brand": brand,
        "status": status,
        "lifetime": lifetime,
        "last_job": lastJob,
        "id_site": idSite,
      };

  @override
  String toString() {
    return 'TireSpec(idTire: $idTire, sn: $sn, size: $size, pattern: $pattern, brand: $brand, status: $status, lifetime: $lifetime, lastJob: $lastJob, idSite: $idSite)';
  }
}
