// import 'package:equatable/equatable.dart';

// class UnitTire extends Equatable {
//   String? unitNumber;
//   String? posisi;
//   String? model;
//   String? status;
//   String? hm;
//   String? brand;
//   String? size;
//   String? pattern;
//   String? otd;
//   String? rtd;
//   String? lifetime;
//   String? hmOnJob;
//   String? lifeOnJob;
//   String? date;
//   String? rating;
//   String? site;
//   String? sn;
//   String? kunciUnit;
//   String? kunciTire;
//   String? idinventory;
//   String? idUnit;

//   UnitTire({
//     this.unitNumber,
//     this.posisi,
//     this.model,
//     this.status,
//     this.hm,
//     this.brand,
//     this.size,
//     this.pattern,
//     this.otd,
//     this.rtd,
//     this.lifetime,
//     this.hmOnJob,
//     this.lifeOnJob,
//     this.date,
//     this.rating,
//     this.site,
//     this.sn,
//     this.kunciUnit,
//     this.kunciTire,
//     this.idinventory,
//     this.idUnit,
//   });

//   @override
//   List<Object?> get props => [
//         unitNumber,
//         posisi,
//         model,
//         status,
//         hm,
//         brand,
//         size,
//         pattern,
//         otd,
//         rtd,
//         lifetime,
//         hmOnJob,
//         lifeOnJob,
//         date,
//         rating,
//         site,
//         sn,
//         kunciUnit,
//         kunciTire,
//         idinventory,
//         idUnit,
//       ];

//   // Metode fromJson, toJson, dan toString tetap seperti yang Anda miliki
//   // ...

//   factory UnitTire.fromJson(Map<String, dynamic> json) {
//     return UnitTire(
//       unitNumber: json['unit_number'],
//       posisi: json['posisi'],
//       model: json['model'],
//       status: json['status'],
//       hm: json['hm'],
//       brand: json['brand'],
//       size: json['size'],
//       pattern: json['pattern'],
//       otd: json['otd'],
//       rtd: json['rtd'],
//       lifetime: json['lifetime'],
//       hmOnJob: json['hm_on_job'],
//       lifeOnJob: json['life_on_job'],
//       date: json['date'],
//       rating: json['rating'],
//       site: json['site'],
//       sn: json['sn'],
//       kunciUnit: json['kunci_unit'],
//       kunciTire: json['kunci_tire'],
//       idinventory: json['id_inventory'],
//       idUnit: json['idunit'],
//     );
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['unit_number'] = this.unitNumber;
//     data['posisi'] = this.posisi;
//     data['model'] = this.model;
//     data['status'] = this.status;
//     data['hm'] = this.hm;
//     data['brand'] = this.brand;
//     data['size'] = this.size;
//     data['pattern'] = this.pattern;
//     data['otd'] = this.otd;
//     data['rtd'] = this.rtd;
//     data['lifetime'] = this.lifetime;
//     data['hm_on_job'] = this.hmOnJob;
//     data['life_on_job'] = this.lifeOnJob;
//     data['date'] = this.date;
//     data['rating'] = this.rating;
//     data['site'] = this.site;
//     data['sn'] = this.sn;
//     data['kunci_unit'] = this.kunciUnit;
//     data['kunci_tire'] = this.kunciTire;
//     data['id_inventory'] = this.idinventory;
//     data['idunit'] = this.idUnit;
//     return data;
//   }

//   @override
//   String toString() {
//     return 'UnitTire(unitNumber: $unitNumber, posisi: $posisi, model: $model, status: $status, hm: $hm, brand: $brand, size: $size, pattern: $pattern, otd: $otd, rtd: $rtd, lifetime: $lifetime, hmOnJob: $hmOnJob, lifeOnJob: $lifeOnJob, date: $date, rating: $rating, site: $site, sn: $sn, kunciUnit: $kunciUnit, kunciTire: $kunciTire, idInventory: $idinventory, idUnit: $idUnit)';
//   }
// }

import 'package:equatable/equatable.dart';

