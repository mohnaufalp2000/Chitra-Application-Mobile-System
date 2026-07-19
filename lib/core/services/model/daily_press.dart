import 'package:equatable/equatable.dart';

// DailyPress Class (dengan perbaikan kecil pada parsing list)
class DailyPress extends Equatable {
  final String idSite;
  final String user;
  final String tanggal;
  final String hari;
  final String jam;
  final String unit;
  final String hm;
  final List<Position> posisi;
  final String pit;

  DailyPress({
    required this.idSite,
    required this.user,
    required this.tanggal,
    required this.hari,
    required this.jam,
    required this.unit,
    required this.hm,
    required this.posisi,
    required this.pit,
  });

  String get onlyDate => tanggal.split('T').first;

  @override
  String toString() {
    return 'DailyPress(idSite: $idSite, user: $user, tanggal: $tanggal, hari: $hari, jam: $jam, unit: $unit, hm: $hm, posisi: ${posisi.map((p) => p.toString()).join(", ")}, pit: $pit, )';
  }

  factory DailyPress.fromFirestore(Map<String, dynamic> json) {
    // Membuat parsing 'posisi' lebih aman jika datanya null
    var posisiList = <Position>[];
    if (json['posisi'] is List) {
      posisiList = (json['posisi'] as List)
          .map((p) => Position.fromMap(Map<String, dynamic>.from(p)))
          .toList();
    }

    return DailyPress(
      idSite: json['idSite'] ?? '',
      user: json['user'] ?? '',
      tanggal: json['tanggal'] ?? '',
      hari: json['hari'] ?? '',
      jam: json['jam'] ?? '',
      unit: json['unit'] ?? '',
      hm: json['hm'] ?? '',
      posisi: posisiList, // Menggunakan list yang sudah aman
      pit: json['pit'] ?? 'Default',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'idSite': idSite,
      'user': user,
      'tanggal': tanggal,
      'hari': hari,
      'jam': jam,
      'unit': unit,
      'hm': hm,
      'posisi': posisi.map((p) => p.toMap()).toList(),
      'pit': pit,
    };
  }

  @override
  List<Object?> get props => [
        unit,
        onlyDate,
      ];
}

// Position Class (dengan implementasi solusi)
class Position extends Equatable {
  final String pos;
  final String pressure;
  final String temperatureStatus;
  final String rating;
  final String adjusmentPressure;
  final String adjustmentTemperatureStatus;
  final List<String> luka;
  final String image;
  final String size;
  final String idInventory;
  final String idUnit;
  final String idDaily;
  final String kondisi;
  final String minPress;
  final String maxPress;
  final String avgPress;
  final String temp;
  final List<TireAccessory> tireAccessories;
  final String rtd1;
  final String rtd2;

  Position({
    required this.pos,
    required this.pressure,
    required this.temperatureStatus,
    required this.rating,
    required this.adjusmentPressure,
    required this.adjustmentTemperatureStatus,
    required this.luka,
    required this.image,
    required this.size,
    required this.idInventory,
    required this.idUnit,
    required this.idDaily,
    required this.kondisi,
    this.minPress = '',
    this.maxPress = '',
    this.avgPress = '',
    this.temp = '',
    this.tireAccessories = const [],
    this.rtd1 = '',
    this.rtd2 = '',
  });

  @override
  String toString() {
    return 'Position(pos: $pos, pressure: $pressure, temperatureStatus: $temperatureStatus, rating: $rating, adjusmentPressure: $adjusmentPressure, adjustmentTemperatureStatus: $adjustmentTemperatureStatus, '
        'luka: ${luka.join(", ")}, image: $image, size: $size, idInventory: $idInventory, idUnit: $idUnit, '
        'idDaily: $idDaily, kondisi: $kondisi, minPress: $minPress, maxPress: $maxPress, avgPress: $avgPress, '
        'rtd1: $rtd1, rtd2: $rtd2)'
        'temp: $temp, tireAccessories: ${tireAccessories.map((e) => e.toMap()).toList()})';
  }

  static List<String> _parseList(dynamic data) {
    if (data is List) {
      return data.map((item) => item.toString()).toList();
    }
    if (data is String && data.isNotEmpty) {
      return [data];
    }
    return [];
  }

