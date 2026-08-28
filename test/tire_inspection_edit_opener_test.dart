import 'dart:async';

import 'package:camos/core/services/tire_inspection_edit_opener.dart';
import 'package:camos/core/services/tire_inspection_offline_edit_service.dart';
import 'package:flutter_test/flutter_test.dart';

TireInspectionOfflineSnapshot snapshot(
    {bool pending = false, String hm = '10'}) {
  return TireInspectionOfflineSnapshot(
    documentId: 'inspection-1',
    siteId: '8',
    unitNumber: 'DT090-0001',
    inspectionDate: '2026-08-27',
    data: {'unit': 'DT090-0001', 'hm': hm},
    pendingSync: pending,
  );
}

void main() {
  late TireInspectionEditOpener opener;
  late TireInspectionOfflineSnapshot local;
  late int remoteCalls;
  late int cacheWrites;

  setUp(() {
    opener = TireInspectionEditOpener();
    local = snapshot();
    remoteCalls = 0;
    cacheWrites = 0;
  });

  Future<Map<String, dynamic>?> fetchRemote() async {
    remoteCalls++;
    return {'unit': 'DT090-0001', 'hm': '20'};
  }

  TireInspectionOfflineSnapshot cacheRemote(Map<String, dynamic> data) {
    cacheWrites++;
    return snapshot(hm: data['hm'] as String);
  }

  test('offline langsung memakai lokal tanpa request Firestore', () async {
    final result = await opener.loadInspection(
      localSnapshot: local,
      hasNetworkInterface: () async => false,
      fetchRemote: fetchRemote,
      cacheRemote: cacheRemote,
    );
    expect(result, same(local));
    expect(remoteCalls, 0);
    expect(cacheWrites, 0);
  });

  test('pending edit selalu diprioritaskan tanpa cek jaringan', () async {
    local = snapshot(pending: true);
    final result = await opener.loadInspection(
      localSnapshot: local,
      hasNetworkInterface: () async => throw StateError('must not be called'),
      fetchRemote: fetchRemote,
      cacheRemote: cacheRemote,
    );
    expect(result, same(local));
    expect(remoteCalls, 0);
  });

  test('offline tanpa cache tidak membuat data inspeksi kosong', () async {
    final result = await opener.loadInspection(
      localSnapshot: null,
      hasNetworkInterface: () async => false,
      fetchRemote: fetchRemote,
      cacheRemote: cacheRemote,
    );
    expect(result, isNull);
    expect(remoteCalls, 0);
    expect(cacheWrites, 0);
  });

  test('online tetap mengambil data server terbaru', () async {
    final result = await opener.loadInspection(
      localSnapshot: local,
      hasNetworkInterface: () async => true,
      fetchRemote: fetchRemote,
      cacheRemote: cacheRemote,
    );
    expect(result!.data['hm'], '20');
    expect(remoteCalls, 1);
    expect(cacheWrites, 1);
  });

  test('online tanpa cache bisa memuat dokumen dari server', () async {
    final result = await opener.loadInspection(
      localSnapshot: null,
      hasNetworkInterface: () async => true,
      fetchRemote: fetchRemote,
      cacheRemote: cacheRemote,
    );
    expect(result!.documentId, 'inspection-1');
    expect(result.data['hm'], '20');
    expect(cacheWrites, 1);
  });

  test('server gagal memakai lokal dan mencatat error', () async {
    final errors = <Object>[];
    final result = await opener.loadInspection(
      localSnapshot: local,
      hasNetworkInterface: () async => true,
      fetchRemote: () async => throw StateError('network unavailable'),
      cacheRemote: cacheRemote,
      onError: (error, _) => errors.add(error),
    );
    expect(result, same(local));
    expect(errors.single, isA<StateError>());
    expect(cacheWrites, 0);
  });

  test('request lambat dibatasi; respons terlambat tidak menimpa cache',
      () async {
    final response = Completer<Map<String, dynamic>?>();
    final errors = <Object>[];
    final result = await opener.loadInspection(
      localSnapshot: local,
      hasNetworkInterface: () async => true,
      fetchRemote: () => response.future,
      cacheRemote: cacheRemote,
      remoteTimeout: const Duration(milliseconds: 10),
      onError: (error, _) => errors.add(error),
    );
    expect(result, same(local));
    expect(errors.single, isA<TimeoutException>());
    response.complete({'hm': '99'});
    await Future<void>.delayed(Duration.zero);
    expect(cacheWrites, 0);
  });

  test('cek jaringan macet tidak menahan cache lokal', () async {
    final network = Completer<bool>();
    final result = await opener.loadInspection(
      localSnapshot: local,
      hasNetworkInterface: () => network.future,
      fetchRemote: fetchRemote,
      cacheRemote: cacheRemote,
      networkTimeout: const Duration(milliseconds: 10),
    );
    expect(result, same(local));
    expect(remoteCalls, 0);
    network.complete(true);
    await Future<void>.delayed(Duration.zero);
    expect(remoteCalls, 0);
  });

  test('cek jaringan gagal tanpa cache masih mencoba server sekali', () async {
    final result = await opener.loadInspection(
      localSnapshot: null,
      hasNetworkInterface: () async => throw StateError('platform error'),
      fetchRemote: fetchRemote,
      cacheRemote: cacheRemote,
    );
    expect(result!.data['hm'], '20');
    expect(remoteCalls, 1);
  });

  test('server gagal tanpa cache mengembalikan null', () async {
    final result = await opener.loadInspection(
      localSnapshot: null,
      hasNetworkInterface: () async => true,
      fetchRemote: () async => throw StateError('offline'),
      cacheRemote: cacheRemote,
    );
    expect(result, isNull);
    expect(cacheWrites, 0);
  });

  test('tap berulang diabaikan saat loading maupun selama route masih terbuka',
      () async {
    final loading = Completer<void>();
    final routeClosed = Completer<void>();
    var loads = 0;
    var pushes = 0;
    Future<void> openPage() async {
      loads++;
      await loading.future;
      pushes++;
      await routeClosed.future;
    }

    final firstTap = opener.openOnce(openPage);
    await Future.wait(List.generate(10, (_) => opener.openOnce(openPage)));
    expect(opener.isOpening, isTrue);
    expect(loads, 1);
    expect(pushes, 0);

    loading.complete();
    await Future<void>.delayed(Duration.zero);
    await opener.openOnce(openPage);
    expect(pushes, 1);
    expect(loads, 1);
    expect(opener.isOpening, isTrue);

    routeClosed.complete();
    await firstTap;
    expect(opener.isOpening, isFalse);
    await opener.openOnce(openPage);
    expect(pushes, 2);
  });

  test('kegagalan membuka halaman melepaskan pengunci untuk retry', () async {
    await expectLater(
      opener.openOnce(() async => throw StateError('load failed')),
      throwsStateError,
    );
    expect(opener.isOpening, isFalse);
    var opened = false;
    await opener.openOnce(() async {
      opened = true;
    });
    expect(opened, isTrue);
    expect(opener.isOpening, isFalse);
  });
}