class UnitTire extends Equatable {
  final String? unitNumber;
  final String? posisi;
  final String? model;
  final String? status;
  final String? hm;
  final String? brand;
  final String? size;
  final String? pattern;
  final String? otd;
  final String? rtd;
  final String? lifetime;
  final String? hmOnJob;
  final String? lifeOnJob;
  final String? date;
  final String? rating;
  final String? site;
  final String? sn;
  final String? kunciUnit;
  final String? kunciTire;
  final String? idinventory;
  final String? idUnit;

  /// Field baru dari get_tire_running.
  final String? area;
  final String? scheduleType;
  final String? scheduleDate;

  const UnitTire({
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
    this.idinventory,
    this.idUnit,
    this.area,
    this.scheduleType,
    this.scheduleDate,
  });

  static String? _toNullableString(dynamic value) {
    if (value == null) {
      return null;
    }

    final String result = value.toString().trim();

    if (result.isEmpty || result.toLowerCase() == 'null') {
      return null;
    }

    return result;
  }

  factory UnitTire.fromJson(Map<String, dynamic> json) {
    return UnitTire(
      unitNumber: _toNullableString(json['unit_number']),
      posisi: _toNullableString(json['posisi']),
      model: _toNullableString(json['model']),
      status: _toNullableString(json['status']),
      hm: _toNullableString(json['hm']),
      brand: _toNullableString(json['brand']),
      size: _toNullableString(json['size']),
      pattern: _toNullableString(json['pattern']),
      otd: _toNullableString(json['otd']),
      rtd: _toNullableString(json['rtd']),
      lifetime: _toNullableString(json['lifetime']),
      hmOnJob: _toNullableString(json['hm_on_job']),
      lifeOnJob: _toNullableString(json['life_on_job']),
      date: _toNullableString(json['date']),
      rating: _toNullableString(json['rating']),
      site: _toNullableString(json['site']),
      sn: _toNullableString(json['sn']),
      kunciUnit: _toNullableString(json['kunci_unit']),
      kunciTire: _toNullableString(json['kunci_tire']),
      idinventory: _toNullableString(json['id_inventory']),
      idUnit: _toNullableString(json['idunit']),

      /// Field baru.
      area: _toNullableString(json['area']),
      scheduleType: _toNullableString(json['schedule_type']),
      scheduleDate: _toNullableString(json['schedule_date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unit_number': unitNumber,
      'posisi': posisi,
      'model': model,
      'status': status,
      'hm': hm,
      'brand': brand,
      'size': size,
      'pattern': pattern,
      'otd': otd,
      'rtd': rtd,
      'lifetime': lifetime,
      'hm_on_job': hmOnJob,
      'life_on_job': lifeOnJob,
      'date': date,
      'rating': rating,
      'site': site,
      'sn': sn,
      'kunci_unit': kunciUnit,
      'kunci_tire': kunciTire,
      'id_inventory': idinventory,
      'idunit': idUnit,

      /// Field baru ikut tersimpan ke cache unit.
      'area': area,
      'schedule_type': scheduleType,
      'schedule_date': scheduleDate,
    };
  }

  @override
  List<Object?> get props => [
        unitNumber,
        posisi,
        model,
        status,
        hm,
        brand,
        size,
        pattern,
        otd,
        rtd,
        lifetime,
        hmOnJob,
        lifeOnJob,
        date,
        rating,
        site,
        sn,
        kunciUnit,
        kunciTire,
        idinventory,
        idUnit,
        area,
        scheduleType,
        scheduleDate,
      ];

  @override
  String toString() {
    return 'UnitTire('
        'unitNumber: $unitNumber, '
        'posisi: $posisi, '
        'model: $model, '
        'status: $status, '
        'hm: $hm, '
        'brand: $brand, '
        'size: $size, '
        'pattern: $pattern, '
        'otd: $otd, '
        'rtd: $rtd, '
        'lifetime: $lifetime, '
        'hmOnJob: $hmOnJob, '
        'lifeOnJob: $lifeOnJob, '
        'date: $date, '
        'rating: $rating, '
        'site: $site, '
        'sn: $sn, '
        'kunciUnit: $kunciUnit, '
        'kunciTire: $kunciTire, '
        'idInventory: $idinventory, '
        'idUnit: $idUnit, '
        'area: $area, '
        'scheduleType: $scheduleType, '
        'scheduleDate: $scheduleDate'
        ')';
  }
}
