import 'dart:developer';
import 'dart:io';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/services/tire_inspection_offline_edit_service.dart';
import '../../../core/utils/functions/inspection_photo_helpers.dart';

class UploadQueueService extends GetxService {
  final box = GetStorage();
  final _key = 'pendingTaskUploads';

  List<Map<String, dynamic>> pending = [];
  bool _isUploading = false;

  static UploadQueueService get to => Get.find<UploadQueueService>();

  Future<UploadQueueService> init() async {
    final stored = box.read(_key);
    if (stored != null && stored is List) {
      pending = stored
          .map<Map<String, dynamic>>(
            (e) => Map<String, dynamic>.from(e as Map),
          )
          .toList();
    }

    // Coba upload semua yang tertunda saat app start
    retryPending();
    return this;
  }

  void _save() => box.write(_key, pending);

  List<Map<String, dynamic>> photosForDocument(
    String documentId, {
    List<dynamic>? storedPositions,
  }) {
    if (storedPositions != null &&
        bindPendingInspectionPhotoPositions(
          pending,
          documentId,
          storedPositions,
        )) {
      _save();
    }
    return pendingInspectionPhotosForDocument(pending, documentId);
  }

  /// Tambah ke antrian upload
  void addPending(
      {required String docId,
      required String filePath,
      required int posisiIndex,
      String tirePosition = ''}) {
    if (upsertPendingInspectionPhoto(
      pending,
      docId: docId,
      filePath: filePath,
      posisiIndex: posisiIndex,
      tirePosition: tirePosition,
    )) {
      _save();
    }
  }

  /// Upload semua foto pending → update Firestore dengan downloadURL
  Future<void> retryPending() async {
    if (_isUploading) return;
    _isUploading = true;

    // Dokumen inspeksi harus diperbarui lebih dulu. Foto untuk dokumen yang
    // masih memiliki edit pending akan dicoba pada retry berikutnya.
    await TireInspectionOfflineEditService.instance.retryPending();

    final firestore = FirebaseFirestore.instance;
    final List<Map<String, dynamic>> current = List.from(pending);

    for (final item in current) {
      // Abaikan entri lama jika foto diganti saat worker menunggu jaringan.
      if (!pending.contains(item)) continue;
      log('posisi item ${item}');
      final docId = item["docId"] as String?;
      final filePath = item["filePath"] as String?;

      if (docId == null || filePath == null) continue;
      if (TireInspectionOfflineEditService.instance
          .hasPendingForDocument(docId)) {
        continue;
      }

      final file = File(filePath);
      if (!file.existsSync()) continue;

      try {
        final posisiIndex = item["posisiIndex"] as int?;
        final fileName =
            '${docId}_${posisiIndex}_${DateTime.now().millisecondsSinceEpoch}.jpg';

        final ref = FirebaseStorage.instance.ref('tire_task_images/$fileName');

        await ref.putFile(file);
        final url = await ref.getDownloadURL();
        if (!pending.contains(item)) continue;

        // await firestore.collection('tire_inspection').doc(docId).update({
        //   'images': [url],
        //   'imagePending': false,
        // });
        log('posisi index 1 : $posisiIndex');

        if (posisiIndex == null) continue;

// Ambil data posisi lama dulu
        final docRef = firestore.collection('tire_inspection').doc(docId);
        final snapshot = await docRef.get();

        if (!snapshot.exists) continue;

        final data = snapshot.data() as Map<String, dynamic>;
        final List posisi = List.from(data['posisi'] ?? []);

        log('posisi length : ${posisi.length}');
        log('posisi lengkap : ${posisi}');

        final photoIndex = inspectionPhotoPositionIndex(
          posisi,
          fallbackIndex: posisiIndex,
          tirePosition: item['tirePosition']?.toString() ?? '',
        );
        if (photoIndex < 0 || !pending.contains(item)) continue;
        if (TireInspectionOfflineEditService.instance
            .hasPendingForDocument(docId)) {
          continue;
        }

        log('posisi index 3 : $posisiIndex');

// Update hanya posisi tertentu
        posisi[photoIndex]['images'] = [url];
        posisi[photoIndex]['imagePending'] = false;

// Simpan kembali seluruh posisi
        await docRef.update({
          'posisi': posisi,
        });

        // Pertahankan thumbnail lokal setelah upload agar edit offline tetap
        // dapat menampilkan foto tanpa mengunduh ulang dari Firebase.
        final uploadedTirePosition =
            (posisi[photoIndex]['position'] ?? posisi[photoIndex]['pos'])
                    ?.toString() ??
                '';
        TireInspectionOfflineEditService.instance.cacheLocalPhotoPath(
          inspectionDocumentId: docId,
          tirePosition: uploadedTirePosition,
          filePath: filePath,
        );

        // Hasil upload ikut tersedia saat data dibuka dari cache edit lokal.
        TireInspectionOfflineEditService.instance.cacheInspection(
          documentId: docId,
          data: {...data, 'posisi': posisi},
        );

        // File lokal dipertahankan sebagai thumbnail offline.

        pending.remove(item);
        _save();
      } catch (e) {
        // Kalau gagal upload, biarkan tetap di pending
      }
    }

    _isUploading = false;
  }
}
