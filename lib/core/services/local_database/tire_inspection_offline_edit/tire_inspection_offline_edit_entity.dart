import 'package:objectbox/objectbox.dart';

/// Snapshot inspeksi yang dapat dibuka kembali tanpa jaringan sekaligus
/// antrean perubahan edit yang belum tersinkron ke Firestore.
@Entity()
class TireInspectionOfflineEditEntity {
  TireInspectionOfflineEditEntity({
    this.id = 0,
    this.inspectionDocumentId = '',
    this.siteId = '',
    this.unitNumber = '',
    this.inspectionDate = '',
    this.originalHari = '',
    this.cachedInspectionJson = '',
    this.pendingInspectionJson = '',
    this.pendingDailyPressureJson = '',
    this.updatedAtMillis = 0,
    this.pendingSync = false,
  });

  int id;

  @Unique()
  String inspectionDocumentId;

  @Index()
  String siteId;

  @Index()
  String unitNumber;

  @Index()
  String inspectionDate;

  String originalHari;
  String cachedInspectionJson;
  String pendingInspectionJson;
  String pendingDailyPressureJson;

  @Index()
  int updatedAtMillis;

  bool pendingSync;
}