  factory Position.fromMap(Map<String, dynamic> map) {
    return Position(
      pos: map['pos'] ?? '',
      pressure: map['pressure']?.toString() ?? '0',
      temperatureStatus: map['temperatureStatus']?.toString() ?? '',
      rating: map['rating'] ?? '',
      adjusmentPressure: map['adjusmentPressure']?.toString() ?? '0',
      adjustmentTemperatureStatus:
          map['adjustmentTemperatureStatus']?.toString() ?? '0',
      luka: _parseList(map['luka']),
      image: map['image'] ?? '',
      size: map['tireSize'] ?? '',
      idInventory: map['idInventory'] ?? '',
      idUnit: map['idUnit'] ?? '',
      idDaily: map['idDaily'] ?? '',
      kondisi: map['kondisi'] ?? '',
      minPress: (double.tryParse(map['min_press'].toString()) ?? 0)
          .toStringAsFixed(0),
      maxPress: (double.tryParse(map['max_press'].toString()) ?? 0)
          .toStringAsFixed(0),
      avgPress: (double.tryParse(map['avg_press'].toString()) ?? 0)
          .toStringAsFixed(0),
      temp: map['temp']?.toString() ?? '',
      tireAccessories: (map['tireAccessories'] as List?)
              ?.map((e) => TireAccessory.fromMap(e))
              .toList() ??
          [],
      rtd1: map['rtd1']?.toString() ?? '',
      rtd2: map['rtd2']?.toString() ?? '',
    );
  }

  Position copyWith({
    String? pos,
    String? pressure,
    String? temperatureStatus,
    String? rating,
    String? adjusmentPressure,
    String? adjustmentTemperatureStatus,
    List<String>? luka,
    String? image,
    String? size,
    String? idInventory,
    String? idUnit,
    String? idDaily,
    String? kondisi,
    String? minPress,
    String? maxPress,
    String? avgPress,
    String? temp,
    List<TireAccessory>? tireAccessories,
    String? rtd1,
    String? rtd2,
  }) {
    return Position(
      pos: pos ?? this.pos,
      pressure: pressure ?? this.pressure,
      temperatureStatus: temperatureStatus ?? this.temperatureStatus,
      rating: rating ?? this.rating,
      adjusmentPressure: adjusmentPressure ?? this.adjusmentPressure,
      adjustmentTemperatureStatus:
          adjustmentTemperatureStatus ?? this.adjustmentTemperatureStatus,
      luka: luka ?? this.luka,
      image: image ?? this.image,
      size: size ?? this.size,
      idInventory: idInventory ?? this.idInventory,
      idUnit: idUnit ?? this.idUnit,
      idDaily: idDaily ?? this.idDaily,
      kondisi: kondisi ?? this.kondisi,
      minPress: minPress ?? this.minPress,
      maxPress: maxPress ?? this.maxPress,
      avgPress: avgPress ?? this.avgPress,
      temp: temp ?? this.temp,
      tireAccessories: tireAccessories ?? this.tireAccessories,
      rtd1: rtd1 ?? this.rtd1,
      rtd2: rtd2 ?? this.rtd2,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pos': pos,
      'pressure': pressure,
      'temperatureStatus': temperatureStatus,
      'rating': rating,
      'adjusmentPressure': adjusmentPressure,
      'adjustmentTemperatureStatus': adjustmentTemperatureStatus,
      'luka': luka,
      'image': image,
      'tireSize': size,
      'idInventory': idInventory,
      'idUnit': idUnit,
      'idDaily': idDaily,
      'kondisi': kondisi,
      'min_press': minPress,
      'max_press': maxPress,
      'avg_press': avgPress,
      'temp': temp,
      'tireAccessories': tireAccessories.map((e) => e.toMap()).toList(),
      'rtd1': rtd1,
      'rtd2': rtd2,
    };
  }

  @override
  List<Object?> get props => [pos];
}

class TireAccessory {
  final String name;
  final String condition; // Normal, Rusak, Hilang
  final String remark;
  final String image;

  TireAccessory({
    required this.name,
    required this.condition,
    required this.remark,
    required this.image,
  });

  factory TireAccessory.fromMap(Map<String, dynamic> map) {
    return TireAccessory(
      name: map['name'] ?? '',
      condition: map['condition'] ?? 'Normal',
      remark: map['remark'] ?? '',
      image: map['image'] ?? 'image.png',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'condition': condition,
      'remark': remark,
      'image': image,
    };
  }

  // --- copyWith baru ---
  TireAccessory copyWith({
    String? name,
    String? condition,
    String? remark,
    String? image,
  }) {
    return TireAccessory(
      name: name ?? this.name,
      condition: condition ?? this.condition,
      remark: remark ?? this.remark,
      image: image ?? this.image,
    );
  }

  @override
  String toString() {
    return 'TireAccessory(name: $name, condition: $condition, remark: $remark, image: $image)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TireAccessory &&
        other.name == name &&
        other.condition == condition &&
        other.remark == remark &&
        other.image == image;
  }

  @override
  int get hashCode =>
      name.hashCode ^ condition.hashCode ^ remark.hashCode ^ image.hashCode;
}
