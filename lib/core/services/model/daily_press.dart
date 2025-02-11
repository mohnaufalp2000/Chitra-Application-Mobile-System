import 'package:equatable/equatable.dart';

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

  factory DailyPress.fromFirestore(Map<String, dynamic> json) {
    return DailyPress(
      idSite: json['idSite'] ?? '',
      user: json['user'] ?? '',
      tanggal: json['tanggal'] ?? '',
      hari: json['hari'] ?? '',
      jam: json['jam'] ?? '',
      unit: json['unit'] ?? '',
      hm: json['hm'] ?? '',
      posisi: (json['posisi'] as List)
          .map((p) => Position.fromMap(Map<String, dynamic>.from(p)))
          .toList(),
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
  List<Object?> get props => [unit, hari, onlyDate];
}

class Position extends Equatable {
  final String pos;
  final String pressure;
  final String rating;
  final String adjusmentPressure;
  final List<String> luka;
  final String image;

  Position({
    required this.pos,
    required this.pressure,
    required this.rating,
    required this.adjusmentPressure,
    required this.luka,
    required this.image,
  });

  factory Position.fromMap(Map<String, dynamic> map) {
    return Position(
      pos: map['pos'] ?? '',
      pressure: map['pressure'] ?? '0',
      rating: map['rating'] ?? '',
      adjusmentPressure: map['adjusmentPressure'] ?? '0',
      luka: (map['luka'] as List<dynamic>?)?.cast<String>() ?? [],
      image: map['image'] ?? '',
    );
  }

  // Copy method for immutability
  // Copy method for immutability
  Position copyWith({
    String? pos,
    String? pressure,
    String? rating,
    String? adjusmentPressure,
    List<String>? luka,
    String? image,
  }) {
    return Position(
      pos: pos ?? this.pos,
      pressure: pressure ?? this.pressure,
      rating: rating ?? this.rating,
      adjusmentPressure: adjusmentPressure ?? this.adjusmentPressure,
      luka: luka ?? this.luka,
      image: image ?? this.image,
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
    };
  }

  @override
  List<Object?> get props => [pos];
}
