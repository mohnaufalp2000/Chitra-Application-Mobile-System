import 'dart:convert';

class DailyCheckPost {
  List<MaterialRepair> data;

  DailyCheckPost({
    required this.data,
  });

  factory DailyCheckPost.fromRawJson(String str) =>
      DailyCheckPost.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory DailyCheckPost.fromJson(Map<String, dynamic> json) => DailyCheckPost(
        data: List<MaterialRepair>.from(
            json["data"].map((x) => MaterialRepair.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
      };

  @override
  String toString() => 'DailyCheckPost(data: $data)';
}

class MaterialRepair {
  String idMatstock;
  String idSap;
  Category category;
  String materialName;
  Smu smu;

  MaterialRepair({
    required this.idMatstock,
    required this.idSap,
    required this.category,
    required this.materialName,
    required this.smu,
  });

  factory MaterialRepair.fromRawJson(String str) =>
      MaterialRepair.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory MaterialRepair.fromJson(Map<String, dynamic> json) => MaterialRepair(
        idMatstock: json["id_matstock"],
        idSap: json["id_sap"],
        category: categoryValues.map[json["category"]]!,
        materialName: json["material_name"],
        smu: smuValues.map[json["smu"]]!,
      );

  Map<String, dynamic> toJson() => {
        "id_matstock": idMatstock,
        "id_sap": idSap,
        "category": categoryValues.reverse[category],
        "material_name": materialName,
        "smu": smuValues.reverse[smu],
      };

  MaterialRepair copyWith({
    String? idMatstock,
    String? idSap,
    Category? category,
    String? materialName,
    Smu? smu,
  }) {
    return MaterialRepair(
      idMatstock: idMatstock ?? this.idMatstock,
      idSap: idSap ?? this.idSap,
      category: category ?? this.category,
      materialName: materialName ?? this.materialName,
      smu: smu ?? this.smu,
    );
  }

  @override
  String toString() {
    return 'MaterialRepair(idMatstock: $idMatstock, idSap: $idSap, category: ${categoryValues.reverse[category]}, '
        'materialName: $materialName, smu: ${smuValues.reverse[smu]})';
  }
}

enum Category { CEMENT, CUSHION_GUM, PATCH, RUBBER }

final categoryValues = EnumValues({
  "CEMENT": Category.CEMENT,
  "CUSHION GUM": Category.CUSHION_GUM,
  "PATCH": Category.PATCH,
  "RUBBER": Category.RUBBER
});

enum Smu { mL, KG, PC }

final smuValues = EnumValues({"mL": Smu.mL, "KG": Smu.KG, "PC": Smu.PC});

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
