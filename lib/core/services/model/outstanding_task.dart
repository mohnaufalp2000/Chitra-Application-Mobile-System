class OutstandingTask {
  final String id;
  final String idSite;
  final String user;
  final String userEmail;
  final String unit;
  final String serialNumber;
  final List<String> condition;
  final String tireSize;
  final int position;
  final String hm;
  final String brand;
  final String tireDamage;
  final String remarks;
  final String rtd;
  final String pressure;
  final String adjusmentPressure;
  final String lastUpdate;
  final bool isDone;
  final List<String>? images;
  final String sn;
  final String kunciUnit;
  final String kunciTire;

  OutstandingTask({
    required this.id,
    required this.idSite,
    required this.user,
    required this.userEmail,
    required this.unit,
    required this.serialNumber,
    required this.condition,
    required this.tireSize,
    required this.position,
    required this.hm,
    required this.brand,
    required this.tireDamage,
    required this.remarks,
    required this.rtd,
    required this.pressure,
    required this.adjusmentPressure,
    required this.lastUpdate,
    required this.isDone,
    required this.images,
    required this.sn,
    required this.kunciUnit,
    required this.kunciTire,
  });

factory OutstandingTask.fromFirestore(Map<String, dynamic> json) {
  List<String> conditionList = [];
  if (json['condition'] is List) {
    conditionList = List<String>.from(json['condition']);
  }

  List<String>? imagesList;
  if (json['images'] is List) {
    imagesList = List<String>.from(json['images']);
  }

  return OutstandingTask(
    id: json['id'] ?? '',
    idSite: json['id_site']?.toString() ?? '',
    user: json['user'] ?? '',
    userEmail: json['user_email'] ?? '',
    unit: json['unit'] ?? '',
    serialNumber: json['serial_number'] ?? '',
    condition: conditionList,
    tireSize: json['tire_size'] ?? '',
    position: json['position'] is int
        ? json['position']
        : int.tryParse(json['position']?.toString() ?? '0') ?? 0,
    hm: json['hm']?.toString() ?? '',
    brand: json['brand'] ?? '',
    tireDamage: json['tire_damage'] ?? '',
    remarks: json['remarks'] ?? '',
    rtd: json['rtd']?.toString() ?? '',
    pressure: json['pressure']?.toString() ?? '',
    adjusmentPressure: json['adjusmentPressure']?.toString() ?? '',

    lastUpdate: json['last_update'] ?? '',   // 🔥 fix

    isDone: json['is_done'] ?? false,        // 🔥 fix

    images: imagesList,
    sn: json['sn']?.toString() ?? '',
    kunciUnit: json['kunci_unit'] ?? '',     // 🔥 fix
    kunciTire: json['kunci_tire'] ?? '',     // 🔥 fix
  );
}


  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'idSite': idSite,
      'user': user,
      'userEmail': userEmail,
      'unit': unit,
      'serialNumber': serialNumber,
      'condition': condition, // List<String>
      'tireSize': tireSize,
      'position': position,
      'hm': hm,
      'brand': brand,
      'tireDamage': tireDamage,
      'remarks': remarks,
      'rtd': rtd,
      'pressure': pressure,
      'adjusmentPressure': adjusmentPressure,
      'lastUpdate': lastUpdate,
      'isDone': isDone,
      'images':
          images, // List<String>? bisa null -> Firestore ignore atau simpan null
      'sn': sn,
      'kunciUnit': kunciUnit,
      'kunciTire': kunciTire,
    };
  }

  @override
  String toString() {
    return 'OutstandingTask{id: $id, idSite: $idSite, user: $user, userEmail: $userEmail, unit: $unit, serialNumber: $serialNumber, condition: $condition, tireSize: $tireSize, position: $position, brand: $brand, tireDamage: $tireDamage, remarks: $remarks, rtd: $rtd, pressure: $pressure, lastUpdate: $lastUpdate, isDone: $isDone, images: $images, sn: $sn, kunciUnit: $kunciUnit, kunciTire: $kunciTire}';
  }
}
