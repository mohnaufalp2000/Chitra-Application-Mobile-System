class SendTireInspectionRequest {
  final String moNumber;
  final List<SendTireInspection> inspects;

  SendTireInspectionRequest({
    required this.moNumber,
    required this.inspects,
  });

  factory SendTireInspectionRequest.fromJson(
    Map<String, dynamic> json,
  ) {
    return SendTireInspectionRequest(
      moNumber: json['mo_number']?.toString() ?? '',
      inspects: (json['inspects'] as List<dynamic>? ?? [])
          .map(
            (item) => SendTireInspection.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mo_number': moNumber,
      'inspects': inspects.map((e) => e.toJson()).toList(),
    };
  }
}

class SendTireInspection {
  /// FIELD BARU
  final String idUnitSite;

  final String date;
  final String unitNumber;
  final String tirePosition;
  final String pressure;
  final String rtd1;
  final String rtd2;
  final String avgRtd;
  final String job;

  final String hmOnInspect;
  final String kmOnInspect;

  final String remark;
  final String pics;
  final String adjPress;

  final String inspectorLocation;
  final String area;

  /// FIELD BARU
  final String inspectionPeriod;

  final String tireDamage;
  final String brokenComponent;
  final String snTire;

  final String rimBaseCondition;
  final String rimBaseRemark;

  final String flangeCondition;
  final String flangeRemark;

  final String lockRingCondition;
  final String lockRingRemark;

  /// FIELD BARU
  final String oRingCondition;
  final String oRingRemark;

  final String valveCondition;
  final String valveRemark;

  final String coreValveCondition;
  final String coreValveRemark;

  final String valveCapCondition;
  final String valveCapRemark;

  final String nutStudCondition;
  final String nutStudRemark;

  final String temperatureStatus;
  final String site;

  SendTireInspection({
    required this.idUnitSite,
    required this.date,
    required this.unitNumber,
    required this.tirePosition,
    required this.pressure,
    required this.rtd1,
    this.rtd2 = '',
    this.avgRtd = '',
    this.job = '',
    required this.hmOnInspect,
    required this.kmOnInspect,
    required this.remark,
    required this.pics,
    required this.adjPress,
    required this.inspectorLocation,
    required this.area,
    required this.inspectionPeriod,
    required this.tireDamage,
    required this.brokenComponent,
    required this.snTire,
    required this.rimBaseCondition,
    required this.rimBaseRemark,
    required this.flangeCondition,
    required this.flangeRemark,
    required this.lockRingCondition,
    required this.lockRingRemark,
    required this.oRingCondition,
    required this.oRingRemark,
    required this.valveCondition,
    required this.valveRemark,
    required this.coreValveCondition,
    required this.coreValveRemark,
    required this.valveCapCondition,
    required this.valveCapRemark,
    required this.nutStudCondition,
    required this.nutStudRemark,
    required this.temperatureStatus,
    required this.site,
  });

  factory SendTireInspection.fromJson(
    Map<String, dynamic> json,
  ) {
    return SendTireInspection(
      idUnitSite: json['id_unit_site']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      unitNumber: json['unit_number']?.toString() ?? '',
      tirePosition: json['tire_position']?.toString() ?? '',
      pressure: json['pressure']?.toString() ?? '',
      rtd1: json['rtd1']?.toString() ?? '',
      rtd2: json['rtd2']?.toString() ?? '',
      avgRtd: (json['avg_rtd'] ?? json['avgRtd'])?.toString() ?? '',
      job: json['job']?.toString() ?? '',
      hmOnInspect: json['hm_on_inspect']?.toString() ?? '',
      kmOnInspect: json['km_on_inspect']?.toString() ?? '',
      remark: json['remark']?.toString() ?? '',
      pics: json['pics']?.toString() ?? '',
      adjPress: json['adj_press']?.toString() ?? '',
      inspectorLocation: json['inspector_location']?.toString() ?? '',
      area: json['area']?.toString() ?? '',
      inspectionPeriod: json['inspection_period']?.toString() ?? '',
      tireDamage: json['tire_damage']?.toString() ?? '',
      brokenComponent: json['broken_component']?.toString() ?? '',
      snTire: json['sn_tire']?.toString() ?? '',
      rimBaseCondition: json['rim_base_condition']?.toString() ?? '',
      rimBaseRemark: json['rim_base_remark']?.toString() ?? '',
      flangeCondition: json['flange_condition']?.toString() ?? '',
      flangeRemark: json['flange_remark']?.toString() ?? '',
      lockRingCondition: json['lock_ring_condition']?.toString() ?? '',
      lockRingRemark: json['lock_ring_remark']?.toString() ?? '',
      oRingCondition: json['o_ring_condition']?.toString() ?? '',
      oRingRemark: json['o_ring_remark']?.toString() ?? '',
      valveCondition: json['valve_condition']?.toString() ?? '',
      valveRemark: json['valve_remark']?.toString() ?? '',
      coreValveCondition: json['core_valve_condition']?.toString() ?? '',
      coreValveRemark: json['core_valve_remark']?.toString() ?? '',
      valveCapCondition: json['valve_cap_condition']?.toString() ?? '',
      valveCapRemark: json['valve_cap_remark']?.toString() ?? '',
      nutStudCondition: json['nut_stud_condition']?.toString() ?? '',
      nutStudRemark: json['nut_stud_remark']?.toString() ?? '',
      temperatureStatus: json['temperature_status']?.toString() ?? '',
      site: json['site']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      /// BARU
      'id_unit_site': idUnitSite,

      'date': date,
      'unit_number': unitNumber,
      'tire_position': tirePosition,
      'pressure': pressure,
      'rtd1': rtd1,
      'rtd2': rtd2,
      'avg_rtd': avgRtd,
      'job': job,
      'hm_on_inspect': hmOnInspect,
      'km_on_inspect': kmOnInspect,
      'remark': remark,
      'pics': pics,
      'adj_press': adjPress,
      'inspector_location': inspectorLocation,
      'area': area,

      /// BARU
      'inspection_period': inspectionPeriod,

      'tire_damage': tireDamage,
      'broken_component': brokenComponent,
      'sn_tire': snTire,

      'rim_base_condition': rimBaseCondition,
      'rim_base_remark': rimBaseRemark,

      'flange_condition': flangeCondition,
      'flange_remark': flangeRemark,

      'lock_ring_condition': lockRingCondition,
      'lock_ring_remark': lockRingRemark,

      /// BARU
      'o_ring_condition': oRingCondition,
      'o_ring_remark': oRingRemark,

      'valve_condition': valveCondition,
      'valve_remark': valveRemark,

      'core_valve_condition': coreValveCondition,
      'core_valve_remark': coreValveRemark,

      'valve_cap_condition': valveCapCondition,
      'valve_cap_remark': valveCapRemark,

      'nut_stud_condition': nutStudCondition,
      'nut_stud_remark': nutStudRemark,

      'temperature_status': temperatureStatus,
      'site': site,
    };
  }
}
