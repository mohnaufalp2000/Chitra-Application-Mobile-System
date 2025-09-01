class SpmJam7 {
  DateTime? tgl;
  String? devicename;
  String? idSite;
  String? maxP1;
  String? maxP2;
  String? maxP3;
  String? maxP4;
  String? maxP5;
  String? maxP6;
  String? minP1;
  String? minP2;
  String? minP3;
  String? minP4;
  String? minP5;
  String? minP6;
  String? avgP1;
  String? avgP2;
  String? avgP3;
  String? avgP4;
  String? avgP5;
  String? avgP6;
  String? maxT1;
  String? maxT2;
  String? maxT3;
  String? maxT4;
  String? maxT5;
  String? maxT6;
  String? minT1;
  String? minT2;
  String? minT3;
  String? minT4;
  String? minT5;
  String? minT6;
  String? avgT1;
  String? avgT2;
  String? avgT3;
  String? avgT4;
  String? avgT5;
  String? avgT6;

  SpmJam7({
    this.tgl,
    this.devicename,
    this.idSite,
    this.maxP1,
    this.maxP2,
    this.maxP3,
    this.maxP4,
    this.maxP5,
    this.maxP6,
    this.minP1,
    this.minP2,
    this.minP3,
    this.minP4,
    this.minP5,
    this.minP6,
    this.avgP1,
    this.avgP2,
    this.avgP3,
    this.avgP4,
    this.avgP5,
    this.avgP6,
    this.maxT1,
    this.maxT2,
    this.maxT3,
    this.maxT4,
    this.maxT5,
    this.maxT6,
    this.minT1,
    this.minT2,
    this.minT3,
    this.minT4,
    this.minT5,
    this.minT6,
    this.avgT1,
    this.avgT2,
    this.avgT3,
    this.avgT4,
    this.avgT5,
    this.avgT6,
  });

  /// Konversi ke Map/JSON (snake_case)
  Map<String, dynamic> toJson() {
    return {
      'tgl': tgl?.toIso8601String(),
      'devicename': devicename,
      'id_site': idSite,
      'max_p1': maxP1,
      'max_p2': maxP2,
      'max_p3': maxP3,
      'max_p4': maxP4,
      'max_p5': maxP5,
      'max_p6': maxP6,
      'min_p1': minP1,
      'min_p2': minP2,
      'min_p3': minP3,
      'min_p4': minP4,
      'min_p5': minP5,
      'min_p6': minP6,
      'avg_p1': avgP1,
      'avg_p2': avgP2,
      'avg_p3': avgP3,
      'avg_p4': avgP4,
      'avg_p5': avgP5,
      'avg_p6': avgP6,
      'max_t1': maxT1,
      'max_t2': maxT2,
      'max_t3': maxT3,
      'max_t4': maxT4,
      'max_t5': maxT5,
      'max_t6': maxT6,
      'min_t1': minT1,
      'min_t2': minT2,
      'min_t3': minT3,
      'min_t4': minT4,
      'min_t5': minT5,
      'min_t6': minT6,
      'avg_t1': avgT1,
      'avg_t2': avgT2,
      'avg_t3': avgT3,
      'avg_t4': avgT4,
      'avg_t5': avgT5,
      'avg_t6': avgT6,
    };
  }

  /// Buat instance dari JSON (snake_case → camelCase)
  factory SpmJam7.fromJson(Map<String, dynamic> json) {
    return SpmJam7(
      tgl: json['tgl'] != null
          ? DateTime.tryParse(json['tgl'].toString())
          : null,
      devicename: json['devicename']?.toString(),
      idSite: json['id_site']?.toString(),
      maxP1: json['max_p1']?.toString(),
      maxP2: json['max_p2']?.toString(),
      maxP3: json['max_p3']?.toString(),
      maxP4: json['max_p4']?.toString(),
      maxP5: json['max_p5']?.toString(),
      maxP6: json['max_p6']?.toString(),
      minP1: json['min_p1']?.toString(),
      minP2: json['min_p2']?.toString(),
      minP3: json['min_p3']?.toString(),
      minP4: json['min_p4']?.toString(),
      minP5: json['min_p5']?.toString(),
      minP6: json['min_p6']?.toString(),
      avgP1: json['avg_p1']?.toString(),
      avgP2: json['avg_p2']?.toString(),
      avgP3: json['avg_p3']?.toString(),
      avgP4: json['avg_p4']?.toString(),
      avgP5: json['avg_p5']?.toString(),
      avgP6: json['avg_p6']?.toString(),
      maxT1: json['max_t1']?.toString(),
      maxT2: json['max_t2']?.toString(),
      maxT3: json['max_t3']?.toString(),
      maxT4: json['max_t4']?.toString(),
      maxT5: json['max_t5']?.toString(),
      maxT6: json['max_t6']?.toString(),
      minT1: json['min_t1']?.toString(),
      minT2: json['min_t2']?.toString(),
      minT3: json['min_t3']?.toString(),
      minT4: json['min_t4']?.toString(),
      minT5: json['min_t5']?.toString(),
      minT6: json['min_t6']?.toString(),
      avgT1: json['avg_t1']?.toString(),
      avgT2: json['avg_t2']?.toString(),
      avgT3: json['avg_t3']?.toString(),
      avgT4: json['avg_t4']?.toString(),
      avgT5: json['avg_t5']?.toString(),
      avgT6: json['avg_t6']?.toString(),
    );
  }

  @override
  String toString() {
    return '''
      SpmJam7(
        tgl: $tgl,
        devicename: $devicename,
        idSite: $idSite,
        
        --- Pressure (P) ---
        Pos 1: max=$maxP1, min=$minP1, avg=$avgP1
        Pos 2: max=$maxP2, min=$minP2, avg=$avgP2
        Pos 3: max=$maxP3, min=$minP3, avg=$avgP3
        Pos 4: max=$maxP4, min=$minP4, avg=$avgP4
        Pos 5: max=$maxP5, min=$minP5, avg=$avgP5
        Pos 6: max=$maxP6, min=$minP6, avg=$avgP6

        --- Temperature (T) ---
        Pos 1: max=$maxT1, min=$minT1, avg=$avgT1
        Pos 2: max=$maxT2, min=$minT2, avg=$avgT2
        Pos 3: max=$maxT3, min=$minT3, avg=$avgT3
        Pos 4: max=$maxT4, min=$minT4, avg=$avgT4
        Pos 5: max=$maxT5, min=$minT5, avg=$avgT5
        Pos 6: max=$maxT6, min=$minT6, avg=$avgT6
      )''';
  }
}
