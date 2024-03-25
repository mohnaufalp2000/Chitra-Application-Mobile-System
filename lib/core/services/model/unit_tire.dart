// ignore_for_file: public_member_api_docs, sort_constructors_first
// To parse this JSON data, do
//
//     final unitTire = unitTireFromJson(jsonString);

import 'dart:convert';

UnitTire unitTireFromJson(String str) => UnitTire.fromJson(json.decode(str));

String unitTireToJson(UnitTire data) => json.encode(data.toJson());

class UnitTire {
  String? unitNumber;
  String? posisi;
  String? model;
  String? status;
  String? hm;
  String? brand;
  String? size;
  String? pattern;
  String? otd;
  String? rtd;
  String? lifetime;
  String? hmOnJob;
  String? lifeOnJob;
  String? date;
  String? rating;
  String? site;
  String? sn;
  String? kunciUnit;
  String? kunciTire;

  UnitTire({
    this.unitNumber,
    this.posisi,
    this.model,
    this.status,
    this.hm,
    this.brand,
    this.size,
    this.pattern,
    this.otd,
    this.rtd,
    this.lifetime,
    this.hmOnJob,
    this.lifeOnJob,
    this.date,
    this.rating,
    this.site,
    this.sn,
    this.kunciUnit,
    this.kunciTire,
  });

  UnitTire.fromJson(Map<String, dynamic> json) {
    unitNumber = json['unit_number'];
    posisi = json['posisi'];
    model = json['model'];
    status = json['status'];
    hm = json['hm'];
    brand = json['brand'];
    size = json['size'];
    pattern = json['pattern'];
    otd = json['otd'];
    rtd = json['rtd'];
    lifetime = json['lifetime'];
    hmOnJob = json['hm_on_job'];
    lifeOnJob = json['life_on_job'];
    date = json['date'];
    rating = json['rating'];
    site = json['site'];
    sn = json['sn'];
    kunciUnit = json['kunci_unit'];
    kunciTire = json['kunci_tire'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['unit_number'] = this.unitNumber;
    data['posisi'] = this.posisi;
    data['model'] = this.model;
    data['status'] = this.status;
    data['hm'] = this.hm;
    data['brand'] = this.brand;
    data['size'] = this.size;
    data['pattern'] = this.pattern;
    data['otd'] = this.otd;
    data['rtd'] = this.rtd;
    data['lifetime'] = this.lifetime;
    data['hm_on_job'] = this.hmOnJob;
    data['life_on_job'] = this.lifeOnJob;
    data['date'] = this.date;
    data['rating'] = this.rating;
    data['site'] = this.site;
    data['sn'] = this.sn;
    data['kunci_unit'] = this.kunciUnit;
    data['kunci_tire'] = this.kunciTire;
    return data;
  }

  @override
  String toString() {
    return 'UnitTire(unitNumber: $unitNumber, posisi: $posisi, model: $model, status: $status, hm: $hm, brand: $brand, size: $size, pattern: $pattern, otd: $otd, rtd: $rtd, lifetime: $lifetime, hmOnJob: $hmOnJob, lifeOnJob: $lifeOnJob, date: $date, rating: $rating, site: $site, sn: $sn, kunciUnit: $kunciUnit, kunciTire: $kunciTire)';
  }
}
