class SendTireInspection {
  final String date;
  final String unitNumber;
  final String tirePosition;
  final String pressure;
  final String rtd1;
  final String hmOnInspect;
  final String remark;
  final String pics;
  final String adjPress;
  final String inspectorLocation;
  final String tireDamage;
  final String brokenComponent;
  final String snTire;

  final String rimBaseCondition;
  final String rimBaseRemark;

  final String flangeCondition;
  final String flangeRemark;

  final String lockRingCondition;
  final String lockRingRemark;

  final String valveCondition;
  final String valveRemark;

  final String coreValveCondition;
  final String coreValveRemark;

  final String nutStudCondition;
  final String nutStudRemark;

  final String temperatureStatus;
  final String site;

  SendTireInspection({
    required this.date,
    required this.unitNumber,
    required this.tirePosition,
    required this.pressure,
    required this.rtd1,
    required this.hmOnInspect,
    required this.remark,
    required this.pics,
    required this.adjPress,
    required this.inspectorLocation,
    required this.tireDamage,
    required this.brokenComponent,
    required this.snTire,
    required this.rimBaseCondition,
    required this.rimBaseRemark,
    required this.flangeCondition,
    required this.flangeRemark,
    required this.lockRingCondition,
    required this.lockRingRemark,
    required this.valveCondition,
    required this.valveRemark,
    required this.coreValveCondition,
    required this.coreValveRemark,
    required this.nutStudCondition,
    required this.nutStudRemark,
    required this.temperatureStatus,
    required this.site,
  });

  factory SendTireInspection.fromJson(Map<String, dynamic> json) {
    return SendTireInspection(
      date: json['date'] ?? '',
      unitNumber: json['unit_number'] ?? '',
      tirePosition: json['tire_position'] ?? '',
      pressure: json['pressure'] ?? '',
      rtd1: json['rtd1'] ?? '',
      hmOnInspect: json['hm_on_inspect'] ?? '',
      remark: json['remark'] ?? '',
      pics: json['pics'] ?? '',
      adjPress: json['adj_press'] ?? '',
      inspectorLocation: json['inspector_location'] ?? '',
      tireDamage: json['tire_damage'] ?? '',
      brokenComponent: json['broken_component'] ?? '',
      snTire: json['sn_tire'] ?? '',
      rimBaseCondition: json['rim_base_condition'] ?? '',
      rimBaseRemark: json['rim_base_remark'] ?? '',
      flangeCondition: json['flange_condition'] ?? '',
      flangeRemark: json['flange_remark'] ?? '',
      lockRingCondition: json['lock_ring_condition'] ?? '',
      lockRingRemark: json['lock_ring_remark'] ?? '',
      valveCondition: json['valve_condition'] ?? '',
      valveRemark: json['valve_remark'] ?? '',
      coreValveCondition: json['core_valve_condition'] ?? '',
      coreValveRemark: json['core_valve_remark'] ?? '',
      nutStudCondition: json['nut_stud_condition'] ?? '',
      nutStudRemark: json['nut_stud_remark'] ?? '',
      temperatureStatus: json['temperature_status'] ?? '',
      site: json['site'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'unit_number': unitNumber,
      'tire_position': tirePosition,
      'pressure': pressure,
      'rtd1': rtd1,
      'hm_on_inspect': hmOnInspect,
      'remark': remark,
      'pics': pics,
      'adj_press': adjPress,
      'inspector_location': inspectorLocation,
      'tire_damage': tireDamage,
      'broken_component': brokenComponent,
      'sn_tire': snTire,
      'rim_base_condition': rimBaseCondition,
      'rim_base_remark': rimBaseRemark,
      'flange_condition': flangeCondition,
      'flange_remark': flangeRemark,
      'lock_ring_condition': lockRingCondition,
      'lock_ring_remark': lockRingRemark,
      'valve_condition': valveCondition,
      'valve_remark': valveRemark,
      'core_valve_condition': coreValveCondition,
      'core_valve_remark': coreValveRemark,
      'nut_stud_condition': nutStudCondition,
      'nut_stud_remark': nutStudRemark,
      'temperature_status': temperatureStatus,
      'site': site,
    };
  }
}
