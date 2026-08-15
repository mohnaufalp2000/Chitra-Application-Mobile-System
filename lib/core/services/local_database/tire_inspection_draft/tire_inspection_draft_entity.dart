import 'package:objectbox/objectbox.dart';

/// ObjectBox representation of one unfinished Tire Inspection form.
///
/// Searchable metadata is stored separately from [payloadJson] so draft lists
/// and retention cleanup do not need to decode the complete form payload.
@Entity()
class TireInspectionDraftEntity {
  TireInspectionDraftEntity({
    this.id = 0,
    this.storageToken = '',
    this.userId = '',
    this.siteId = '',
    this.unitNumber = '',
    this.inspectionDate = '',
    this.createdAtMillis = 0,
    this.updatedAtMillis = 0,
    this.periodType = 'PI',
    this.location = '',
    this.hm = '',
    this.unitModel = '',
    this.siteName = '',
    this.userDisplayName = '',
    this.positionCount = 0,
    this.imageCount = 0,
    this.payloadJson = '',
  });

  int id;

  @Unique()
  String storageToken;

  @Index()
  String userId;

  @Index()
  String siteId;

  @Index()
  String unitNumber;

  @Index()
  String inspectionDate;

  int createdAtMillis;

  @Index()
  int updatedAtMillis;

  String periodType;
  String location;
  String hm;
  String unitModel;
  String siteName;
  String userDisplayName;
  int positionCount;
  int imageCount;
  String payloadJson;
}
