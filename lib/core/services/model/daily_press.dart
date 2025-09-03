// import 'package:equatable/equatable.dart';

// class DailyPress extends Equatable {
//   final String idSite;
//   final String user;
//   final String tanggal;
//   final String hari;
//   final String jam;
//   final String unit;
//   final String hm;
//   final List<Position> posisi;
//   final String pit;

//   DailyPress({
//     required this.idSite,
//     required this.user,
//     required this.tanggal,
//     required this.hari,
//     required this.jam,
//     required this.unit,
//     required this.hm,
//     required this.posisi,
//     required this.pit,
//   });

//   String get onlyDate => tanggal.split('T').first;

//   @override
//   String toString() {
//     return 'DailyPress(idSite: $idSite, user: $user, tanggal: $tanggal, hari: $hari, jam: $jam, unit: $unit, hm: $hm, posisi: ${posisi.map((p) => p.toString()).join(", ")}, pit: $pit, )';
//   }

//   factory DailyPress.fromFirestore(Map<String, dynamic> json) {
//     return DailyPress(
//       idSite: json['idSite'] ?? '',
//       user: json['user'] ?? '',
//       tanggal: json['tanggal'] ?? '',
//       hari: json['hari'] ?? '',
//       jam: json['jam'] ?? '',
//       unit: json['unit'] ?? '',
//       hm: json['hm'] ?? '',
//       posisi: (json['posisi'] as List)
//           .map((p) => Position.fromMap(Map<String, dynamic>.from(p)))
//           .toList(),
//       pit: json['pit'] ?? 'Default',
//     );
//   }

//   Map<String, dynamic> toFirestore() {
//     return {
//       'idSite': idSite,
//       'user': user,
//       'tanggal': tanggal,
//       'hari': hari,
//       'jam': jam,
//       'unit': unit,
//       'hm': hm,
//       'posisi': posisi.map((p) => p.toMap()).toList(),
//       'pit': pit,
//     };
//   }

//   @override
//   List<Object?> get props => [
//         unit,
//         // hari,
//         onlyDate,
//         // posisi.map((p) => p.toString()).join('|'),
//       ]; // Include idUnit in props
// }

// class Position extends Equatable {
//   final String pos;
//   final String pressure;
//   final String rating;
//   final String adjusmentPressure;
//   final List<String> luka;
//   final String image;
//   final String size;
//   final String idInventory;
//   final String idUnit;
//   final String idDaily;
//   final String kondisi; // Added kondisi

//   Position({
//     required this.pos,
//     required this.pressure,
//     required this.rating,
//     required this.adjusmentPressure,
//     required this.luka,
//     required this.image,
//     required this.size,
//     required this.idInventory,
//     required this.idUnit,
//     required this.idDaily,
//     required this.kondisi, // Initialize kondisi
//   });

//   @override
//   String toString() {
//     return 'Position(pos: $pos, pressure: $pressure, rating: $rating, adjusmentPressure: $adjusmentPressure, luka: ${luka.join(", ")}, image: $image, size: $size, idInventory: $idInventory, idUnit: $idUnit, idDaily: $idDaily, kondisi: $kondisi)';
//   }

//   factory Position.fromMap(Map<String, dynamic> map) {
//     return Position(
//       pos: map['pos'] ?? '',
//       pressure: map['pressure'] ?? '0',
//       rating: map['rating'] ?? '',
//       adjusmentPressure: map['adjusmentPressure'] ?? '0',
//       luka: (map['luka'] as List<dynamic>?)?.cast<String>() ?? [],
//       image: map['image'] ?? '',
//       size: map['tireSize'] ?? '',
//       idInventory: map['idInventory'] ?? '',
//       idUnit: map['idUnit'] ?? '',
//       idDaily: map['idDaily'] ?? '',
//       kondisi: map['kondisi'] ?? '', // Get kondisi from map
//     );
//   }

//   Position copyWith({
//     String? pos,
//     String? pressure,
//     String? rating,
//     String? adjusmentPressure,
//     List<String>? luka,
//     String? image,
//     String? size,
//     String? idInventory,
//     String? idUnit,
//     String? idDaily,
//     String? kondisi, // Add kondisi to copyWith
//   }) {
//     return Position(
//       pos: pos ?? this.pos,
//       pressure: pressure ?? this.pressure,
//       rating: rating ?? this.rating,
//       adjusmentPressure: adjusmentPressure ?? this.adjusmentPressure,
//       luka: luka ?? this.luka,
//       image: image ?? this.image,
//       size: size ?? this.size,
//       idInventory: idInventory ?? this.idInventory,
//       idUnit: idUnit ?? this.idUnit,
//       idDaily: idDaily ?? this.idDaily,
//       kondisi: kondisi ?? this.kondisi, // Copy kondisi
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'pos': pos,
//       'pressure': pressure,
//       'rating': rating,
//       'adjusmentPressure': adjusmentPressure,
//       'luka': luka,
//       'image': image,
//       'tireSize': size,
//       'idInventory': idInventory,
//       'idUnit': idUnit,
//       'idDaily': idDaily,
//       'kondisi': kondisi, // Add kondisi to map
//     };
//   }

//   @override
//   List<Object?> get props => [pos]; // Include kondisi in props
// }

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
  final String rating;
  final String adjusmentPressure;
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

  Position({
    required this.pos,
    required this.pressure,
    required this.rating,
    required this.adjusmentPressure,
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
  });

  @override
  String toString() {
    return 'Position(pos: $pos, pressure: $pressure, rating: $rating, adjusmentPressure: $adjusmentPressure, luka: ${luka.join(", ")}, image: $image, size: $size, idInventory: $idInventory, idUnit: $idUnit, idDaily: $idDaily, kondisi: $kondisi, minPress: $minPress, maxPress: $maxPress, avgPress: $avgPress, temp: $temp)';
  }

  static List<String> _parseLuka(dynamic data) {
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
      rating: map['rating'] ?? '',
      adjusmentPressure: map['adjusmentPressure']?.toString() ?? '0',
      luka: _parseLuka(map['luka']), // Menggunakan helper function yang aman
      image: map['image'] ?? '',
      size: map['tireSize'] ?? '',
      idInventory: map['idInventory'] ?? '',
      idUnit: map['idUnit'] ?? '',
      idDaily: map['idDaily'] ?? '',
      kondisi: map['kondisi'] ?? '',
      // minPress: map['min_press']?.toString() ?? '',
      minPress: (double.tryParse(map['min_press'].toString()) ?? 0)
          .toStringAsFixed(0),
      // maxPress: map['max_press']?.toString() ?? '',
      maxPress: (double.tryParse(map['max_press'].toString()) ?? 0)
          .toStringAsFixed(0),
      // avgPress: map['avg_press']?.toString() ?? '',
      avgPress: (double.tryParse(map['avg_press'].toString()) ?? 0)
          .toStringAsFixed(0),
      temp: map['temp']?.toString() ?? '',
    );
  }

  Position copyWith({
    String? pos,
    String? pressure,
    String? rating,
    String? adjusmentPressure,
    List<String>? luka,
    String? image,
    String? size,
    String? idInventory,
    String? idUnit,
    String? idDaily,
    String? kondisi,
  }) {
    return Position(
      pos: pos ?? this.pos,
      pressure: pressure ?? this.pressure,
      rating: rating ?? this.rating,
      adjusmentPressure: adjusmentPressure ?? this.adjusmentPressure,
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pos': pos,
      'pressure': pressure,
      'rating': rating,
      'adjusmentPressure': adjusmentPressure,
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
    };
  }

  @override
  List<Object?> get props => [pos];
}
