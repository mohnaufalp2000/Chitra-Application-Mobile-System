import 'dart:io';

import 'package:camos/core/services/local_database/tire_inspection_offline_edit/tire_inspection_offline_edit_entity.dart';
import 'package:camos/core/services/tire_inspection_offline_edit_service.dart';
import 'package:camos/objectbox.g.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory databaseDirectory;
  late Store store;
  late TireInspectionOfflineEditService service;

  setUp(() async {
    databaseDirectory =
        await Directory.systemTemp.createTemp('camos-offline-edit-objectbox-');
    store = Store(
      getObjectBoxModel(),
      directory: databaseDirectory.path,
    );
    service = TireInspectionOfflineEditService.forTesting(store);
  });

  tearDown(() async {
    store.close();
    if (await databaseDirectory.exists()) {
      await databaseDirectory.delete(recursive: true);
    }
  });

  test('snapshot checked dapat dibuka berdasarkan dokumen dan site/tanggal',
      () {
    service.cacheInspection(
      documentId: 'inspection-1',
      data: _inspectionData(pressure: '100'),
    );

    final byDocument = service.loadByDocumentId('inspection-1');
    final byDate = service.loadForSiteAndDate(
      siteId: '8',
      inspectionDate: '2026-08-26',
    );

    expect(byDocument, isNotNull);
    expect(byDocument!.data['unit'], 'DT090-0001');
    expect(byDocument.pendingSync, isFalse);
    expect(byDate, hasLength(1));
  });

  test('edit offline menimpa antrean unit yang sama tanpa duplikasi', () async {
    service.cacheInspection(
      documentId: 'inspection-1',
      data: _inspectionData(pressure: '100'),
    );

    await service.enqueueEdit(
      inspectionDocumentId: 'inspection-1',
      siteId: '8',
      unitNumber: 'DT090-0001',
      originalHari: '2026-08-26',
      inspectionData: _inspectionData(pressure: '110'),
      dailyPressureData: _dailyPressureData(pressure: '110'),
    );
    await service.enqueueEdit(
      inspectionDocumentId: 'inspection-1',
      siteId: '8',
      unitNumber: 'DT090-0001',
      originalHari: '2026-08-26',
      inspectionData: _inspectionData(pressure: '120'),
      dailyPressureData: _dailyPressureData(pressure: '120'),
    );

    final snapshot = service.loadByDocumentId('inspection-1');
    expect(store.box<TireInspectionOfflineEditEntity>().count(), 1);
    expect(snapshot, isNotNull);
    expect(snapshot!.pendingSync, isTrue);
    expect((snapshot.data['posisi'] as List).first['pressure'], '120');
    expect(service.hasPendingForDocument('inspection-1'), isTrue);
  });

  test('refresh server tidak menimpa perubahan yang masih pending', () async {
    service.cacheInspection(
      documentId: 'inspection-1',
      data: _inspectionData(pressure: '100'),
    );
    await service.enqueueEdit(
      inspectionDocumentId: 'inspection-1',
      siteId: '8',
      unitNumber: 'DT090-0001',
      originalHari: '2026-08-26',
      inspectionData: _inspectionData(pressure: '120'),
      dailyPressureData: _dailyPressureData(pressure: '120'),
    );

    final effective = service.cacheInspection(
      documentId: 'inspection-1',
      data: _inspectionData(pressure: '100'),
    );

    expect(effective.pendingSync, isTrue);
    expect((effective.data['posisi'] as List).first['pressure'], '120');
  });
}

Map<String, dynamic> _inspectionData({required String pressure}) {
  return <String, dynamic>{
    'id': 'inspection-business-id',
    'id_site': '8',
    'unit': 'DT090-0001',
    'hari': '2026-08-26',
    'tanggal': '2026-08-26T10:00:00.000',
    'pit': '4.refueling',
    'posisi': <Map<String, dynamic>>[
      <String, dynamic>{
        'position': 1,
        'pressure': pressure,
        'damageTire': <String>['Good Condition'],
      },
    ],
  };
}

Map<String, dynamic> _dailyPressureData({required String pressure}) {
  return <String, dynamic>{
    'idSite': '8',
    'unit': 'DT090-0001',
    'hari': '2026-08-26',
    'tanggal': '2026-08-26T10:00:00.000',
    'posisi': <Map<String, dynamic>>[
      <String, dynamic>{
        'pos': '1',
        'pressure': pressure,
      },
    ],
  };
}
