import 'dart:async';

import 'tire_inspection_offline_edit_service.dart';

/// Mengunci proses sejak tap sampai route edit ditutup, bukan hanya sampai
/// data selesai dimuat. Satu halaman list tidak dapat membuka route ganda.
class TireInspectionEditOpener {
  bool _isOpening = false;

  bool get isOpening => _isOpening;

  Future<void> openOnce(Future<void> Function() action) async {
    if (_isOpening) return;
    _isOpening = true;
    try {
      await action();
    } finally {
      _isOpening = false;
    }
  }

  /// Offline tanpa jaringan langsung memakai ObjectBox. Saat ada jaringan,
  /// tetap mencoba data terbaru, tetapi tidak menunggu Firestore tanpa batas.
  /// Hasil request yang terlambat tidak boleh mengubah cache atau form yang
  /// sudah dibuka dari snapshot lokal.
  Future<TireInspectionOfflineSnapshot?> loadInspection({
    required TireInspectionOfflineSnapshot? localSnapshot,
    required Future<bool> Function() hasNetworkInterface,
    required Future<Map<String, dynamic>?> Function() fetchRemote,
    required TireInspectionOfflineSnapshot Function(Map<String, dynamic>)
        cacheRemote,
    void Function(Object, StackTrace)? onError,
    Duration networkTimeout = const Duration(seconds: 1),
    Duration remoteTimeout = const Duration(seconds: 3),
  }) async {
    if (localSnapshot?.pendingSync == true) return localSnapshot;

    try {
      final hasNetwork = await hasNetworkInterface().timeout(networkTimeout);
      if (!hasNetwork) return localSnapshot;
    } catch (error, stackTrace) {
      onError?.call(error, stackTrace);
      if (localSnapshot != null) return localSnapshot;
      // Jika status jaringan tidak bisa dibaca dan cache belum ada,
      // berikan satu kesempatan ke server dengan batas waktu di bawah.
    }

    try {
      final data = await fetchRemote().timeout(remoteTimeout);
      if (data != null) return cacheRemote(data);
    } catch (error, stackTrace) {
      onError?.call(error, stackTrace);
    }

    return localSnapshot;
  }
}
