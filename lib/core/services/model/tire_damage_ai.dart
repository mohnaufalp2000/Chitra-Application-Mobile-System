import 'package:meta/meta.dart';
import 'dart:convert';

class TireDamageAi {
  int status;
  Data data;
  Headers headers;

  TireDamageAi({
    required this.status,
    required this.data,
    required this.headers,
  });

  TireDamageAi copyWith({
    int? status,
    Data? data,
    Headers? headers,
  }) =>
      TireDamageAi(
        status: status ?? this.status,
        data: data ?? this.data,
        headers: headers ?? this.headers,
      );

  factory TireDamageAi.fromJson(String str) =>
      TireDamageAi.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory TireDamageAi.fromMap(Map<String, dynamic> json) => TireDamageAi(
        status: json["status"],
        data: Data.fromMap(json["data"]),
        headers: Headers.fromMap(json["headers"]),
      );

  Map<String, dynamic> toMap() => {
        "status": status,
        "data": data.toMap(),
        "headers": headers.toMap(),
      };
}

class Data {
  List<TireDamageResult> tireDamageResult;
  List<TireSegmentationResult> tireSegmentationResult;
  String status;
  String message;
  ImageQualityResult imageQualityResult;

  Data({
    required this.tireDamageResult,
    required this.tireSegmentationResult,
    required this.status,
    required this.message,
    required this.imageQualityResult,
  });

  Data copyWith({
    List<TireDamageResult>? tireDamageResult,
    List<TireSegmentationResult>? tireSegmentationResult,
    String? status,
    String? message,
    ImageQualityResult? imageQualityResult,
  }) =>
      Data(
        tireDamageResult: tireDamageResult ?? this.tireDamageResult,
        tireSegmentationResult:
            tireSegmentationResult ?? this.tireSegmentationResult,
        status: status ?? this.status,
        message: message ?? this.message,
        imageQualityResult: imageQualityResult ?? this.imageQualityResult,
      );

  factory Data.fromJson(String str) => Data.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Data.fromMap(Map<String, dynamic> json) => Data(
        tireDamageResult: List<TireDamageResult>.from(
            json["tire_damage_result"].map((x) => TireDamageResult.fromMap(x))),
        tireSegmentationResult: List<TireSegmentationResult>.from(
            json["tire_segmentation_result"]
                .map((x) => TireSegmentationResult.fromMap(x))),
        status: json["status"],
        message: json["message"],
        imageQualityResult:
            ImageQualityResult.fromMap(json["image_quality_result"]),
      );

  Map<String, dynamic> toMap() => {
        "tire_damage_result":
            List<dynamic>.from(tireDamageResult.map((x) => x.toMap())),
        "tire_segmentation_result":
            List<dynamic>.from(tireSegmentationResult.map((x) => x.toMap())),
        "status": status,
        "message": message,
        "image_quality_result": imageQualityResult.toMap(),
      };
}

class ImageQualityResult {
  double score;
  int processingTimeMs;

  ImageQualityResult({
    required this.score,
    required this.processingTimeMs,
  });

  ImageQualityResult copyWith({
    double? score,
    int? processingTimeMs,
  }) =>
      ImageQualityResult(
        score: score ?? this.score,
        processingTimeMs: processingTimeMs ?? this.processingTimeMs,
      );

  factory ImageQualityResult.fromJson(String str) =>
      ImageQualityResult.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ImageQualityResult.fromMap(Map<String, dynamic> json) =>
      ImageQualityResult(
        score: json["score"]?.toDouble(),
        processingTimeMs: json["processing_time_ms"],
      );

  Map<String, dynamic> toMap() => {
        "score": score,
        "processing_time_ms": processingTimeMs,
      };
}

class TireDamageResult {
  Percentages percentages;
  String label;
  double confidenceLevel;
  String dominant;
  int tireDamageResultClass;
  String centroid;
  List<int> bbox;

  TireDamageResult({
    required this.percentages,
    required this.label,
    required this.confidenceLevel,
    required this.dominant,
    required this.tireDamageResultClass,
    required this.centroid,
    required this.bbox,
  });

  TireDamageResult copyWith({
    Percentages? percentages,
    String? label,
    double? confidenceLevel,
    String? dominant,
    int? tireDamageResultClass,
    String? centroid,
    List<int>? bbox,
  }) =>
      TireDamageResult(
        percentages: percentages ?? this.percentages,
        label: label ?? this.label,
        confidenceLevel: confidenceLevel ?? this.confidenceLevel,
        dominant: dominant ?? this.dominant,
        tireDamageResultClass:
            tireDamageResultClass ?? this.tireDamageResultClass,
        centroid: centroid ?? this.centroid,
        bbox: bbox ?? this.bbox,
      );

  factory TireDamageResult.fromJson(String str) =>
      TireDamageResult.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory TireDamageResult.fromMap(Map<String, dynamic> json) =>
      TireDamageResult(
        percentages: Percentages.fromMap(json["percentages"]),
        label: json["label"],
        confidenceLevel: json["confidence_level"]?.toDouble(),
        dominant: json["dominant"],
        tireDamageResultClass: json["class"],
        centroid: json["centroid"],
        bbox: List<int>.from(json["bbox"].map((x) => x)),
      );

  Map<String, dynamic> toMap() => {
        "percentages": percentages.toMap(),
        "label": label,
        "confidence_level": confidenceLevel,
        "dominant": dominant,
        "class": tireDamageResultClass,
        "centroid": centroid,
        "bbox": List<dynamic>.from(bbox.map((x) => x)),
      };
}

class Percentages {
  double sidewall;
  double shoulder;

  Percentages({
    required this.sidewall,
    required this.shoulder,
  });

  Percentages copyWith({
    double? sidewall,
    double? shoulder,
  }) =>
      Percentages(
        sidewall: sidewall ?? this.sidewall,
        shoulder: shoulder ?? this.shoulder,
      );

  factory Percentages.fromJson(String str) =>
      Percentages.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Percentages.fromMap(Map<String, dynamic> json) => Percentages(
        sidewall: (json["sidewall"] ?? 0).toDouble(),
        shoulder: (json["shoulder"] ?? 0).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        "sidewall": sidewall,
        "shoulder": shoulder,
      };
}

class TireSegmentationResult {
  String polygon;
  int label;
  String imageMask;
  double confidenceLevel;

  TireSegmentationResult({
    required this.polygon,
    required this.label,
    required this.imageMask,
    required this.confidenceLevel,
  });

  TireSegmentationResult copyWith({
    String? polygon,
    int? label,
    String? imageMask,
    double? confidenceLevel,
  }) =>
      TireSegmentationResult(
        polygon: polygon ?? this.polygon,
        label: label ?? this.label,
        imageMask: imageMask ?? this.imageMask,
        confidenceLevel: confidenceLevel ?? this.confidenceLevel,
      );

  factory TireSegmentationResult.fromJson(String str) =>
      TireSegmentationResult.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory TireSegmentationResult.fromMap(Map<String, dynamic> json) =>
      TireSegmentationResult(
        polygon: json["polygon"],
        label: json["label"],
        imageMask: json["image_mask"],
        confidenceLevel: json["confidence_level"]?.toDouble(),
      );

  Map<String, dynamic> toMap() => {
        "polygon": polygon,
        "label": label,
        "image_mask": imageMask,
        "confidence_level": confidenceLevel,
      };
}

class Headers {
  String contentType;
  String contentLength;
  String server;
  String date;
  String connection;

  Headers({
    required this.contentType,
    required this.contentLength,
    required this.server,
    required this.date,
    required this.connection,
  });

  Headers copyWith({
    String? contentType,
    String? contentLength,
    String? server,
    String? date,
    String? connection,
  }) =>
      Headers(
        contentType: contentType ?? this.contentType,
        contentLength: contentLength ?? this.contentLength,
        server: server ?? this.server,
        date: date ?? this.date,
        connection: connection ?? this.connection,
      );

  factory Headers.fromJson(String str) => Headers.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Headers.fromMap(Map<String, dynamic> json) => Headers(
        contentType: json["content-type"],
        contentLength: json["content-length"],
        server: json["server"],
        date: json["date"],
        connection: json["connection"],
      );

  Map<String, dynamic> toMap() => {
        "content-type": contentType,
        "content-length": contentLength,
        "server": server,
        "date": date,
        "connection": connection,
      };
}
